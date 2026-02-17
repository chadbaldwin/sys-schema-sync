CREATE PROCEDURE import.usp_GetDatabaseSyncObjectsToProcess (
    @Limit int = -1, -- Set to -1 to disable batching
    @OpportunisticSchedulingEnabled   bit = 0,
    @OpportunisticSchedulingThreshold int = 50
)
AS
BEGIN;
    SET NOCOUNT ON;
    DECLARE @ts datetime2 = SYSUTCDATETIME();

    /* Lets make things more complicated than they need to be just for fun...

      Implementing a priority system:
        * Priority  0 = manual resets      - syncs that have been manually reset to run again
        * Priority  1 = new syncs          - syncs that have never run before (new database, new sync object, etc)
        * Priority  2 = aging syncs        - syncs that have passed their stale age threshold
        * Priority  3 = forced syncs       - syncs that haven't imported data in a while - typically due to having a checksum.
                                             If the checksum never changes, then new data is never imported.
                                             This is just a safety to ensure even with a checksum, they get forced to refresh occasionally.
        * Priority  4 = opportunistic sync - fill in free time - if the queue is light, might as well use this free time to take care of older syncs
    */

    /*
    DECLARE @Limit int = 500, @OpportunisticSchedulingEnabled bit = 1, @OpportunisticSchedulingThreshold int = 50, @ts datetime2 = SYSUTCDATETIME();
    --*/

    DROP TABLE IF EXISTS #tmp_limit
    SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID, x.[priority]
        , PriorityDescription = CHOOSE(x.[priority]+1,'Manual','New','Aging','Force','Opportunistic')
    INTO #tmp_limit
    FROM (
        SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID, x.[priority]
            , rn = ROW_NUMBER() OVER (ORDER BY x.[priority]
                                             , IIF(x.[priority] IN (0,1), NEWID(), NULL)
                                             , IIF(x.[priority] = 2, x.NextCheckTime, NULL)     -- The most stale syncs get run first
                                             , IIF(x.[priority] = 3, x.LastSyncTime, NULL) DESC -- Forced refresh, run oldest first
                                             , IIF(x.[priority] = 4, x.age_rank_rand, NULL)     -- Opportunistically scheduled syncs get randomized within their age group
                                     )
        FROM (
            SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID, x.LastSyncTime, x.NextCheckTime, x.[priority], x.age_rank
                /* Sorting by age group and _then_ NEWID() in order to add some randomization within the age group
                   This helps with breaking up strings of instances/databases that are clustered together and helps
                   with spreading the workload out over time */
                , age_rank_rand = ROW_NUMBER() OVER (PARTITION BY x.[priority] ORDER BY x.age_group, NEWID())
            FROM (
                SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID, so.LastSyncTime, n.NextCheckTime, x.[priority]
                    , age_group = NTILE(10)    OVER win
                    , age_rank  = ROW_NUMBER() OVER win
                FROM import.vw_DatabaseSyncObject so
                    CROSS APPLY (SELECT NextCheckTime = DATEADD(MINUTE, so.SyncStaleAgeMinutes, so.LastSyncCheck)) n
                    CROSS APPLY (
                        SELECT [priority] = CASE
                                                WHEN so.LastSyncCheck = '1900-01-01' THEN 0 -- Manual resets - status record exists, but the date was reset
                                                WHEN so.LastSyncCheck IS NULL        THEN 1 -- Brand new syncs - status record does not exist, so it has never run before, or was deleted
                                                WHEN n.NextCheckTime < @ts           THEN 2 -- Aging syncs
                                                WHEN so.LastSyncChecksum = -1        THEN 3 -- Force refresh syncs that haven't updated in a while
                                                WHEN @OpportunisticSchedulingEnabled = 1              -- Opportunistic scheduling control at the proc level
                                                    AND so.OpportunisticSchedulingEnabled = 1         -- Opportunistic scheduling control at the sync object level
                                                    AND so.LastSyncWasError = 0                       -- Errored syncs should just wait their normal turn to run
                                                    AND DATEDIFF(MINUTE, so.LastSyncCheck, @ts) > 120 -- If it ran _that_ recently, it can wait
                                                THEN 4 -- Eligible for opportunistic scheduling 
                                                ELSE NULL
                                            END
                    ) x
                WHERE x.[priority] IS NOT NULL
                WINDOW win AS (PARTITION BY x.[priority] ORDER BY so.LastSyncCheck)
            ) x
        ) x
        WHERE x.[priority] IN (0,1,2,3)
            OR (
                x.[priority] = 4
                /* When opportunistic scheduling was completely random against the oldest non-stale syncs, it would
                   often result in a handful of syncs that get stuck at the very bottom of the queue for a long time.
                   In other words, if you have 10,000 eligible syncs, the older they are, the higher their priority should be.
                   So, we _always_ take a small amount from the bottom of the list and the rest can be a random grab bag.
                   
                   So in this case, we're taking the bottom N * 20% + a random N * 80%. */
                AND (x.age_rank <= CEILING(@OpportunisticSchedulingThreshold * 0.2) OR x.age_rank_rand <= FLOOR(@OpportunisticSchedulingThreshold * 0.8))
            )
    ) x
    WHERE x.rn <= @Limit OR @Limit = -1
    OPTION (RECOMPILE);

    SELECT so._InstanceID, so._DatabaseID, so.InstanceName, so.DatabaseName
        , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID, so.LastSyncTime, so.LastSyncChecksum
        , so.ImportTable, so.ImportProc, so.ExportQueryPath, so.SyncOnZeroChecksum, so.ChecksumQueryText, l.PriorityDescription
    FROM import.vw_DatabaseSyncObject so
        JOIN #tmp_limit l ON EXISTS (
                                SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID
                                INTERSECT
                                SELECT l._InstanceID, l._DatabaseID, l.SyncObjectID
                            )
    ORDER BY l.[priority];
END;
GO
CREATE PROCEDURE import.usp_GetDatabaseSyncObjectsToProcess (
    @Limit int = 500,
    @EnableOpportunisticScheduling bit = 1,
    @OpportunisticSchedulingLimit int = 50
)
AS
BEGIN;
    SET NOCOUNT ON;
    DECLARE @ts datetime2 = SYSUTCDATETIME();

    /* Clear out old checksums to force a full re-sync on any syncs that haven't run in a while.
       Cannot set to NULL because that would be seen as an error for any syncs which have a
       CHecksumQueryText configured. Setting to -1 instead, whcih is a valid checksum value
       but it's harmless risk and low chances of a collision anyway */
    UPDATE import.DatabaseSyncObjectStatus
        SET LastSyncChecksum = -1
    WHERE LastSyncTime < DATEADD(DAY, -7, @ts)
        AND LastSyncChecksum <> -1; -- Implicitly excluding NULLs

    /* Lets make things more complicated than they need to be just for fun.... 

      Implementing a priority system:
        * Priority   0 = manual resets - syncs that have been manually reset to run again
        * Priority   1 = new syncs - syncs that have never run before
        * Priority   2 = aging syncs - syncs that have passed their stale age threshold
        * Priority 999 = fill in free time - if there's nothing to run right now, might as well use this free time to take care of older syncs

      Total syncs returned is limited to TOP(N) so that the sync service stops early and checks back in on the queue often.
      This avoids issues such as getting stuck running a very large instance with many databses while there's others waiting to run.

      TODO: Consider table driving all limits. Or maybe making this a function that accepts parameters populated from appsettings
    */
    SELECT TOP(@Limit) x._InstanceID, x._DatabaseID, x.SyncObjectID, x.NextCheckTime, x.[priority], x.age_group, x.age_rank, x.age_rank_rand
        , PriorityDescription = CASE x.[priority]
                                    WHEN 0 THEN 'Manual'
                                    WHEN 1 THEN 'New'
                                    WHEN 2 THEN 'Aging'
                                    WHEN 3 THEN 'Force'
                                    WHEN 4 THEN 'Opportunistic'
                                    ELSE 'Other'
                                END
    INTO #tmp_limit
    FROM (
        SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID, x.InstanceName, x.DatabaseName, x.SyncObjectName
            , x.LastSyncTime, x.NextCheckTime, x.[priority], x.age_group, x.age_rank
            /* Sorting by age group and _then_ NEWID() in order to add some randomization within the age group
               This helps with breaking up strings of instances/databases that are clustered together and helps
               with spreading the workload out over time */
            , age_rank_rand = ROW_NUMBER() OVER (PARTITION BY x.[priority] ORDER BY x.age_group, NEWID())
        FROM (
            SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID, so.InstanceName, so.DatabaseName, so.SyncObjectName
                , so.LastSyncTime, n.NextCheckTime, x.[priority]
                , age_group = NTILE(10) OVER win
                , age_rank = ROW_NUMBER() OVER win
            FROM import.vw_DatabaseSyncObject so
                CROSS APPLY (SELECT NextCheckTime = DATEADD(MINUTE, so.SyncStaleAgeMinutes, so.LastSyncCheck)) n
                CROSS APPLY (
                    SELECT [priority] = CASE
                                            WHEN so.LastSyncCheck = '1900-01-01' THEN 0 -- Manual resets - status record exists, but the date was reset
                                            WHEN so.DatabaseSyncObjectID IS NULL THEN 1 -- Brand new syncs - status record does not exist, so it has never run before, or was deleted
                                            WHEN n.NextCheckTime < @ts           THEN 2 -- Aging syncs
                                            WHEN so.LastSyncChecksum = -1        THEN 3 -- Force refresh syncs that haven't updated in a while
                                            WHEN @EnableOpportunisticScheduling = 1               -- Opportunistic scheduling control at the proc level
                                                AND so.OpportunisticSchedulingEnabled = 1         -- Opportunistic scheduling control at the sync object level
                                                AND so.LastSyncWasError = 0                       -- Errored syncs should just wait their normal turn to run
                                                AND DATEDIFF(MINUTE, so.LastSyncCheck, @ts) > 120 -- If it ran that recently, it can wait
                                            THEN 4 -- Eligible for opportunistic scheduling 
                                            ELSE NULL
                                        END
                ) x
            WHERE x.[priority] IS NOT NULL
            WINDOW win AS (PARTITION BY x.[priority] ORDER BY so.LastSyncCheck)
        ) x
    ) x
    WHERE x.[priority] IN (0,1,2,3)
        OR (x.[priority] = 4 AND (x.age_rank <= @OpportunisticSchedulingLimit * 0.2 OR x.age_rank_rand <= @OpportunisticSchedulingLimit * 0.8)) -- Grab the top N oldest syncs as well as N random, these two can overlap, but that's ok, this is just to fill empty time
    ORDER BY x.[priority]
        , IIF(x.[priority] IN (0,1), NEWID(), NULL)
        , IIF(x.[priority] = 2, x.NextCheckTime, NULL)     -- The most stale syncs get run first
        , IIF(x.[priority] = 3, x.LastSyncTime, NULL) DESC -- Forced refresh, run oldest first
        , IIF(x.[priority] = 4, x.age_rank_rand, NULL)     -- Opportunistically scheduled syncs get randomized within their age group
    OPTION (RECOMPILE);

    SELECT so._InstanceID, so._DatabaseID, so.InstanceName, so.DatabaseName
        , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID, so.LastSyncTime, so.LastSyncChecksum
        , so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.SyncOnZeroChecksum, so.ChecksumQueryText, l.PriorityDescription
    FROM import.vw_DatabaseSyncObject so
        JOIN #tmp_limit l ON EXISTS (
                                SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID
                                INTERSECT
                                SELECT l._InstanceID, l._DatabaseID, l.SyncObjectID
                            )
    ORDER BY l.[priority];
END;
GO
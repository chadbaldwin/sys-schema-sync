CREATE VIEW import.vw_DatabaseSyncObjectQueue
AS
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
WITH limit AS (
    SELECT TOP(500) x._InstanceID, x._DatabaseID, x.SyncObjectID, x.[priority], x.age_group, x.age_rank, x.age_rank_rand
    FROM (
        SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID, x.[priority], x.age_group, x.age_rank
            /* Sorting by age group and _then_ NEWID() in order to add some randomization within the age group
                This helps with breaking up strings of instances/databases that are clustered together and helps
                with spreading the workload out over time */
            , age_rank_rand = ROW_NUMBER() OVER (PARTITION BY x.[priority] ORDER BY x.age_group, NEWID())
        FROM (
            SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID, x.[priority]
                , age_group = NTILE(10) OVER win
                , age_rank = ROW_NUMBER() OVER win
            FROM import.vw_DatabaseSyncObject so
                CROSS APPLY (
                    SELECT [priority] = CASE
                                            WHEN so.LastSyncCheck = '1900-01-01 00:00:00.0000000' THEN 0 -- Manual resets - status record exists, but the date was reset
                                            WHEN so.DatabaseSyncObjectID IS NULL THEN 1 -- Brand new syncs, status record does not exist, so it has never run before, or was deleted
                                            WHEN so.SyncStaleAgeMinutes <= FLOOR(DATEDIFF_BIG(SECOND, so.LastSyncCheck, SYSUTCDATETIME()) / 60.0) THEN 2 -- Aging syncs
                                            ELSE 999 -- Everything else
                                        END
                ) x
            WINDOW win AS (PARTITION BY x.[priority] ORDER BY so.LastSyncCheck)
        ) x
    ) x
    WHERE x.[priority] IN (0,1,2)
        OR (x.[priority] = 999 AND (x.age_rank <= 10 OR x.age_rank_rand <= 40)) -- Grab the top N oldest syncs as well as N random, these two can overlap, but that's ok, this is just to fill empty time
    ORDER BY x.[priority], x.age_rank_rand
)
SELECT so._InstanceID, so._DatabaseID, so.InstanceName, so.DatabaseName
    , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID
    , so.LastSyncChecksum, so.LastSyncTime, so.LastSyncCheck, so.LastSyncError, so.LastSyncErrorMessage
    , so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.ChecksumQueryText
FROM import.vw_DatabaseSyncObject so
WHERE EXISTS (
        SELECT so._InstanceID, so._DatabaseID, so.SyncObjectID
        INTERSECT
        SELECT l._InstanceID, l._DatabaseID, l.SyncObjectID FROM limit l
    );
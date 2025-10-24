CREATE VIEW import.vw_DatabaseSyncObjectQueue
AS
/* Lets make things more complicated than they need to be just for fun.... 

  Implementing a priority system:
    * Priority 0 = new and manual syncs - these are top priority and should always get picked up first
    * Priority 1 = stale syncs - syncs that have not run in a while and have passed their configured stale age limit
    * Priority 2 = fill in free time - if there's nothing to run right now, might as well use this free time to take care of the older syncs

  Total syncs returned is limited to 200 so that the sync service stops early and checks back in on the queue often.
  This avoids issues such as getting stuck running a very large instance with many databses while there's others waiting to run.
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
                                            WHEN so.LastSyncCheck = '1900-01-01 00:00:00.0000000' OR so.LastSyncCheck IS NULL THEN 0 -- Manual resets / New syncs
                                            WHEN so.SyncStaleAgeMinutes <= FLOOR(DATEDIFF_BIG(SECOND, so.LastSyncCheck, SYSUTCDATETIME()) / 60.0) THEN 1 -- Aging syncs
                                            ELSE 2 -- Everything else
                                        END
                ) x
            WINDOW win AS (PARTITION BY x.[priority] ORDER BY so.LastSyncCheck)
        ) x
    ) x
    WHERE x.[priority] IN (0,1)
        OR (x.[priority] = 2 AND (x.age_rank <= 10 OR x.age_rank_rand <= 40)) -- Grab the top 10 oldest syncs as well as 50 random, there will be occasional overlap, but that's ok
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
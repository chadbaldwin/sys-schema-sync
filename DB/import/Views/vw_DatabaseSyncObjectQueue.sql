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
    SELECT TOP(500) so.DatabaseSyncObjectID
    FROM (
        SELECT x.DatabaseSyncObjectID, x.[priority]
            , rn = ROW_NUMBER() OVER (PARTITION BY x.[priority] ORDER BY x.age_group, NEWID())
        FROM (
            SELECT so.DatabaseSyncObjectID, x.[priority]
                -- Using NTILE so that we can add a bit of randomness to the priority 2 syncs
                -- Helps to break up clusters of instances stuck together and spread out over time
                , age_group = NTILE(10) OVER (PARTITION BY x.[priority] ORDER BY so.LastSyncCheck)
            FROM import.vw_DatabaseSyncObject so
                CROSS APPLY (
                    SELECT [priority] = CASE
                                            WHEN so.LastSyncCheck IS NULL THEN 0
                                            WHEN so.SyncStaleAgeMinutes <= FLOOR(DATEDIFF_BIG(SECOND, so.LastSyncCheck, SYSUTCDATETIME()) / 60.0) THEN 1
                                            ELSE 2
                                        END
                ) x
        ) x
    ) so
    WHERE so.[priority] < 2 OR (so.[priority] = 2 AND so.rn <= 50)
    ORDER BY so.[priority], so.rn
)
SELECT so._InstanceID, so._DatabaseID, so.InstanceName, so.DatabaseName
    , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID
    , so.LastSyncChecksum, so.LastSyncTime, so.LastSyncCheck, so.LastSyncError, so.LastSyncErrorMessage
    , so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.ChecksumQueryText
FROM import.vw_DatabaseSyncObject so
WHERE EXISTS (SELECT * FROM limit l WHERE l.DatabaseSyncObjectID = so.DatabaseSyncObjectID);
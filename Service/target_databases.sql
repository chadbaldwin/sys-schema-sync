SELECT Instance = InstanceName
    , [Database] = DatabaseName
    , SyncTaskCount
FROM import.vw_DatabaseQueue;
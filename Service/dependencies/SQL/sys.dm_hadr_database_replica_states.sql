SELECT _CollectionDate = SYSUTCDATETIME()
    --
    , x.*
FROM sys.dm_hadr_database_replica_states x
WHERE x.database_id = DB_ID();
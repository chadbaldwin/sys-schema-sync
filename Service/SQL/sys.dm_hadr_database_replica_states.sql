DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
        --
        , quorum_commit_lsn  = CONVERT(numeric(25,0), NULL) -- Added: SQL Server 2019
        , quorum_commit_time = CONVERT(datetime     , NULL) -- Added: SQL Server 2019
    FROM sys.dm_hadr_database_replica_states x
    WHERE x.database_id = DB_ID();
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.dm_hadr_database_replica_states x
    WHERE x.database_id = DB_ID();
END;

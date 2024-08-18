DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
        --
        , cached_tasks         = CONVERT(bigint, NULL) -- Added: SQL Server 2022
        , cached_tasks_reused  = CONVERT(bigint, NULL) -- Added: SQL Server 2022
        , cached_tasks_removed = CONVERT(bigint, NULL) -- Added: SQL Server 2022
    FROM sys.dm_os_nodes x
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.dm_os_nodes x
END;

DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
        --
        , incurs_seek_penalty = CONVERT(tinyint, NULL) -- Added: SQL Server 2019
    FROM sys.database_files df
        CROSS APPLY sys.dm_os_volume_stats(DB_ID(), df.[file_id]) x;
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.database_files df
        CROSS APPLY sys.dm_os_volume_stats(DB_ID(), df.[file_id]) x;
END;

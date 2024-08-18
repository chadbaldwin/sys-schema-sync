DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
        --
        , num_of_pushed_reads          = CONVERT(bigint, NULL) -- Added: SQL Server 2022
        , num_of_pushed_bytes_returned = CONVERT(bigint, NULL) -- Added: SQL Server 2022
    FROM sys.database_files df
        CROSS APPLY sys.dm_io_virtual_file_stats(DB_ID(), df.[file_id]) x;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.database_files df
        CROSS APPLY sys.dm_io_virtual_file_stats(DB_ID(), df.[file_id]) x;
END;

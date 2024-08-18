DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT d.* FROM (SELECT NULL) x(x) FOR JSON AUTO)))
        --
        , d.*
        --
        , catalog_collation_type              = CONVERT(int          , NULL) -- Added: SQL Server 2019
        , catalog_collation_type_desc         = CONVERT(nvarchar(60) , NULL) -- Added: SQL Server 2019
        , physical_database_name              = CONVERT(nvarchar(128), NULL) -- Added: SQL Server 2019
        , is_result_set_caching_on            = CONVERT(bit          , NULL) -- Added: SQL Server 2019
        , is_accelerated_database_recovery_on = CONVERT(bit          , NULL) -- Added: SQL Server 2019
        , is_tempdb_spill_to_remote_store     = CONVERT(bit          , NULL) -- Added: SQL Server 2019
        , is_stale_page_detection_on          = CONVERT(bit          , NULL) -- Added: SQL Server 2019
        , is_memory_optimized_enabled         = CONVERT(bit          , NULL) -- Added: SQL Server 2019
        , is_data_retention_enabled           = CONVERT(bit          , NULL) -- Added: SQL Server 2022
        , is_ledger_on                        = CONVERT(bit          , NULL) -- Added: SQL Server 2022
        , is_change_feed_enabled              = CONVERT(bit          , NULL) -- Added: SQL Server 2022
    FROM sys.databases d;
END;
ELSE IF (@MajorVer = 15) -- SQL Server 2019
BEGIN;
    SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT d.* FROM (SELECT NULL) x(x) FOR JSON AUTO)))
        --
        , d.*
        --
        , is_data_retention_enabled           = CONVERT(bit          , NULL) -- Added: SQL Server 2022
        , is_ledger_on                        = CONVERT(bit          , NULL) -- Added: SQL Server 2022
        , is_change_feed_enabled              = CONVERT(bit          , NULL) -- Added: SQL Server 2022
    FROM sys.databases d;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT d.* FROM (SELECT NULL) x(x) FOR JSON AUTO)))
        --
        , d.*
    FROM sys.databases d;
END;

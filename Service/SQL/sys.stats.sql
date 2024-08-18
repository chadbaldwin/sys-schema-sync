DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = x.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , has_persisted_sample         = CONVERT(bit        , NULL) -- Added: SQL Server 2019
        , stats_generation_method      = CONVERT(int        , NULL) -- Added: SQL Server 2019
        , stats_generation_method_desc = CONVERT(varchar(80), NULL) -- Added: SQL Server 2019
        , auto_drop                    = CONVERT(bit        , NULL) -- Added: SQL Server 2022
    FROM sys.stats x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE x.auto_created = 0
        AND o.is_ms_shipped = 0;
END;
ELSE IF (@MajorVer = 15) -- SQL Server 2019
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = x.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , auto_drop                    = CONVERT(bit        , NULL) -- Added: SQL Server 2022
    FROM sys.stats x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE x.auto_created = 0
        AND o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = x.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM sys.stats x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE x.auto_created = 0
        AND o.is_ms_shipped = 0;
END;

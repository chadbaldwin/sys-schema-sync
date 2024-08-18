DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = x.[name]
        , _ObjectType = x.[type]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , has_snapshot           = CONVERT(bit         , NULL) -- Added: SQL Server 2019
        , ledger_view_type       = CONVERT(tinyint     , NULL) -- Added: SQL Server 2022
        , ledger_view_type_desc  = CONVERT(nvarchar(60), NULL) -- Added: SQL Server 2022
        , is_dropped_ledger_view = CONVERT(bit         , NULL) -- Added: SQL Server 2022
    FROM sys.views x
        JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    WHERE x.is_ms_shipped = 0;
END;
ELSE IF (@MajorVer = 15) -- SQL Server 2019
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = x.[name]
        , _ObjectType = x.[type]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , ledger_view_type       = CONVERT(tinyint     , NULL) -- Added: SQL Server 2022
        , ledger_view_type_desc  = CONVERT(nvarchar(60), NULL) -- Added: SQL Server 2022
        , is_dropped_ledger_view = CONVERT(bit         , NULL) -- Added: SQL Server 2022
    FROM sys.views x
        JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    WHERE x.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = x.[name]
        , _ObjectType = x.[type]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM sys.views x
        JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    WHERE x.is_ms_shipped = 0;
END;

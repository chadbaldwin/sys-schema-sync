DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _ColumnName = x.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , is_data_deletion_filter_column = CONVERT(bit         , NULL) -- Added: SQL Server 2022
        , ledger_view_column_type        = CONVERT(int         , NULL) -- Added: SQL Server 2022
        , ledger_view_column_type_desc   = CONVERT(nvarchar(60), NULL) -- Added: SQL Server 2022
        , is_dropped_ledger_column       = CONVERT(bit         , NULL) -- Added: SQL Server 2022
    FROM sys.computed_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _ColumnName = x.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM sys.computed_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0;
END;

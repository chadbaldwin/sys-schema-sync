DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = i.[name]
        , _ColumnName = c.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , column_store_order_ordinal = CONVERT(tinyint, NULL) -- Added: SQL Server 2019
    FROM sys.index_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
        JOIN sys.columns c ON c.[object_id] = x.[object_id] AND c.column_id = x.column_id
    WHERE o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = i.[name]
        , _ColumnName = c.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM sys.index_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
        JOIN sys.columns c ON c.[object_id] = x.[object_id] AND c.column_id = x.column_id
    WHERE o.is_ms_shipped = 0;
END;

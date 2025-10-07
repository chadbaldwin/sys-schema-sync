SELECT _SchemaName = s.[name]
    , _ObjectName = o.[name]
    , _ObjectType = o.[type]
    , _ColumnName = x.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.columns x
    JOIN sys.objects o ON o.[object_id] = x.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
WHERE o.is_ms_shipped = 0;
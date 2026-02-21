WITH cte_obj AS (
    SELECT o.[object_id], ObjectType = o.[type], SchemaName = s.[name], ObjectName = o.[name]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _IndexName = i.[name]
    , _ColumnName = c.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.index_columns x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
    JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
    JOIN sys.columns c ON c.[object_id] = x.[object_id] AND c.column_id = x.column_id
OPTION (RECOMPILE);
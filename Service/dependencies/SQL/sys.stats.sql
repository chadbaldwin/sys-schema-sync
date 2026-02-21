WITH cte_obj AS (
    SELECT o.[object_id], SchemaName = s.[name], ObjectName = o.[name], ObjectType = o.[type]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _IndexName = x.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.stats x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
WHERE x.auto_created = 0
OPTION (RECOMPILE);
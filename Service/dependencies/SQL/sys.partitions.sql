WITH cte_obj AS (
    SELECT o.[object_id], SchemaName = s.[name], ObjectName = o.[name], ObjectType = o.[type]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _IndexName = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.partitions x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
    JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
OPTION (RECOMPILE, USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'), LOOP JOIN);
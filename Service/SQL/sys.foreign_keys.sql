WITH cte_obj AS (
    SELECT o.[object_id], ObjectType = o.[type], SchemaName = s.[name], ObjectName = o.[name]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = s.[name]
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    , _ParentSchemaName = po.SchemaName
    , _ParentObjectName = po.ObjectName
    , _ParentObjectType = po.ObjectType
    , _ReferencedSchemaName = ro.SchemaName
    , _ReferencedObjectName = ro.ObjectName
    , _ReferencedObjectType = ro.ObjectType
    , _ReferencedIndexName = i.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.foreign_keys x
    JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    JOIN cte_obj po ON po.[object_id] = x.parent_object_id
    JOIN cte_obj ro ON ro.[object_id] = x.referenced_object_id
    JOIN sys.indexes i ON i.[object_id] = x.referenced_object_id AND i.index_id = x.key_index_id
WHERE x.is_ms_shipped = 0
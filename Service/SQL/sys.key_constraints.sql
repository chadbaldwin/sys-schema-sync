SELECT _SchemaName = s.[name]
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    , _ParentObjectName = po.[name]
    , _ParentObjectType = po.[type]
    , _UniqueIndexName = ui.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.key_constraints x
    JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    JOIN sys.objects po ON po.[object_id] = x.parent_object_id
    JOIN sys.indexes ui ON ui.[object_id] = x.parent_object_id AND ui.index_id = x.unique_index_id
WHERE x.is_ms_shipped = 0;
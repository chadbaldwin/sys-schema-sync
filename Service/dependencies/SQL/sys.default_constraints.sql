SELECT _SchemaName = s.[name]
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    , _ParentObjectName = po.[name]
    , _ParentObjectType = po.[type]
    , _ParentColumnName = pc.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.default_constraints x
    JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    JOIN sys.objects po ON po.[object_id] = x.parent_object_id
    JOIN sys.columns pc ON pc.[object_id] = x.parent_object_id AND pc.column_id = x.parent_column_id -- Default constraints are always at the column level
WHERE x.is_ms_shipped = 0;
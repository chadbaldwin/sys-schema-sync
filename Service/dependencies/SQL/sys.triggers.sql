-- Object level triggers
SELECT _SchemaName = s.[name]
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    , _ParentObjectName = po.[name]
    , _ParentObjectType = po.[type]
    -- TODO: change hash to exclude volatile columns that don't need to be included (e.g., modify_date, create_date)
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.triggers x
    JOIN sys.objects o ON o.[object_id] = x.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    JOIN sys.objects po ON po.[object_id] = x.parent_id
WHERE x.is_ms_shipped = 0
    AND x.parent_class = 1
UNION
-- Database level triggers
SELECT _SchemaName = '<<DB>>'
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    , _ParentObjectName = NULL
    , _ParentObjectType = NULL
    -- TODO: change hash to exclude volatile columns that don't need to be included (e.g., modify_date, create_date)
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.triggers x
WHERE x.is_ms_shipped = 0
    AND x.parent_class = 0;
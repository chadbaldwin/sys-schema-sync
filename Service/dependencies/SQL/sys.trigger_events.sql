-- Object level triggers
SELECT _SchemaName = s.[name]
    , _ObjectName = tr.[name]
    , _ObjectType = tr.[type]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.trigger_events x
    JOIN sys.triggers tr ON tr.[object_id] = x.[object_id]
    JOIN sys.objects o ON o.[object_id] = tr.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
WHERE tr.is_ms_shipped = 0
    AND tr.parent_class = 1
UNION
-- Database level triggers
SELECT _SchemaName = '<<DB>>'
    , _ObjectName = tr.[name]
    , _ObjectType = tr.[type]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.trigger_events x
    JOIN sys.triggers tr ON tr.[object_id] = x.[object_id]
WHERE tr.is_ms_shipped = 0
    AND tr.parent_class = 0
OPTION (RECOMPILE);
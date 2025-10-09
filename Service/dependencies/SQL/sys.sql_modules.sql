WITH cte_obj AS (
    SELECT o.[object_id], SchemaName = s.[name], ObjectName = o.[name], ObjectType = o.[type]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
    UNION
    SELECT t.[object_id], '<<DB>>', t.[name], t.[type]
    FROM sys.triggers t
    WHERE parent_class = 0
        AND t.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _ObjectDefinitionHash = CONVERT(binary(32), COALESCE(HASHBYTES('SHA2_256', x.[definition]), 0x0)) -- Encrypted SP's have a NULL definition
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.sql_modules x
    JOIN cte_obj o ON o.[object_id] = x.[object_id];
SELECT _SchemaName = s.[name]
    , _ObjectName = x.[name]
    , _ObjectType = x.[type]
    -- TODO: change hash to exclude volatile columns that don't need to be included (e.g., modify_date, create_date)
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.objects x
    JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
WHERE x.is_ms_shipped = 0;
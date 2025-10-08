SELECT _SchemaName = s.[name]
    , _ObjectName = o.[name]
    , _ObjectType = o.[type]
    , _IndexName = st.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.stats st
    JOIN sys.objects o ON o.[object_id] = st.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    CROSS APPLY sys.dm_db_stats_properties(st.[object_id], st.stats_id) x
WHERE st.auto_created = 0
    AND o.is_ms_shipped = 0;
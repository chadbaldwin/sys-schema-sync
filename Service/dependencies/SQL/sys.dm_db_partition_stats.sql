SELECT _SchemaName = s.[name]
    , _ObjectName = o.[name]
    , _ObjectType = o.[type]
    , _IndexName = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM sys.dm_db_partition_stats x -- Be careful with this view, it seems to have some sort of ghost records where they have no matching record in sys.objects
    JOIN sys.objects o ON o.[object_id] = x.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
WHERE o.is_ms_shipped = 0;
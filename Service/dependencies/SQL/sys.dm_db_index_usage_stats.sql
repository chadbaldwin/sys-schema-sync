/* This export script is a special case due to how the `sys.dm_db_index_usage_stats` DMV works.

   This DMV is cleared and reset for various reasons at the instnace, DB, object and index level.

   Since this table is used to determine how often an index is used, then it makes sense to generate
   rows for indexes that are not in the table at all. Allows us to see if an index is NEVER used.
*/

SELECT _SchemaName      = s.[name]
    , _ObjectName       = o.[name]
    , _ObjectType       = o.[type]
    , _IndexName        = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
    , _RowHash          = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , database_id       = COALESCE(x.database_id, DB_ID())
    , [object_id]       = i.[object_id]
    , index_id          = i.index_id
    , user_seeks        = COALESCE(x.user_seeks, 0)
    , user_scans        = COALESCE(x.user_scans, 0)
    , user_lookups      = COALESCE(x.user_lookups, 0)
    , user_updates      = COALESCE(x.user_updates, 0)
    , x.last_user_seek, x.last_user_scan, x.last_user_lookup, x.last_user_update
    , system_seeks      = COALESCE(x.system_seeks, 0)
    , system_scans      = COALESCE(x.system_scans, 0)
    , system_lookups    = COALESCE(x.system_lookups, 0)
    , system_updates    = COALESCE(x.system_updates, 0)
    , x.last_system_seek, x.last_system_scan, x.last_system_lookup, x.last_system_update
FROM sys.indexes i
    JOIN sys.objects o ON o.[object_id] = i.[object_id]
    JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    LEFT JOIN sys.dm_db_index_usage_stats x ON x.database_id = DB_ID() AND x.[object_id] = i.[object_id] AND x.index_id = i.index_id
WHERE o.is_ms_shipped = 0
    AND CHECKSUM(*) IS NOT NULL
OPTION(RECOMPILE);
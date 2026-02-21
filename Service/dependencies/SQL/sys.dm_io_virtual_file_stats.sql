SELECT _CollectionDate = SYSUTCDATETIME()
    --
    , x.*
FROM sys.database_files df
    CROSS APPLY sys.dm_io_virtual_file_stats(DB_ID(), df.[file_id]) x
OPTION (RECOMPILE);
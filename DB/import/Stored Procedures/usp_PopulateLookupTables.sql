CREATE PROCEDURE import.usp_PopulateLookupTables
AS
BEGIN;
    SET NOCOUNT ON;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Update SyncObjectLevel
    ------------------------------------------------------------------------------
        RAISERROR('Updating: import.SyncObjectLevel ',0,1) WITH NOWAIT;
        MERGE INTO import.SyncObjectLevel WITH(HOLDLOCK) o
        USING (
            VALUES (1, 'Instance') -- Queries that return information about the instance and only need to be run and stored once per instance - OS info, Windows info, server/instance stats, etc
                ,  (2, 'Database') -- Queries that return information specific to a database - database configuration, objects, stats, etc
        ) n (SyncObjectLevelID, SyncObjectLevelName) ON o.SyncObjectLevelID = n.SyncObjectLevelID
        WHEN NOT MATCHED BY TARGET
        THEN
            INSERT (SyncObjectLevelID, SyncObjectLevelName)
            VALUES (n.SyncObjectLevelID, n.SyncObjectLevelName)
        OUTPUT $action, 'Deleted', Deleted.*, 'Inserted', Inserted.*;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- SyncObject configuration
    ------------------------------------------------------------------------------
        /*
            SyncObjectID                   =   Generally matches the original object_id of the object being synced from the `sys` schema,
                                               this is not an operational requirement. It can be anything and it won't affect imports.

            SyncObjectName                 =   The name of the object being synced. In some cases, like with global variables and metadata
                                               functions. The SyncObjectName is used by the sync process to know which table to query data
                                               from when an ExportQueryPath is not provided.

            SyncObjectLevelID              =   The scope at which the target SyncObject runs. Some system DMV's run at the Instance level.
                                               Which means no matter which database you are querying the DMV from, it will always return
                                               the same information about the instance and does not contain database level information.
                                               For example, `sys.dm_os_host_info` returns information about the instance.

                                               Some DMV's run at the Database level, which means the results returned by the object will change
                                               based on which database you are querying from and they return information specific to databases.

                                               This can get tricky with some DMV's because they return Database level information for all
                                               databases regardless of which database they are queried from. For example, `sys.databases` or
                                               `sys.dm_db_index_usage_stats`. Both of these will return records for ALL databases.

                                               In those cases, they are still considered to be running at the Database level, but they would
                                               require creating an ExportQuery and supplying an ExportQueryPath in order to filter the results
                                               by database.

                                               This field controls two things...
                                               If Instance level is specified, it will run against the master database on each instance.
                                               If Database level is specified, it will run against each configured user database.

                                               In either case, if an ExportQueryPath is not provided, one will be generated and will use either
                                               the _InstanceID or _DatabaseID when inserting into its configured ImportTable.

            IsEnabled                      =   Controls whether the sync object is enabled. Disabling immediately removes all records from
                                               the sync queue, but does not remove any records from import.DatabaseSyncObjectStatus.

            SyncStaleAgeMinutes            =   Minimum amount of time the sync process should wait before kicking off another sync. This is
                                               checked at the Database+SyncObject level.

                                               180=3hr;  360=6hr;  480=8hr;  720=12hr;  1440=24hr;  2880=48hr;

            OpportunisticSchedulingEnabled =   Allows the sync process to opportunistically run this sync during free time if there are no other
                                               higher priority syncs to run. This is useful for larger syncs that don't need to run as often
                                               and can take advantage of free time windows to get caught up.

            ImportTable                    =   Used for simple imports (delete and insert). Tells the sync process which table to use for import.
            ImportProc                     =   Used for complex imports (proc + type). Tells the sync process which proc to use for import (as well as type, via looking at the @Dataset parameter).

            ExportQueryPath                =   Used to override the default export query (typically `SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {SyncObjectName}`)
                                               If configured, a file must be created in the SQL scripts directory of the service. Can be used
                                               with both simple and complex sync types.

            SyncOnZeroChecksum             =   If set to true, the sync process will run even if the last checksum calculated is zero. This is useful
                                               for datasets that may legitimately have a checksum of zero and you want deletes to run anyway.

                                               In some cases, you may want to disable this - for example, syncs which are insert/update only.

                                               For example, sys.sql_modules. Only pulls data since the last sync time and relies on the soft delete system for deletes.

            ChecksumQueryText              =   Optional checksum query. Used to decide whether to perform the sync for larger datasets. This adds
                                               extra overhead on the target databases having to run this first, however, it tends to save quite
                                               a bit of processing time due to saved network IO.
        */

        --DROP TABLE IF EXISTS #tmp_SyncObject; --SELECT * FROM #tmp_SyncObject
        SELECT n.SyncObjectID, n.SyncObjectName, n.SyncObjectLevelID, n.SyncStaleAgeMinutes, n.ImportTable, n.ImportProc, n.ExportQueryPath, n.ChecksumQueryText
        INTO #tmp_SyncObject
        FROM ( --               SyncObjectName                                         ImportTable                                 ImportProc                                              ExportQueryPath                              ChecksumQueryText
            VALUES (-951091328, 'sys.dm_hadr_cluster'                       , 1, 1440, 'dbo._dm_hadr_cluster'                    , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.dm_hadr_cluster;')
                ,  (-897487264, 'sys.dm_xe_sessions'                        , 1,  480, 'dbo._dm_xe_sessions'                     , NULL                                                  , NULL                                       , NULL)
                ,  (-879924562, 'sys.dm_db_log_space_usage'                 , 2,  480, 'dbo._dm_db_log_space_usage'              , NULL                                                  , NULL                                       , NULL)
                ,  (-806439612, 'sys.dm_io_virtual_file_stats'              , 2,  480, 'dbo._dm_io_virtual_file_stats'           , NULL                                                  , 'sys.dm_io_virtual_file_stats.sql'         , NULL)
                ,  (-783733354, 'sys.dm_os_wait_stats'                      , 1,  480, NULL                                      , 'import.usp_import__dm_os_wait_stats'                 , NULL                                       , NULL)
                ,  (-680277963, 'sys.database_query_store_options'          , 2,  480, 'dbo._database_query_store_options'       , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.database_query_store_options;')
                ,  (-644579219, 'sys.dm_db_stats_properties'                , 2, 1440, NULL                                      , 'import.usp_import__dm_db_stats_properties'           , 'sys.dm_db_stats_properties.sql'           , NULL)
                ,  (-641734695, 'sys.dm_resource_governor_resource_pools'   , 1,  480, 'dbo._dm_resource_governor_resource_pools', NULL                                                  , NULL                                       , NULL)
                ,  (-638989397, 'sys.dm_os_volume_stats'                    , 2,  480, 'dbo._dm_os_volume_stats'                 , NULL                                                  , 'sys.dm_os_volume_stats.sql'               , NULL)
                ,  (-558058590, 'sys.dm_os_host_info'                       , 1, 1440, 'dbo._dm_os_host_info'                    , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.dm_os_host_info;')
                ,  (-500638940, 'sys.dm_db_index_operational_stats'         , 2,  360, NULL                                      , 'import.usp_import__dm_db_index_operational_stats'    , 'sys.dm_db_index_operational_stats.sql'    , NULL)
                ,  (-495130372, 'sys.dm_db_partition_stats'                 , 2, 1440, NULL                                      , 'import.usp_import__dm_db_partition_stats'            , 'sys.dm_db_partition_stats.sql'            , NULL)
                ,  (-489165464, 'sys.dm_os_sys_memory'                      , 1,  480, 'dbo._dm_os_sys_memory'                   , NULL                                                  , NULL                                       , NULL)
                ,  (-469313267, 'sys.dm_os_nodes'                           , 1,  480, 'dbo._dm_os_nodes'                        , NULL                                                  , NULL                                       , NULL)
                ,  (-334110873, 'sys.dm_db_index_usage_stats'               , 2,  360, NULL                                      , 'import.usp_import__dm_db_index_usage_stats'          , 'sys.dm_db_index_usage_stats.sql'          , NULL)
                ,  (-305100784, 'sys.dm_server_services'                    , 1, 1440, 'dbo._dm_server_services'                 , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.dm_server_services;')
                ,  (-233577667, 'sys.dm_hadr_database_replica_states'       , 2,  480, 'dbo._dm_hadr_database_replica_states'    , NULL                                                  , 'sys.dm_hadr_database_replica_states.sql'  , NULL)
                ,  (-215103612, 'sys.dm_os_sys_info'                        , 1,  480, 'dbo._dm_os_sys_info'                     , NULL                                                  , NULL                                       , NULL)
                ,  (-129939010, 'sys.dm_os_enumerate_fixed_drives'          , 1,  480, 'dbo._dm_os_enumerate_fixed_drives'       , NULL                                                  , NULL                                       , NULL)
                ,  ( -46687631, 'sys.dm_os_memory_nodes'                    , 1,  480, 'dbo._dm_os_memory_nodes'                 , NULL                                                  , NULL                                       , NULL)
                ,  ( -39192848, 'sys.dm_os_cluster_nodes'                   , 1, 1440, 'dbo._dm_os_cluster_nodes'                , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.dm_os_cluster_nodes;')
                ,  ( -32276936, 'sys.dm_os_process_memory'                  , 1,  480, 'dbo._dm_os_process_memory'               , NULL                                                  , NULL                                       , NULL)
                ,  (      -598, 'sys.database_automatic_tuning_options'     , 2,  480, NULL                                      , 'import.usp_import__database_automatic_tuning_options', 'sys.database_automatic_tuning_options.sql', 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.database_automatic_tuning_options;')
                ,  (      -587, 'sys.index_resumable_operations'            , 2, 1440, 'dbo._index_resumable_operations'         , NULL                                                  , NULL                                       , NULL)
                ,  (      -582, 'sys.database_scoped_configurations'        , 2, 1440, 'dbo._database_scoped_configurations'     , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.database_scoped_configurations;')
                ,  (      -448, 'sys.database_files'                        , 2,  480, 'dbo._database_files'                     , NULL                                                  , NULL                                       , NULL)
                ,  (      -439, 'sys.destination_data_spaces'               , 2, 1440, 'dbo._destination_data_spaces'            , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.destination_data_spaces;')
                ,  (      -438, 'sys.partition_schemes'                     , 2, 1440, 'dbo._partition_schemes'                  , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.partition_schemes;')
                ,  (      -437, 'sys.filegroups'                            , 2,  480, 'dbo._filegroups'                         , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.filegroups;')
                ,  (      -436, 'sys.data_spaces'                           , 2,  480, 'dbo._data_spaces'                        , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.data_spaces;')
                ,  (      -435, 'sys.partition_functions'                   , 2, 1440, 'dbo._partition_functions'                , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.partition_functions;')
                ,  (      -434, 'sys.partition_parameters'                  , 2, 1440, 'dbo._partition_parameters'               , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.partition_parameters;')
                ,  (      -433, 'sys.partition_range_values'                , 2, 1440, 'dbo._partition_range_values'             , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.partition_range_values;')
                ,  (      -416, 'sys.sql_modules'                           , 2, 1440, NULL                                      , 'import.usp_import__sql_modules'                      , 'sys.sql_modules.sql'                      , '/* To get around time zone offset discrepancies, just back up by one day
                                                                                                                                                                                                                                             This will cause a slight overlap, but because we''re only checking for
                                                                                                                                                                                                                                             changes, its not as big of a deal */
                                                                                                                                                                                                                                         DECLARE @dt datetime = DATEADD(day, -1, @LastSyncTime)
                                                                                                                                                                                                                                         SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0)
                                                                                                                                                                                                                                         FROM (
                                                                                                                                                                                                                                             SELECT sm.*
                                                                                                                                                                                                                                             FROM sys.sql_modules sm
                                                                                                                                                                                                                                                 JOIN sys.objects o ON o.[object_id] = sm.[object_id]
                                                                                                                                                                                                                                             WHERE (o.modify_date > @dt OR @dt IS NULL)
                                                                                                                                                                                                                                                 AND is_ms_shipped = 0
                                                                                                                                                                                                                                         ) x
                                                                                                                                                                                                                                         OPTION (RECOMPILE);')
                ,  (      -412, 'sys.triggers'                              , 2,  480, NULL                                      , 'import.usp_import__triggers'                         , 'sys.triggers.sql'                         , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.triggers            WHERE is_ms_shipped = 0;')
                ,  (      -410, 'sys.foreign_key_columns'                   , 2,  480, NULL                                      , 'import.usp_import__foreign_key_columns'              , 'sys.foreign_key_columns.sql'              , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.foreign_key_columns;')
                ,  (      -409, 'sys.foreign_keys'                          , 2,  480, NULL                                      , 'import.usp_import__foreign_keys'                     , 'sys.foreign_keys.sql'                     , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.foreign_keys        WHERE is_ms_shipped = 0;')
                ,  (      -408, 'sys.default_constraints'                   , 2,  480, NULL                                      , 'import.usp_import__default_constraints'              , 'sys.default_constraints.sql'              , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.default_constraints WHERE is_ms_shipped = 0;')
                ,  (      -407, 'sys.check_constraints'                     , 2,  480, NULL                                      , 'import.usp_import__check_constraints'                , 'sys.check_constraints.sql'                , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.check_constraints   WHERE is_ms_shipped = 0;')
                ,  (      -406, 'sys.key_constraints'                       , 2,  480, NULL                                      , 'import.usp_import__key_constraints'                  , 'sys.key_constraints.sql'                  , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.key_constraints     WHERE is_ms_shipped = 0;')
                ,  (      -402, 'sys.stats'                                 , 2,  480, NULL                                      , 'import.usp_import__stats'                            , 'sys.stats.sql'                            , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.stats x             WHERE EXISTS (SELECT * FROM sys.objects o WHERE o.[object_id] = x.[object_id] AND o.is_ms_shipped = 0) AND x.auto_created = 0;')
                ,  (      -401, 'sys.index_columns'                         , 2,  480, NULL                                      , 'import.usp_import__index_columns'                    , 'sys.index_columns.sql'                    , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.index_columns x     WHERE OBJECTPROPERTYEX(x.[object_id], ''IsMSShipped'') = 0;')
                ,  (      -399, 'sys.partitions'                            , 2,  480, NULL                                      , 'import.usp_import__partitions'                       , 'sys.partitions.sql'                       , NULL)
                ,  (      -397, 'sys.indexes'                               , 2,  480, NULL                                      , 'import.usp_import__indexes'                          , 'sys.indexes.sql'                          , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.indexes x           WHERE OBJECTPROPERTYEX(x.[object_id], ''IsMSShipped'') = 0;')
                ,  (      -396, 'sys.identity_columns'                      , 2,  480, NULL                                      , 'import.usp_import__identity_columns'                 , 'sys.identity_columns.sql'                 , NULL) -- There will almost definitely always be changes because this table stores the last identity value
                ,  (      -395, 'sys.computed_columns'                      , 2,  480, NULL                                      , 'import.usp_import__computed_columns'                 , 'sys.computed_columns.sql'                 , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.computed_columns;')    -- As of SQL Server 2022, there are no system computed columns
                ,  (      -391, 'sys.columns'                               , 2, 1440, NULL                                      , 'import.usp_import__columns'                          , 'sys.columns.sql'                          , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.columns x           WHERE EXISTS (SELECT * FROM sys.objects o WHERE o.[object_id] = x.[object_id] AND o.is_ms_shipped = 0);')
                ,  (      -387, 'sys.views'                                 , 2,  480, NULL                                      , 'import.usp_import__views'                            , 'sys.views.sql'                            , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.views               WHERE is_ms_shipped = 0;')
                ,  (      -386, 'sys.tables'                                , 2,  480, NULL                                      , 'import.usp_import__tables'                           , 'sys.tables.sql'                           , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM([name], [object_id], principal_id, [schema_id], parent_object_id, [type], is_published, is_schema_published, lob_data_space_id, filestream_data_space_id, max_column_id_used, lock_on_bulk_load, uses_ansi_nulls, is_replicated, has_replication_filter, is_merge_published, is_sync_tran_subscribed, has_unchecked_assembly_data, text_in_row_limit, large_value_types_out_of_row, is_tracked_by_cdc, [lock_escalation], is_filetable, is_memory_optimized, [durability], temporal_type, history_table_id, is_remote_data_archive_enabled, is_external, history_retention_period, history_retention_period_unit, is_node, is_edge)), 0)
                                                                                                                                                                                                                                                                                       FROM sys.tables              WHERE is_ms_shipped = 0;')
                ,  (      -385, 'sys.objects'                               , 2,  360, NULL                                      , 'import.usp_import__objects'                          , 'sys.objects.sql'                          , NULL) -- No checksum; sys.objects is typically a pretty light query to run. The checksum query ended up being heavier than to just pull the data.
                ,  (      -252, 'sys.server_event_sessions'                 , 1,  480, 'dbo._server_event_sessions'              , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.server_event_sessions;')
                ,  (      -224, 'sys.configurations'                        , 1, 1440, NULL                                      , 'import.usp_import__configurations'                   , 'sys.configurations.sql'                   , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.configurations;')
                ,  (      -216, 'sys.master_files'                          , 1,  480, NULL                                      , 'import.usp_import__master_files'                     , 'sys.master_files.sql'                     , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.master_files;')
                ,  (      -213, 'sys.databases'                             , 1,  480, NULL                                      , 'import.usp_import__databases'                        , 'sys.databases.sql'                        , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM sys.databases;')
                ,  (         1, 'SERVERPROPERTY'                            , 1,  480, 'dbo._SERVERPROPERTY'                     , NULL                                                  , 'SERVERPROPERTY.sql'                       , NULL)
                ,  (         2, 'DATABASEPROPERTYEX'                        , 2,  480, 'dbo._DATABASEPROPERTYEX'                 , NULL                                                  , 'DATABASEPROPERTYEX.sql'                   , NULL)
                ,  (         3, 'msdb.dbo.restorehistory'                   , 1, 1440, 'dbo._restorehistory'                     , NULL                                                  , NULL                                       , 'SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM msdb.dbo.restorehistory;')
                ,  (         4, 'dbo.sysarticles'                           , 2,  480, NULL                                      , 'import.usp_import__sysarticles'                      , 'dbo.sysarticles.sql'                      , 'IF (OBJECT_ID(''dbo.sysarticles'')     IS NOT NULL) BEGIN; SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM dbo.sysarticles;     END; ELSE BEGIN; SELECT 0; END;')
                ,  (         5, 'dbo.syspublications'                       , 2, 1440, 'dbo._syspublications'                    , NULL                                                  , 'dbo.syspublications.sql'                  , 'IF (OBJECT_ID(''dbo.syspublications'') IS NOT NULL) BEGIN; SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM dbo.syspublications; END; ELSE BEGIN; SELECT 0; END;')
                ,  (         6, 'dbo.sysreplservers'                        , 2, 1440, 'dbo._sysreplservers'                     , NULL                                                  , 'dbo.sysreplservers.sql'                   , 'IF (OBJECT_ID(''dbo.sysreplservers'')  IS NOT NULL) BEGIN; SELECT COALESCE(CHECKSUM_AGG(CHECKSUM(*)), 0) FROM dbo.sysreplservers;  END; ELSE BEGIN; SELECT 0; END;')
                ,  (         7, 'global_variables'                          , 1,  480, 'dbo._global_variables'                   , NULL                                                  , 'global_variables.sql'                     , NULL)
                ,  (         8, 'OBJECTPROPERTYEX'                          , 2, 1440, NULL                                      , 'import.usp_import__OBJECTPROPERTYEX'                 , 'OBJECTPROPERTYEX.sql'                     , NULL)
                ,  (         9, 'missing_indexes'                           , 2,  480, NULL                                      , 'import.usp_import__missing_indexes'                  , 'missing_indexes.sql'                      , NULL)
        ) n (SyncObjectID, SyncObjectName, SyncObjectLevelID, SyncStaleAgeMinutes, ImportTable, ImportProc, ExportQueryPath, ChecksumQueryText);

    ALTER TABLE #tmp_SyncObject ADD IsEnabled bit NOT NULL DEFAULT (1);
    ALTER TABLE #tmp_SyncObject ADD OpportunisticSchedulingEnabled bit NOT NULL DEFAULT (1);
    ALTER TABLE #tmp_SyncObject ADD SyncOnZeroChecksum bit NOT NULL DEFAULT (1);

    UPDATE #tmp_SyncObject
    SET IsEnabled = 0
    WHERE SyncObjectName IN (
        'OBJECTPROPERTYEX' -- Turned out to be a very heavy export query and not enough useful info.
    );

    UPDATE #tmp_SyncObject
    SET OpportunisticSchedulingEnabled = 0
    WHERE SyncObjectName IN (
        'sys.dm_db_index_usage_stats',       -- Prefer to keep this on a regular schedule.
        'sys.dm_db_index_operational_stats', -- Prefer to keep this on a regular schedule.
        'sys.sql_modules'                    -- Heavy export and checksum queries. So only run on normal schedule.
    );

    UPDATE #tmp_SyncObject
    SET SyncOnZeroChecksum = 0
    WHERE SyncObjectName IN (
        'sys.sql_modules'
    );
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Perform checks against SyncObject configuration
    ------------------------------------------------------------------------------
        --DROP TABLE IF EXISTS #issues; --SELECT * FROM #issues
        CREATE TABLE #issues (
            SyncObjectID    int             NOT NULL,
            IssueDesc       nvarchar(128)   NOT NULL,
            Suggestion      nvarchar(256)       NULL,
            ProperName      nvarchar(128)       NULL,
        );
        ------------------------------------------

        ------------------------------------------
        -- Check for configuration issues
        ------------------------------------------
        -- Make sure everything is named properly before checking anything else
        INSERT #issues (SyncObjectID, IssueDesc, Suggestion, ProperName)
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad ImportTable Name'
            , Suggestion    = 'Fix ImportTable name to follow naming convention'
            , ProperName    = 'dbo._' + PARSENAME(so.SyncObjectName, 1)
        FROM #tmp_SyncObject so
        WHERE 'dbo._' + PARSENAME(so.SyncObjectName, 1) <> so.ImportTable
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad ImportProc Name'
            , Suggestion    = 'Fix ImportProc name to follow naming convention'
            , ProperName    = 'import.usp_import__' + PARSENAME(so.SyncObjectName, 1)
        FROM #tmp_SyncObject so
        WHERE 'import.usp_import__' + PARSENAME(so.SyncObjectName, 1) <> so.ImportProc
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad ExportQueryPath Name'
            , Suggestion    = 'ExportQueryPath name should match the SyncObjectName'
            , ProperName    = so.SyncObjectName + '.sql'
        FROM #tmp_SyncObject so
        WHERE so.SyncObjectName + '.sql' <> so.ExportQueryPath
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad ImportType Name'
            , Suggestion    = 'Fix ImportType name to follow naming convention'
            , ProperName    = 'import.import__' + PARSENAME(so.SyncObjectName, 1)
        FROM #tmp_SyncObject so
            CROSS APPLY (
                SELECT ImportType = CONCAT(SCHEMA_NAME(tt.[schema_id]), '.', tt.[name])
                FROM sys.parameters pa
                    JOIN sys.table_types tt ON tt.user_type_id = pa.user_type_id
                WHERE pa.[object_id] = OBJECT_ID(so.ImportProc, 'P') AND pa.[name] = '@Dataset'
            ) x
        WHERE so.ImportProc IS NOT NULL
            AND 'import.import__' + PARSENAME(so.SyncObjectName, 1) <> x.ImportType;

        IF EXISTS (SELECT * FROM #issues)
        BEGIN;
            SELECT i.*, N'█ SyncObject record --> █' [█ SyncObject record --> █], so.* FROM #issues i JOIN #tmp_SyncObject so ON so.SyncObjectID = i.SyncObjectID;
            THROW 51000, 'Configuration errors detected', 1;
        END;
        ------------------------------------------

        ------------------------------------------
        -- Now that the names have been checked, make sure those objects exist
        INSERT #issues (SyncObjectID, IssueDesc, Suggestion, ProperName)
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'ImportTable does not exist in database'
            , Suggestion    = 'Create missing table'
            , ProperName    = NULL
        FROM #tmp_SyncObject so
        WHERE so.IsEnabled = 1
            AND so.ImportTable IS NOT NULL
            AND OBJECT_ID(so.ImportTable, 'U') IS NULL
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'ImportProc does not exist in database'
            , Suggestion    = 'Create missing proc'
            , ProperName    = NULL
        FROM #tmp_SyncObject so
        WHERE so.IsEnabled = 1
            AND so.ImportProc IS NOT NULL
            AND OBJECT_ID(so.ImportProc, 'P') IS NULL;

        IF EXISTS (SELECT * FROM #issues)
        BEGIN;
            SELECT i.*, N'█ SyncObject record --> █' [█ SyncObject record --> █], so.* FROM #issues i JOIN #tmp_SyncObject so ON so.SyncObjectID = i.SyncObjectID;
            THROW 51000, 'Configuration errors detected', 1;
        END;
        ------------------------------------------

        ------------------------------------------
        INSERT #issues (SyncObjectID, IssueDesc, Suggestion, ProperName)
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'SyncObject changing levels with existing status records'
            , Suggestion    = 'Remove existing import.DatabaseSyncObjectStatus records before changing level'
            , ProperName    = NULL
        FROM #tmp_SyncObject tso
            JOIN import.SyncObject so ON so.SyncObjectID = tso.SyncObjectID
        WHERE so.SyncObjectLevelID <> tso.SyncObjectLevelID
            AND EXISTS (SELECT * FROM import.DatabaseSyncObjectStatus WHERE tso.SyncObjectID = tso.SyncObjectID)
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad configuration - SyncObject with both ImportTable and ImportProc'
            , Suggestion    = 'SyncObjects cannot have both an ImportTable and an ImportProc configured at the same time'
            , ProperName    = NULL
        FROM #tmp_SyncObject so
        WHERE so.IsEnabled = 1 AND so.ImportTable IS NOT NULL AND so.ImportProc IS NOT NULL
        UNION ALL
        SELECT SyncObjectID = so.SyncObjectID
            , IssueDesc     = 'Bad configuration - Missing ExportQueryPath'
            , Suggestion    = 'SyncObjects whose SyncObjectName does not match a system object must have an ExportQueryPath configured'
            , ProperName    = NULL
        FROM #tmp_SyncObject so
        WHERE so.IsEnabled = 1 AND COALESCE(so.ExportQueryPath, '') = ''
            AND NOT EXISTS (SELECT * FROM sys.system_objects s WHERE s.[object_id] = OBJECT_ID(so.SyncObjectName))
            AND NOT EXISTS (SELECT * FROM msdb.sys.objects s WHERE s.[object_id] = OBJECT_ID(so.SyncObjectName))

        IF EXISTS (SELECT * FROM #issues)
        BEGIN;
            SELECT i.*, N'█ SyncObject record --> █' [█ SyncObject record --> █], so.* FROM #issues i JOIN #tmp_SyncObject so ON so.SyncObjectID = i.SyncObjectID;
            THROW 51000, 'Configuration errors detected', 1;
        END;
        ------------------------------------------

        ------------------------------------------
        -- Ensure ChecksumQueryText parses
        ------------------------------------------
        IF EXISTS (
            SELECT *
            FROM #tmp_SyncObject so
                CROSS APPLY (
                    SELECT ColumnCount = COUNT(*), DataType = MAX(x.system_type_name)
                    FROM sys.dm_exec_describe_first_result_set(so.ChecksumQueryText, NULL, 0) x
                ) x
            WHERE so.IsEnabled = 1
                AND so.ChecksumQueryText IS NOT NULL
                AND (x.ColumnCount <> 1 OR x.DataType <> 'int')
        )
        BEGIN;
            DECLARE @errmsg nvarchar(500) = 'Configuration error: At least one ChecksumQueryText is incorrect.' + CHAR(13)+CHAR(10)
                                          + 'Potential reasons: more than 1 column returned, does not return an integer, does not parse';
            THROW 51000, @errmsg, 1;
        END;
        ------------------------------------------

        ------------------------------------------
        -- Ensure ImportProcs have the required parameters
        ------------------------------------------
        IF EXISTS (
            SELECT *
            FROM #tmp_SyncObject so
                JOIN sys.objects o ON o.[object_id] = OBJECT_ID(so.ImportProc, 'P')
            WHERE NOT EXISTS (
                    -- _InstanceID/_DatabaseID parameter is missing or has the wrong type
                    SELECT * FROM sys.parameters p
                    WHERE p.[object_id] = o.[object_id]
                        AND TYPE_NAME(p.system_type_id) = 'int'
                        AND p.[name] = CHOOSE(so.SyncObjectLevelID, '@InstanceID', '@DatabaseID')
                )
                OR NOT EXISTS (
                    -- Table valued parameter is missing or has the wrong type
                    SELECT *
                    FROM sys.parameters p
                    WHERE p.[object_id] = o.[object_id]
                        AND p.[name] = '@Dataset'
                        AND TYPE_NAME(p.system_type_id) = 'table type'
                )
        )
        BEGIN;
            THROW 51000, 'Schema error: At least one ImportProc is missing a required parameter or has the wrong type', 1;
        END;
        ------------------------------------------

        ------------------------------------------
        -- Ensure simple imports have correct schema
        ------------------------------------------
        IF EXISTS (
            SELECT *
            FROM #tmp_SyncObject so
                JOIN sys.objects o ON o.[object_id] = OBJECT_ID(so.ImportTable, 'U')
            WHERE so.ImportTable IS NOT NULL
                AND NOT EXISTS (
                    SELECT *
                    FROM sys.columns c
                    WHERE c.[object_id] = o.[object_id]
                        AND c.column_id = 1
                        AND c.[name] = CHOOSE(so.SyncObjectLevelID, '_InstanceID', '_DatabaseID')
                )
        )
        BEGIN;
            THROW 51000, 'Schema error: The first column on an ImportTable for simple imports should be either the _DatabaseID or _InstanceID', 1;
        END;

        IF EXISTS (
            SELECT *
            FROM #tmp_SyncObject so
                JOIN sys.objects o ON o.[object_id] = OBJECT_ID(so.ImportTable, 'U')
            WHERE so.ImportTable IS NOT NULL
                AND NOT EXISTS (
                    SELECT *
                    FROM sys.columns c
                    WHERE c.[object_id] = o.[object_id]
                        AND c.column_id = 2
                        AND c.[name] = '_CollectionDate'
                        AND TYPE_NAME(c.system_type_id) = 'datetime2'
                )
        )
        BEGIN;
            THROW 51000, 'Schema error: The second column on an ImportTable for simple imports should be the _CollectionDate', 1;
        END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Update SyncObject configuration
    ------------------------------------------------------------------------------
        RAISERROR('Updating: import.SyncObject ',0,1) WITH NOWAIT;
        MERGE INTO import.SyncObject WITH(HOLDLOCK) o
        USING #tmp_SyncObject n ON o.SyncObjectID = n.SyncObjectID
        WHEN MATCHED
        THEN UPDATE
            SET SyncObjectName                 = n.SyncObjectName,
                SyncObjectLevelID              = n.SyncObjectLevelID,
                IsEnabled                      = n.IsEnabled,
                SyncStaleAgeMinutes            = n.SyncStaleAgeMinutes,
                OpportunisticSchedulingEnabled = n.OpportunisticSchedulingEnabled,
                ImportTable                    = n.ImportTable,
                ImportProc                     = n.ImportProc,
                ExportQueryPath                = n.ExportQueryPath,
                SyncOnZeroChecksum             = n.SyncOnZeroChecksum,
                ChecksumQueryText              = n.ChecksumQueryText
        WHEN NOT MATCHED BY TARGET
        THEN
            INSERT (SyncObjectID, SyncObjectName, SyncObjectLevelID, IsEnabled, SyncStaleAgeMinutes, OpportunisticSchedulingEnabled, ImportTable, ImportProc, ExportQueryPath, SyncOnZeroChecksum, ChecksumQueryText)
            VALUES (n.SyncObjectID, n.SyncObjectName, n.SyncObjectLevelID, n.IsEnabled, n.SyncStaleAgeMinutes, n.OpportunisticSchedulingEnabled, n.ImportTable, n.ImportProc, n.ExportQueryPath, n.SyncOnZeroChecksum, n.ChecksumQueryText)
        WHEN NOT MATCHED BY SOURCE
        THEN DELETE -- Will only work if there are no sync records in import.DatabaseSyncObjectStatus
        OUTPUT $action, 'Deleted', Deleted.*, 'Inserted', Inserted.*;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
END;
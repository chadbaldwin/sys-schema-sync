DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = x.[name]
        , _ObjectType = x.[type]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , data_retention_period           = CONVERT(int         , NULL) -- Added: SQL Server 2022
        , data_retention_period_unit      = CONVERT(int         , NULL) -- Added: SQL Server 2022
        , data_retention_period_unit_desc = CONVERT(nvarchar(10), NULL) -- Added: SQL Server 2022
        , ledger_type                     = CONVERT(tinyint     , NULL) -- Added: SQL Server 2022
        , ledger_type_desc                = CONVERT(nvarchar(60), NULL) -- Added: SQL Server 2022
        , ledger_view_id                  = CONVERT(int         , NULL) -- Added: SQL Server 2022
        , is_dropped_ledger_table         = CONVERT(bit         , NULL) -- Added: SQL Server 2022
    FROM (
        SELECT x.[name], x.[object_id], x.principal_id, x.[schema_id], x.parent_object_id, x.[type], x.[type_desc], x.create_date/*, x.modify_date*/, x.is_ms_shipped, x.is_published, x.is_schema_published, x.lob_data_space_id, x.filestream_data_space_id, x.max_column_id_used, x.lock_on_bulk_load, x.uses_ansi_nulls, x.is_replicated, x.has_replication_filter, x.is_merge_published, x.is_sync_tran_subscribed, x.has_unchecked_assembly_data, x.text_in_row_limit, x.large_value_types_out_of_row, x.is_tracked_by_cdc, x.[lock_escalation], x.lock_escalation_desc, x.is_filetable, x.is_memory_optimized, x.[durability], x.durability_desc, x.temporal_type, x.temporal_type_desc, x.history_table_id, x.is_remote_data_archive_enabled, x.is_external, x.history_retention_period, x.history_retention_period_unit, x.history_retention_period_unit_desc, x.is_node, x.is_edge
        FROM sys.tables x
    ) x
        JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    WHERE x.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT x = 1 INTO #tmp -- hack for deferred name resolution to prevent a compile exception on the new 2022 columns when run on a non 2022 instance
    SELECT _SchemaName = s.[name]
        , _ObjectName = x.[name]
        , _ObjectType = x.[type]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM (
        SELECT x.[name], x.[object_id], x.principal_id, x.[schema_id], x.parent_object_id, x.[type], x.[type_desc], x.create_date/*, x.modify_date*/, x.is_ms_shipped, x.is_published, x.is_schema_published, x.lob_data_space_id, x.filestream_data_space_id, x.max_column_id_used, x.lock_on_bulk_load, x.uses_ansi_nulls, x.is_replicated, x.has_replication_filter, x.is_merge_published, x.is_sync_tran_subscribed, x.has_unchecked_assembly_data, x.text_in_row_limit, x.large_value_types_out_of_row, x.is_tracked_by_cdc, x.[lock_escalation], x.lock_escalation_desc, x.is_filetable, x.is_memory_optimized, x.[durability], x.durability_desc, x.temporal_type, x.temporal_type_desc, x.history_table_id, x.is_remote_data_archive_enabled, x.is_external, x.history_retention_period, x.history_retention_period_unit, x.history_retention_period_unit_desc, x.is_node, x.is_edge
            , x.data_retention_period, x.data_retention_period_unit, x.data_retention_period_unit_desc, x.ledger_type, x.ledger_type_desc, x.ledger_view_id, x.is_dropped_ledger_table
        FROM sys.tables x
            CROSS JOIN #tmp
    ) x
        JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
    WHERE x.is_ms_shipped = 0;
END;

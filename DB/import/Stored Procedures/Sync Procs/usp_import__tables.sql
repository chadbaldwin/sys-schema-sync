CREATE PROCEDURE import.usp_import__tables (
    @DatabaseID int,
    @Dataset    import.import__tables READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
         EXEC dbo.usp_Raiserror '[%s] Start: Get IDs', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._tables;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published, lob_data_space_id, filestream_data_space_id, max_column_id_used, lock_on_bulk_load, uses_ansi_nulls, is_replicated, has_replication_filter, is_merge_published, is_sync_tran_subscribed, has_unchecked_assembly_data, text_in_row_limit, large_value_types_out_of_row, is_tracked_by_cdc, [lock_escalation], lock_escalation_desc, is_filetable, is_memory_optimized, [durability], durability_desc, temporal_type, temporal_type_desc, history_table_id, is_remote_data_archive_enabled, is_external, history_retention_period, history_retention_period_unit, history_retention_period_unit_desc, is_node, is_edge, data_retention_period, data_retention_period_unit, data_retention_period_unit_desc, ledger_type, ledger_type_desc, ledger_view_id, is_dropped_ledger_table)
        SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.lob_data_space_id, d.filestream_data_space_id, d.max_column_id_used, d.lock_on_bulk_load, d.uses_ansi_nulls, d.is_replicated, d.has_replication_filter, d.is_merge_published, d.is_sync_tran_subscribed, d.has_unchecked_assembly_data, d.text_in_row_limit, d.large_value_types_out_of_row, d.is_tracked_by_cdc, d.[lock_escalation], d.lock_escalation_desc, d.is_filetable, d.is_memory_optimized, d.[durability], d.durability_desc, d.temporal_type, d.temporal_type_desc, d.history_table_id, d.is_remote_data_archive_enabled, d.is_external, d.history_retention_period, d.history_retention_period_unit, d.history_retention_period_unit_desc, d.is_node, d.is_edge, d.data_retention_period, d.data_retention_period_unit, d.data_retention_period_unit_desc, d.ledger_type, d.ledger_type_desc, d.ledger_view_id, d.is_dropped_ledger_table
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._tables';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._tables x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ModifyDate                        = SYSUTCDATETIME()
          , x._RowHash                           = d._RowHash
          , x.[name]                             = d.[name]
          , x.[object_id]                        = d.[object_id]
          , x.principal_id                       = d.principal_id
          , x.[schema_id]                        = d.[schema_id]
          , x.parent_object_id                   = d.parent_object_id
          , x.[type]                             = d.[type]
          , x.[type_desc]                        = d.[type_desc]
          , x.create_date                        = d.create_date
          , x.is_ms_shipped                      = d.is_ms_shipped
          , x.is_published                       = d.is_published
          , x.is_schema_published                = d.is_schema_published
          , x.lob_data_space_id                  = d.lob_data_space_id
          , x.filestream_data_space_id           = d.filestream_data_space_id
          , x.max_column_id_used                 = d.max_column_id_used
          , x.lock_on_bulk_load                  = d.lock_on_bulk_load
          , x.uses_ansi_nulls                    = d.uses_ansi_nulls
          , x.is_replicated                      = d.is_replicated
          , x.has_replication_filter             = d.has_replication_filter
          , x.is_merge_published                 = d.is_merge_published
          , x.is_sync_tran_subscribed            = d.is_sync_tran_subscribed
          , x.has_unchecked_assembly_data        = d.has_unchecked_assembly_data
          , x.text_in_row_limit                  = d.text_in_row_limit
          , x.large_value_types_out_of_row       = d.large_value_types_out_of_row
          , x.is_tracked_by_cdc                  = d.is_tracked_by_cdc
          , x.[lock_escalation]                  = d.[lock_escalation]
          , x.lock_escalation_desc               = d.lock_escalation_desc
          , x.is_filetable                       = d.is_filetable
          , x.is_memory_optimized                = d.is_memory_optimized
          , x.[durability]                       = d.[durability]
          , x.durability_desc                    = d.durability_desc
          , x.temporal_type                      = d.temporal_type
          , x.temporal_type_desc                 = d.temporal_type_desc
          , x.history_table_id                   = d.history_table_id
          , x.is_remote_data_archive_enabled     = d.is_remote_data_archive_enabled
          , x.is_external                        = d.is_external
          , x.history_retention_period           = d.history_retention_period
          , x.history_retention_period_unit      = d.history_retention_period_unit
          , x.history_retention_period_unit_desc = d.history_retention_period_unit_desc
          , x.is_node                            = d.is_node
          , x.is_edge                            = d.is_edge
          , x.data_retention_period              = d.data_retention_period
          , x.data_retention_period_unit         = d.data_retention_period_unit
          , x.data_retention_period_unit_desc    = d.data_retention_period_unit_desc
          , x.ledger_type                        = d.ledger_type
          , x.ledger_type_desc                   = d.ledger_type_desc
          , x.ledger_view_id                     = d.ledger_view_id
          , x.is_dropped_ledger_table            = d.is_dropped_ledger_table
        FROM dbo._tables x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._tables (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published, lob_data_space_id, filestream_data_space_id, max_column_id_used, lock_on_bulk_load, uses_ansi_nulls, is_replicated, has_replication_filter, is_merge_published, is_sync_tran_subscribed, has_unchecked_assembly_data, text_in_row_limit, large_value_types_out_of_row, is_tracked_by_cdc, [lock_escalation], lock_escalation_desc, is_filetable, is_memory_optimized, [durability], durability_desc, temporal_type, temporal_type_desc, history_table_id, is_remote_data_archive_enabled, is_external, history_retention_period, history_retention_period_unit, history_retention_period_unit_desc, is_node, is_edge, data_retention_period, data_retention_period_unit, data_retention_period_unit_desc, ledger_type, ledger_type_desc, ledger_view_id, is_dropped_ledger_table)
        SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.lob_data_space_id, d.filestream_data_space_id, d.max_column_id_used, d.lock_on_bulk_load, d.uses_ansi_nulls, d.is_replicated, d.has_replication_filter, d.is_merge_published, d.is_sync_tran_subscribed, d.has_unchecked_assembly_data, d.text_in_row_limit, d.large_value_types_out_of_row, d.is_tracked_by_cdc, d.[lock_escalation], d.lock_escalation_desc, d.is_filetable, d.is_memory_optimized, d.[durability], d.durability_desc, d.temporal_type, d.temporal_type_desc, d.history_table_id, d.is_remote_data_archive_enabled, d.is_external, d.history_retention_period, d.history_retention_period_unit, d.history_retention_period_unit_desc, d.is_node, d.is_edge, d.data_retention_period, d.data_retention_period_unit, d.data_retention_period_unit_desc, d.ledger_type, d.ledger_type_desc, d.ledger_view_id, d.is_dropped_ledger_table
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._tables x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
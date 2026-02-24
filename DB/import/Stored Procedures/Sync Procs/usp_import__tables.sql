CREATE PROC import.usp_import__tables (
    @DatabaseID int,
    @Dataset    import.import__tables READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_DatabaseID', @value = @DatabaseID;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._tables;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published, lob_data_space_id, filestream_data_space_id, max_column_id_used, lock_on_bulk_load, uses_ansi_nulls, is_replicated, has_replication_filter, is_merge_published, is_sync_tran_subscribed, has_unchecked_assembly_data, text_in_row_limit, large_value_types_out_of_row, is_tracked_by_cdc, [lock_escalation], lock_escalation_desc, is_filetable, is_memory_optimized, [durability], durability_desc, temporal_type, temporal_type_desc, history_table_id, is_remote_data_archive_enabled, is_external, history_retention_period, history_retention_period_unit, history_retention_period_unit_desc, is_node, is_edge, data_retention_period, data_retention_period_unit, data_retention_period_unit_desc, ledger_type, ledger_type_desc, ledger_view_id, is_dropped_ledger_table)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.lob_data_space_id, d.filestream_data_space_id, d.max_column_id_used, d.lock_on_bulk_load, d.uses_ansi_nulls, d.is_replicated, d.has_replication_filter, d.is_merge_published, d.is_sync_tran_subscribed, d.has_unchecked_assembly_data, d.text_in_row_limit, d.large_value_types_out_of_row, d.is_tracked_by_cdc, d.[lock_escalation], d.lock_escalation_desc, d.is_filetable, d.is_memory_optimized, d.[durability], d.durability_desc, d.temporal_type, d.temporal_type_desc, d.history_table_id, d.is_remote_data_archive_enabled, d.is_external, d.history_retention_period, d.history_retention_period_unit, d.history_retention_period_unit_desc, d.is_node, d.is_edge, d.data_retention_period, d.data_retention_period_unit, d.data_retention_period_unit_desc, d.ledger_type, d.ledger_type_desc, d.ledger_view_id, d.is_dropped_ledger_table
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @CallingProcName = @ProcName, @TargetTable = 'dbo._tables';
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @proc_sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @proc_sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
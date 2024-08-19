CREATE PROCEDURE import.usp_import__tables (
    @DatabaseID int,
    @Dataset    import.import__tables READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
    SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._tables';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._tables x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o.ObjectID = x._ObjectID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                         = SYSUTCDATETIME()
        , x._RowHash                            = d._RowHash
        --
        , x.[name]                              = d.[name]
        , x.[object_id]                         = d.[object_id]
        , x.principal_id                        = d.principal_id
        , x.[schema_id]                         = d.[schema_id]
        , x.parent_object_id                    = d.parent_object_id
        , x.[type]                              = d.[type]
        , x.[type_desc]                         = d.[type_desc]
        , x.create_date                         = d.create_date
        , x.is_ms_shipped                       = d.is_ms_shipped
        , x.is_published                        = d.is_published
        , x.is_schema_published                 = d.is_schema_published
        --
        , x.lob_data_space_id                   = d.lob_data_space_id
        , x.filestream_data_space_id            = d.filestream_data_space_id
        , x.max_column_id_used                  = d.max_column_id_used
        , x.lock_on_bulk_load                   = d.lock_on_bulk_load
        , x.uses_ansi_nulls                     = d.uses_ansi_nulls
        , x.is_replicated                       = d.is_replicated
        , x.has_replication_filter              = d.has_replication_filter
        , x.is_merge_published                  = d.is_merge_published
        , x.is_sync_tran_subscribed             = d.is_sync_tran_subscribed
        , x.has_unchecked_assembly_data         = d.has_unchecked_assembly_data
        , x.text_in_row_limit                   = d.text_in_row_limit
        , x.large_value_types_out_of_row        = d.large_value_types_out_of_row
        , x.is_tracked_by_cdc                   = d.is_tracked_by_cdc
        , x.[lock_escalation]                   = d.[lock_escalation]
        , x.lock_escalation_desc                = d.lock_escalation_desc
        , x.is_filetable                        = d.is_filetable
        , x.is_memory_optimized                 = d.is_memory_optimized
        , x.[durability]                        = d.[durability]
        , x.durability_desc                     = d.durability_desc
        , x.temporal_type                       = d.temporal_type
        , x.temporal_type_desc                  = d.temporal_type_desc
        , x.history_table_id                    = d.history_table_id
        , x.is_remote_data_archive_enabled      = d.is_remote_data_archive_enabled
        , x.is_external                         = d.is_external
        , x.history_retention_period            = d.history_retention_period
        , x.history_retention_period_unit       = d.history_retention_period_unit
        , x.history_retention_period_unit_desc  = d.history_retention_period_unit_desc
        , x.is_node                             = d.is_node
        , x.is_edge                             = d.is_edge
        , x.data_retention_period               = d.data_retention_period
        , x.data_retention_period_unit          = d.data_retention_period_unit
        , x.data_retention_period_unit_desc     = d.data_retention_period_unit_desc
        , x.ledger_type                         = d.ledger_type
        , x.ledger_type_desc                    = d.ledger_type_desc
        , x.ledger_view_id                      = d.ledger_view_id
        , x.is_dropped_ledger_table             = d.is_dropped_ledger_table
    FROM dbo._tables x
        JOIN @output y ON y.ObjectID = x._ObjectID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._tables (_DatabaseID, _ObjectID, _RowHash
        , [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published
        , lob_data_space_id, filestream_data_space_id, max_column_id_used, lock_on_bulk_load, uses_ansi_nulls, is_replicated, has_replication_filter, is_merge_published, is_sync_tran_subscribed, has_unchecked_assembly_data, text_in_row_limit, large_value_types_out_of_row, is_tracked_by_cdc, [lock_escalation], lock_escalation_desc, is_filetable, is_memory_optimized, [durability], durability_desc, temporal_type, temporal_type_desc, history_table_id, is_remote_data_archive_enabled, is_external, history_retention_period, history_retention_period_unit, history_retention_period_unit_desc, is_node, is_edge, data_retention_period, data_retention_period_unit, data_retention_period_unit_desc, ledger_type, ledger_type_desc, ledger_view_id, is_dropped_ledger_table)
    SELECT @DatabaseID, y.ObjectID, d._RowHash
        , d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published
        , d.lob_data_space_id, d.filestream_data_space_id, d.max_column_id_used, d.lock_on_bulk_load, d.uses_ansi_nulls, d.is_replicated, d.has_replication_filter, d.is_merge_published, d.is_sync_tran_subscribed, d.has_unchecked_assembly_data, d.text_in_row_limit, d.large_value_types_out_of_row, d.is_tracked_by_cdc, d.[lock_escalation], d.lock_escalation_desc, d.is_filetable, d.is_memory_optimized, d.[durability], d.durability_desc, d.temporal_type, d.temporal_type_desc, d.history_table_id, d.is_remote_data_archive_enabled, d.is_external, d.history_retention_period, d.history_retention_period_unit, d.history_retention_period_unit_desc, d.is_node, d.is_edge, d.data_retention_period, d.data_retention_period_unit, d.data_retention_period_unit_desc, d.ledger_type, d.ledger_type_desc, d.ledger_view_id, d.is_dropped_ledger_table
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._tables x
            WHERE x._ObjectID = y.ObjectID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

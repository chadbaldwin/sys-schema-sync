CREATE PROC import.usp_import__dm_db_index_operational_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_operational_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;
    EXEC sp_set_session_context N'_DatabaseID', @DatabaseID;

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
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_index_operational_stats;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, _BoundaryValue);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _IndexID, _BoundaryValue, EstimatedStatsBeginTime, StatsEndTime, database_id, [object_id], index_id, partition_number, hobt_id, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count, leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count, page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow)
            SELECT @DatabaseID, o._IndexID
                , COALESCE(d._BoundaryValue, '<<OPEN BOUNDARY>>')
                , d.EstimatedStatsBeginTime, d.StatsEndTime
                , d.__database_id, d.__object_id, d.__index_id, d.__partition_number, d.__hobt_id
                , COALESCE(d.leaf_insert_count, 0)
                , COALESCE(d.leaf_delete_count, 0)
                , COALESCE(d.leaf_update_count, 0)
                , COALESCE(d.leaf_ghost_count, 0)
                , COALESCE(d.nonleaf_insert_count, 0)
                , COALESCE(d.nonleaf_delete_count, 0)
                , COALESCE(d.nonleaf_update_count, 0)
                , COALESCE(d.leaf_allocation_count, 0)
                , COALESCE(d.nonleaf_allocation_count, 0)
                , COALESCE(d.leaf_page_merge_count, 0)
                , COALESCE(d.nonleaf_page_merge_count, 0)
                , COALESCE(d.range_scan_count, 0)
                , COALESCE(d.singleton_lookup_count, 0)
                , COALESCE(d.forwarded_fetch_count, 0)
                , COALESCE(d.lob_fetch_in_pages, 0)
                , COALESCE(d.lob_fetch_in_bytes, 0)
                , COALESCE(d.lob_orphan_create_count, 0)
                , COALESCE(d.lob_orphan_insert_count, 0)
                , COALESCE(d.row_overflow_fetch_in_pages, 0)
                , COALESCE(d.row_overflow_fetch_in_bytes, 0)
                , COALESCE(d.column_value_push_off_row_count, 0)
                , COALESCE(d.column_value_pull_in_row_count, 0)
                , COALESCE(d.row_lock_count, 0)
                , COALESCE(d.row_lock_wait_count, 0)
                , COALESCE(d.row_lock_wait_in_ms, 0)
                , COALESCE(d.page_lock_count, 0)
                , COALESCE(d.page_lock_wait_count, 0)
                , COALESCE(d.page_lock_wait_in_ms, 0)
                , COALESCE(d.index_lock_promotion_attempt_count, 0)
                , COALESCE(d.index_lock_promotion_count, 0)
                , COALESCE(d.page_latch_wait_count, 0)
                , COALESCE(d.page_latch_wait_in_ms, 0)
                , COALESCE(d.page_io_latch_wait_count, 0)
                , COALESCE(d.page_io_latch_wait_in_ms, 0)
                , COALESCE(d.tree_page_latch_wait_count, 0)
                , COALESCE(d.tree_page_latch_wait_in_ms, 0)
                , COALESCE(d.tree_page_io_latch_wait_count, 0)
                , COALESCE(d.tree_page_io_latch_wait_in_ms, 0)
                , COALESCE(d.page_compression_attempt_count, 0)
                , COALESCE(d.page_compression_success_count, 0)
                , COALESCE(d.version_generated_inrow, 0)
                , COALESCE(d.version_generated_offrow, 0)
                , COALESCE(d.ghost_version_inrow, 0)
                , COALESCE(d.ghost_version_offrow, 0)
                , COALESCE(d.insert_over_ghost_version_inrow, 0)
                , COALESCE(d.insert_over_ghost_version_offrow, 0)
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs
            -- Record delta history before updating table
            EXEC dw.usp_import__dm_db_index_operational_stats_delta @DatabaseID = @DatabaseID;

            /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
                so it will always return every index. The only time indexes will be deleted is when
                they have been completely dropped from the database and never re-created. */
            EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @CallingProcName = @ProcName, @TargetTable = 'dbo._dm_db_index_operational_stats';
        COMMIT;
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
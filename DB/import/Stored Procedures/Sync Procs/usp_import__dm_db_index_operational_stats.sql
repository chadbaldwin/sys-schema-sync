CREATE PROCEDURE import.usp_import__dm_db_index_operational_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_operational_stats READONLY,
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
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_index_operational_stats;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
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
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs

        -- Record delta history before updating table
        EXEC dw.usp_import__dm_db_index_operational_stats_delta @DatabaseID = @DatabaseID;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_operational_stats';

        /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
            so it will always return every index. The only time indexes will be deleted is when
            they have been completely dropped from the database and never re-created. */
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._dm_db_index_operational_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x.EstimatedStatsBeginTime            = d.EstimatedStatsBeginTime
          , x.StatsEndTime                       = d.StatsEndTime
          , x.database_id                        = d.database_id
          , x.[object_id]                        = d.[object_id]
          , x.index_id                           = d.index_id
          , x.partition_number                   = d.partition_number
          , x.hobt_id                            = d.hobt_id
          , x.leaf_insert_count                  = d.leaf_insert_count
          , x.leaf_delete_count                  = d.leaf_delete_count
          , x.leaf_update_count                  = d.leaf_update_count
          , x.leaf_ghost_count                   = d.leaf_ghost_count
          , x.nonleaf_insert_count               = d.nonleaf_insert_count
          , x.nonleaf_delete_count               = d.nonleaf_delete_count
          , x.nonleaf_update_count               = d.nonleaf_update_count
          , x.leaf_allocation_count              = d.leaf_allocation_count
          , x.nonleaf_allocation_count           = d.nonleaf_allocation_count
          , x.leaf_page_merge_count              = d.leaf_page_merge_count
          , x.nonleaf_page_merge_count           = d.nonleaf_page_merge_count
          , x.range_scan_count                   = d.range_scan_count
          , x.singleton_lookup_count             = d.singleton_lookup_count
          , x.forwarded_fetch_count              = d.forwarded_fetch_count
          , x.lob_fetch_in_pages                 = d.lob_fetch_in_pages
          , x.lob_fetch_in_bytes                 = d.lob_fetch_in_bytes
          , x.lob_orphan_create_count            = d.lob_orphan_create_count
          , x.lob_orphan_insert_count            = d.lob_orphan_insert_count
          , x.row_overflow_fetch_in_pages        = d.row_overflow_fetch_in_pages
          , x.row_overflow_fetch_in_bytes        = d.row_overflow_fetch_in_bytes
          , x.column_value_push_off_row_count    = d.column_value_push_off_row_count
          , x.column_value_pull_in_row_count     = d.column_value_pull_in_row_count
          , x.row_lock_count                     = d.row_lock_count
          , x.row_lock_wait_count                = d.row_lock_wait_count
          , x.row_lock_wait_in_ms                = d.row_lock_wait_in_ms
          , x.page_lock_count                    = d.page_lock_count
          , x.page_lock_wait_count               = d.page_lock_wait_count
          , x.page_lock_wait_in_ms               = d.page_lock_wait_in_ms
          , x.index_lock_promotion_attempt_count = d.index_lock_promotion_attempt_count
          , x.index_lock_promotion_count         = d.index_lock_promotion_count
          , x.page_latch_wait_count              = d.page_latch_wait_count
          , x.page_latch_wait_in_ms              = d.page_latch_wait_in_ms
          , x.page_io_latch_wait_count           = d.page_io_latch_wait_count
          , x.page_io_latch_wait_in_ms           = d.page_io_latch_wait_in_ms
          , x.tree_page_latch_wait_count         = d.tree_page_latch_wait_count
          , x.tree_page_latch_wait_in_ms         = d.tree_page_latch_wait_in_ms
          , x.tree_page_io_latch_wait_count      = d.tree_page_io_latch_wait_count
          , x.tree_page_io_latch_wait_in_ms      = d.tree_page_io_latch_wait_in_ms
          , x.page_compression_attempt_count     = d.page_compression_attempt_count
          , x.page_compression_success_count     = d.page_compression_success_count
          , x.version_generated_inrow            = d.version_generated_inrow
          , x.version_generated_offrow           = d.version_generated_offrow
          , x.ghost_version_inrow                = d.ghost_version_inrow
          , x.ghost_version_offrow               = d.ghost_version_offrow
          , x.insert_over_ghost_version_inrow    = d.insert_over_ghost_version_inrow
          , x.insert_over_ghost_version_offrow   = d.insert_over_ghost_version_offrow
        FROM dbo._dm_db_index_operational_stats x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._dm_db_index_operational_stats (_DatabaseID, _IndexID, _BoundaryValue, EstimatedStatsBeginTime, StatsEndTime, database_id, [object_id], index_id, partition_number, hobt_id, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count, leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count, page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow)
        SELECT d._DatabaseID, d._IndexID, d._BoundaryValue, d.EstimatedStatsBeginTime, d.StatsEndTime, d.database_id, d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.leaf_insert_count, d.leaf_delete_count, d.leaf_update_count, d.leaf_ghost_count, d.nonleaf_insert_count, d.nonleaf_delete_count, d.nonleaf_update_count, d.leaf_allocation_count, d.nonleaf_allocation_count, d.leaf_page_merge_count, d.nonleaf_page_merge_count, d.range_scan_count, d.singleton_lookup_count, d.forwarded_fetch_count, d.lob_fetch_in_pages, d.lob_fetch_in_bytes, d.lob_orphan_create_count, d.lob_orphan_insert_count, d.row_overflow_fetch_in_pages, d.row_overflow_fetch_in_bytes, d.column_value_push_off_row_count, d.column_value_pull_in_row_count, d.row_lock_count, d.row_lock_wait_count, d.row_lock_wait_in_ms, d.page_lock_count, d.page_lock_wait_count, d.page_lock_wait_in_ms, d.index_lock_promotion_attempt_count, d.index_lock_promotion_count, d.page_latch_wait_count, d.page_latch_wait_in_ms, d.page_io_latch_wait_count, d.page_io_latch_wait_in_ms, d.tree_page_latch_wait_count, d.tree_page_latch_wait_in_ms, d.tree_page_io_latch_wait_count, d.tree_page_io_latch_wait_in_ms, d.page_compression_attempt_count, d.page_compression_success_count, d.version_generated_inrow, d.version_generated_offrow, d.ghost_version_inrow, d.ghost_version_offrow, d.insert_over_ghost_version_inrow, d.insert_over_ghost_version_offrow
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_index_operational_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
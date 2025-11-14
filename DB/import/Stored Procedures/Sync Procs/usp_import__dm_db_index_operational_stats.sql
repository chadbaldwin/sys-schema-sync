CREATE PROCEDURE import.usp_import__dm_db_index_operational_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_operational_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Need to do some quick transformations of the incoming data to adjust for things like UTC conversions and handling nulls
    -- Doing this here instead of on export allows for keeping the export query simpler.
    DECLARE @DatasetTransformed import.import__dm_db_index_operational_stats;
    INSERT @DatasetTransformed (
        __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName, _BoundaryValue
        , EstimatedStatsBeginTime, StatsEndTime
        , database_id, [object_id], index_id, partition_number, hobt_id
        , leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count, leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count, page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName
        , COALESCE(_BoundaryValue, '<<OPEN BOUNDARY>>')
        , EstimatedStatsBeginTime, StatsEndTime
        , __database_id, __object_id, __index_id, __partition_number, __hobt_id
        , COALESCE(leaf_insert_count, 0)
        , COALESCE(leaf_delete_count, 0)
        , COALESCE(leaf_update_count, 0)
        , COALESCE(leaf_ghost_count, 0)
        , COALESCE(nonleaf_insert_count, 0)
        , COALESCE(nonleaf_delete_count, 0)
        , COALESCE(nonleaf_update_count, 0)
        , COALESCE(leaf_allocation_count, 0)
        , COALESCE(nonleaf_allocation_count, 0)
        , COALESCE(leaf_page_merge_count, 0)
        , COALESCE(nonleaf_page_merge_count, 0)
        , COALESCE(range_scan_count, 0)
        , COALESCE(singleton_lookup_count, 0)
        , COALESCE(forwarded_fetch_count, 0)
        , COALESCE(lob_fetch_in_pages, 0)
        , COALESCE(lob_fetch_in_bytes, 0)
        , COALESCE(lob_orphan_create_count, 0)
        , COALESCE(lob_orphan_insert_count, 0)
        , COALESCE(row_overflow_fetch_in_pages, 0)
        , COALESCE(row_overflow_fetch_in_bytes, 0)
        , COALESCE(column_value_push_off_row_count, 0)
        , COALESCE(column_value_pull_in_row_count, 0)
        , COALESCE(row_lock_count, 0)
        , COALESCE(row_lock_wait_count, 0)
        , COALESCE(row_lock_wait_in_ms, 0)
        , COALESCE(page_lock_count, 0)
        , COALESCE(page_lock_wait_count, 0)
        , COALESCE(page_lock_wait_in_ms, 0)
        , COALESCE(index_lock_promotion_attempt_count, 0)
        , COALESCE(index_lock_promotion_count, 0)
        , COALESCE(page_latch_wait_count, 0)
        , COALESCE(page_latch_wait_in_ms, 0)
        , COALESCE(page_io_latch_wait_count, 0)
        , COALESCE(page_io_latch_wait_in_ms, 0)
        , COALESCE(tree_page_latch_wait_count, 0)
        , COALESCE(tree_page_latch_wait_in_ms, 0)
        , COALESCE(tree_page_io_latch_wait_count, 0)
        , COALESCE(tree_page_io_latch_wait_in_ms, 0)
        , COALESCE(page_compression_attempt_count, 0)
        , COALESCE(page_compression_success_count, 0)
        , COALESCE(version_generated_inrow, 0)
        , COALESCE(version_generated_offrow, 0)
        , COALESCE(ghost_version_inrow, 0)
        , COALESCE(ghost_version_offrow, 0)
        , COALESCE(insert_over_ghost_version_inrow, 0)
        , COALESCE(insert_over_ghost_version_offrow, 0)
    FROM @Dataset;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @DatasetTransformed;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT _DatabaseID   = @DatabaseID
        , _IndexID       = o._IndexID
        , _BoundaryValue = d._BoundaryValue
        , d.EstimatedStatsBeginTime, d.StatsEndTime, d.database_id, d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.leaf_insert_count, d.leaf_delete_count, d.leaf_update_count, d.leaf_ghost_count, d.nonleaf_insert_count, d.nonleaf_delete_count, d.nonleaf_update_count, d.leaf_allocation_count, d.nonleaf_allocation_count, d.leaf_page_merge_count, d.nonleaf_page_merge_count, d.range_scan_count, d.singleton_lookup_count, d.forwarded_fetch_count, d.lob_fetch_in_pages, d.lob_fetch_in_bytes, d.lob_orphan_create_count, d.lob_orphan_insert_count, d.row_overflow_fetch_in_pages, d.row_overflow_fetch_in_bytes, d.column_value_push_off_row_count, d.column_value_pull_in_row_count, d.row_lock_count, d.row_lock_wait_count, d.row_lock_wait_in_ms, d.page_lock_count, d.page_lock_wait_count, d.page_lock_wait_in_ms, d.index_lock_promotion_attempt_count, d.index_lock_promotion_count, d.page_latch_wait_count, d.page_latch_wait_in_ms, d.page_io_latch_wait_count, d.page_io_latch_wait_in_ms, d.tree_page_latch_wait_count, d.tree_page_latch_wait_in_ms, d.tree_page_io_latch_wait_count, d.tree_page_io_latch_wait_in_ms, d.page_compression_attempt_count, d.page_compression_success_count, d.version_generated_inrow, d.version_generated_offrow, d.ghost_version_inrow, d.ghost_version_offrow, d.insert_over_ghost_version_inrow, d.insert_over_ghost_version_offrow
    INTO #tmp_Dataset
    FROM @DatasetTransformed d
        JOIN @output o ON o.ID = d.__ID;

    CREATE INDEX IX ON #tmp_Dataset (_DatabaseID, _IndexID);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs

        -- Record delta history before updating table
        EXEC dw.usp_import__dm_db_index_operational_stats_delta @DatabaseID = @DatabaseID, @Dataset = @DatasetTransformed, @ItemName = @output, @Verbose = @Verbose;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_operational_stats';

        /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
            so it will always return every index. The only time indexes will be deleted is when
            they have been completely dropped from the database and never re-created. */
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._dm_db_index_operational_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #tmp_Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
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
            JOIN #tmp_Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._dm_db_index_operational_stats (_DatabaseID, _IndexID, _BoundaryValue, EstimatedStatsBeginTime, StatsEndTime, database_id, [object_id], index_id, partition_number, hobt_id, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count, leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count, page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow)
        SELECT d._DatabaseID, d._IndexID, d._BoundaryValue, d.EstimatedStatsBeginTime, d.StatsEndTime, d.database_id, d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.leaf_insert_count, d.leaf_delete_count, d.leaf_update_count, d.leaf_ghost_count, d.nonleaf_insert_count, d.nonleaf_delete_count, d.nonleaf_update_count, d.leaf_allocation_count, d.nonleaf_allocation_count, d.leaf_page_merge_count, d.nonleaf_page_merge_count, d.range_scan_count, d.singleton_lookup_count, d.forwarded_fetch_count, d.lob_fetch_in_pages, d.lob_fetch_in_bytes, d.lob_orphan_create_count, d.lob_orphan_insert_count, d.row_overflow_fetch_in_pages, d.row_overflow_fetch_in_bytes, d.column_value_push_off_row_count, d.column_value_pull_in_row_count, d.row_lock_count, d.row_lock_wait_count, d.row_lock_wait_in_ms, d.page_lock_count, d.page_lock_wait_count, d.page_lock_wait_in_ms, d.index_lock_promotion_attempt_count, d.index_lock_promotion_count, d.page_latch_wait_count, d.page_latch_wait_in_ms, d.page_io_latch_wait_count, d.page_io_latch_wait_in_ms, d.tree_page_latch_wait_count, d.tree_page_latch_wait_in_ms, d.tree_page_io_latch_wait_count, d.tree_page_io_latch_wait_in_ms, d.page_compression_attempt_count, d.page_compression_success_count, d.version_generated_inrow, d.version_generated_offrow, d.ghost_version_inrow, d.ghost_version_offrow, d.insert_over_ghost_version_inrow, d.insert_over_ghost_version_offrow
        FROM #tmp_Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_index_operational_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
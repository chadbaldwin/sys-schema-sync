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
    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT o._ObjectID, o._IndexID, o._ColumnID, d.*
    INTO #Dataset
    FROM @output o
        JOIN @Dataset d ON d.__ID = o.ID;

    CREATE CLUSTERED INDEX CIX ON #Dataset (_IndexID, _BoundaryValue);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs

        -- Record delta history before updating table
        --EXEC dw.usp_import__dm_db_index_operational_stats_delta_history @DatabaseID = @DatabaseID, @Dataset = @Dataset, @ItemName = @output, @Verbose = @Verbose;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_operational_stats';

        /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
            so it will always return every index. The only time indexes will be deleted is when
            they have been completely dropped from the database and never re-created. */
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._dm_db_index_operational_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (
                SELECT *
                FROM #Dataset d
                WHERE d._IndexID = x._IndexID
                    AND d._BoundaryValue = x._BoundaryValue
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x.EstimatedStatsBeginTime            = d.EstimatedStatsBeginTime
            , x.StatsEndTime                       = d.StatsEndTime
            --
            , x.database_id                        = d.database_id
            , x.[object_id]                        = d.[object_id]
            , x.index_id                           = d.index_id
            , x.partition_number                   = d.partition_number
            , x.hobt_id                            = d.hobt_id
            , x.leaf_insert_count                  = COALESCE(d.leaf_insert_count, 0)
            , x.leaf_delete_count                  = COALESCE(d.leaf_delete_count, 0)
            , x.leaf_update_count                  = COALESCE(d.leaf_update_count, 0)
            , x.leaf_ghost_count                   = COALESCE(d.leaf_ghost_count, 0)
            , x.nonleaf_insert_count               = COALESCE(d.nonleaf_insert_count, 0)
            , x.nonleaf_delete_count               = COALESCE(d.nonleaf_delete_count, 0)
            , x.nonleaf_update_count               = COALESCE(d.nonleaf_update_count, 0)
            , x.leaf_allocation_count              = COALESCE(d.leaf_allocation_count, 0)
            , x.nonleaf_allocation_count           = COALESCE(d.nonleaf_allocation_count, 0)
            , x.leaf_page_merge_count              = COALESCE(d.leaf_page_merge_count, 0)
            , x.nonleaf_page_merge_count           = COALESCE(d.nonleaf_page_merge_count, 0)
            , x.range_scan_count                   = COALESCE(d.range_scan_count, 0)
            , x.singleton_lookup_count             = COALESCE(d.singleton_lookup_count, 0)
            , x.forwarded_fetch_count              = COALESCE(d.forwarded_fetch_count, 0)
            , x.lob_fetch_in_pages                 = COALESCE(d.lob_fetch_in_pages, 0)
            , x.lob_fetch_in_bytes                 = COALESCE(d.lob_fetch_in_bytes, 0)
            , x.lob_orphan_create_count            = COALESCE(d.lob_orphan_create_count, 0)
            , x.lob_orphan_insert_count            = COALESCE(d.lob_orphan_insert_count, 0)
            , x.row_overflow_fetch_in_pages        = COALESCE(d.row_overflow_fetch_in_pages, 0)
            , x.row_overflow_fetch_in_bytes        = COALESCE(d.row_overflow_fetch_in_bytes, 0)
            , x.column_value_push_off_row_count    = COALESCE(d.column_value_push_off_row_count, 0)
            , x.column_value_pull_in_row_count     = COALESCE(d.column_value_pull_in_row_count, 0)
            , x.row_lock_count                     = COALESCE(d.row_lock_count, 0)
            , x.row_lock_wait_count                = COALESCE(d.row_lock_wait_count, 0)
            , x.row_lock_wait_in_ms                = COALESCE(d.row_lock_wait_in_ms, 0)
            , x.page_lock_count                    = COALESCE(d.page_lock_count, 0)
            , x.page_lock_wait_count               = COALESCE(d.page_lock_wait_count, 0)
            , x.page_lock_wait_in_ms               = COALESCE(d.page_lock_wait_in_ms, 0)
            , x.index_lock_promotion_attempt_count = COALESCE(d.index_lock_promotion_attempt_count, 0)
            , x.index_lock_promotion_count         = COALESCE(d.index_lock_promotion_count, 0)
            , x.page_latch_wait_count              = COALESCE(d.page_latch_wait_count, 0)
            , x.page_latch_wait_in_ms              = COALESCE(d.page_latch_wait_in_ms, 0)
            , x.page_io_latch_wait_count           = COALESCE(d.page_io_latch_wait_count, 0)
            , x.page_io_latch_wait_in_ms           = COALESCE(d.page_io_latch_wait_in_ms, 0)
            , x.tree_page_latch_wait_count         = COALESCE(d.tree_page_latch_wait_count, 0)
            , x.tree_page_latch_wait_in_ms         = COALESCE(d.tree_page_latch_wait_in_ms, 0)
            , x.tree_page_io_latch_wait_count      = COALESCE(d.tree_page_io_latch_wait_count, 0)
            , x.tree_page_io_latch_wait_in_ms      = COALESCE(d.tree_page_io_latch_wait_in_ms, 0)
            , x.page_compression_attempt_count     = COALESCE(d.page_compression_attempt_count, 0)
            , x.page_compression_success_count     = COALESCE(d.page_compression_success_count, 0)
            , x.version_generated_inrow            = COALESCE(d.version_generated_inrow, 0)
            , x.version_generated_offrow           = COALESCE(d.version_generated_offrow, 0)
            , x.ghost_version_inrow                = COALESCE(d.ghost_version_inrow, 0)
            , x.ghost_version_offrow               = COALESCE(d.ghost_version_offrow, 0)
            , x.insert_over_ghost_version_inrow    = COALESCE(d.insert_over_ghost_version_inrow, 0)
            , x.insert_over_ghost_version_offrow   = COALESCE(d.insert_over_ghost_version_offrow, 0)
        FROM dbo._dm_db_index_operational_stats x
            JOIN #Dataset d ON d._IndexID = x._IndexID AND d._BoundaryValue = x._BoundaryValue
        WHERE x._DatabaseID = @DatabaseID;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._dm_db_index_operational_stats (_DatabaseID, _ObjectID, _IndexID, _BoundaryValue
            , EstimatedStatsBeginTime, StatsEndTime
            , database_id, [object_id], index_id, partition_number, hobt_id, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count, leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count, page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow)
        SELECT @DatabaseID, d._ObjectID, d._IndexID, d._BoundaryValue
            , d.EstimatedStatsBeginTime, d.StatsEndTime
            , d.database_id, d.[object_id], d.index_id, d.partition_number, d.hobt_id
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
        FROM #Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._dm_db_index_operational_stats x
                WHERE x._DatabaseID = @DatabaseID
                    AND x._IndexID  = d._IndexID
                    AND x._BoundaryValue = d._BoundaryValue
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
CREATE PROCEDURE dw.usp_import__dm_db_index_operational_stats_delta (
    @DatabaseID int,
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

    DECLARE @tableName nvarchar(128) = N'dw._dm_db_index_operational_stats_delta';

    IF (OBJECT_ID('tempdb..#Dataset') IS NULL)
    BEGIN;
        SELECT x = 1 INTO #Dataset;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Delete
    ------------------------------------------------------------------------------
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE s
        FROM dw._dm_db_index_operational_stats_delta s
        WHERE s._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = s._DatabaseID AND d._IndexID = s._IndexID AND d._BoundaryValue = s._BoundaryValue);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Update
    ------------------------------------------------------------------------------
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        -- Calcualted fields are being handled here because the destination table is a clustered columnstore index, which currently do not support computed columns
        UPDATE t
        SET   t.partition_number        = s.partition_number
            --
            , t.EstimatedStatsBeginTime = y.EstimatedStatsBeginTime
            , t.StatsEndTime            = s.StatsEndTime
            , t.StatsAgeMS              = DATEDIFF_BIG(MILLISECOND, y.EstimatedStatsBeginTime, s.StatsEndTime)
            , t.WereStatsReset          = x.WereStatsReset

            /* If the index's stats have been reset since the last time we took a snapshot, then the delta
                needs to be based on our best guess of when the stats we're reset, rather than the end of the
                previous stats snapshot. If it was reset, then we just want to take the whole stats value rather
                than getting the difference since the last snapshot. */
            , t.leaf_insert_count                  = s.leaf_insert_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_insert_count)
            , t.leaf_delete_count                  = s.leaf_delete_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_delete_count)
            , t.leaf_update_count                  = s.leaf_update_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_update_count)
            , t.leaf_ghost_count                   = s.leaf_ghost_count                   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_ghost_count)
            , t.nonleaf_insert_count               = s.nonleaf_insert_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_insert_count)
            , t.nonleaf_delete_count               = s.nonleaf_delete_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_delete_count)
            , t.nonleaf_update_count               = s.nonleaf_update_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_update_count)
            , t.leaf_allocation_count              = s.leaf_allocation_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_allocation_count)
            , t.nonleaf_allocation_count           = s.nonleaf_allocation_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_allocation_count)
            , t.leaf_page_merge_count              = s.leaf_page_merge_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_page_merge_count)
            , t.nonleaf_page_merge_count           = s.nonleaf_page_merge_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_page_merge_count)
            , t.range_scan_count                   = s.range_scan_count                   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.range_scan_count)
            , t.singleton_lookup_count             = s.singleton_lookup_count             - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.singleton_lookup_count)
            , t.forwarded_fetch_count              = s.forwarded_fetch_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.forwarded_fetch_count)
            , t.lob_fetch_in_pages                 = s.lob_fetch_in_pages                 - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_fetch_in_pages)
            , t.lob_fetch_in_bytes                 = s.lob_fetch_in_bytes                 - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_fetch_in_bytes)
            , t.lob_orphan_create_count            = s.lob_orphan_create_count            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_orphan_create_count)
            , t.lob_orphan_insert_count            = s.lob_orphan_insert_count            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_orphan_insert_count)
            , t.row_overflow_fetch_in_pages        = s.row_overflow_fetch_in_pages        - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_overflow_fetch_in_pages)
            , t.row_overflow_fetch_in_bytes        = s.row_overflow_fetch_in_bytes        - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_overflow_fetch_in_bytes)
            , t.column_value_push_off_row_count    = s.column_value_push_off_row_count    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.column_value_push_off_row_count)
            , t.column_value_pull_in_row_count     = s.column_value_pull_in_row_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.column_value_pull_in_row_count)
            , t.row_lock_count                     = s.row_lock_count                     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_count)
            , t.row_lock_wait_count                = s.row_lock_wait_count                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_wait_count)
            , t.row_lock_wait_in_ms                = s.row_lock_wait_in_ms                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_wait_in_ms)
            , t.page_lock_count                    = s.page_lock_count                    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_count)
            , t.page_lock_wait_count               = s.page_lock_wait_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_wait_count)
            , t.page_lock_wait_in_ms               = s.page_lock_wait_in_ms               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_wait_in_ms)
            , t.index_lock_promotion_attempt_count = s.index_lock_promotion_attempt_count - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.index_lock_promotion_attempt_count)
            , t.index_lock_promotion_count         = s.index_lock_promotion_count         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.index_lock_promotion_count)
            , t.page_latch_wait_count              = s.page_latch_wait_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_latch_wait_count)
            , t.page_latch_wait_in_ms              = s.page_latch_wait_in_ms              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_latch_wait_in_ms)
            , t.page_io_latch_wait_count           = s.page_io_latch_wait_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_io_latch_wait_count)
            , t.page_io_latch_wait_in_ms           = s.page_io_latch_wait_in_ms           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_io_latch_wait_in_ms)
            , t.tree_page_latch_wait_count         = s.tree_page_latch_wait_count         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_latch_wait_count)
            , t.tree_page_latch_wait_in_ms         = s.tree_page_latch_wait_in_ms         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_latch_wait_in_ms)
            , t.tree_page_io_latch_wait_count      = s.tree_page_io_latch_wait_count      - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_io_latch_wait_count)
            , t.tree_page_io_latch_wait_in_ms      = s.tree_page_io_latch_wait_in_ms      - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_io_latch_wait_in_ms)
            , t.page_compression_attempt_count     = s.page_compression_attempt_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_compression_attempt_count)
            , t.page_compression_success_count     = s.page_compression_success_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_compression_success_count)
            , t.version_generated_inrow            = s.version_generated_inrow            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.version_generated_inrow)
            , t.version_generated_offrow           = s.version_generated_offrow           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.version_generated_offrow)
            , t.ghost_version_inrow                = s.ghost_version_inrow                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.ghost_version_inrow)
            , t.ghost_version_offrow               = s.ghost_version_offrow               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.ghost_version_offrow)
            , t.insert_over_ghost_version_inrow    = s.insert_over_ghost_version_inrow    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.insert_over_ghost_version_inrow)
            , t.insert_over_ghost_version_offrow   = s.insert_over_ghost_version_offrow   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.insert_over_ghost_version_offrow)
        FROM dw._dm_db_index_operational_stats_delta t -- Previous snapshot
            JOIN #Dataset s ON s._DatabaseID = t._DatabaseID AND s._IndexID = t._IndexID AND s._BoundaryValue = t._BoundaryValue
            CROSS APPLY (
                SELECT
                    /*  If the new EstimatedStatsBeginTime is higher than the last snapshot time (StatsEndTime), then we know something was reset.
                        e.g. SQL Server was restarted, database restored, table dropped and recreated, index dropped and recreated, etc.
                        Unfortunately, this isn't a perfect solution. There may be other reasons for a stats record to be reset that we are not detecting. */
                        WereStatsReset    = CONVERT(bit, IIF(s.EstimatedStatsBeginTime > t.StatsEndTime, 1, 0))
                    /*  If the new value is lower than the previous value for counter based stats, then we know it has been reset.
                        This is a safety measure to prevent negative values from being produced due to undetected counter resets. 
                            
                        Just like the other reset detection logic, this is just a best attempt. It's still possible for values to be higher and still
                        be a reset especially when the values are typically on the low end. By using multiple fields that tend to be the most active,
                        this can potentially help reduce any false positives on reset detection. */
                    ,  WereIdxStatsReset = CONVERT(bit, CASE
                                                            WHEN   s.leaf_insert_count        < t.leaf_insert_count
                                                                OR s.leaf_delete_count        < t.leaf_delete_count
                                                                OR s.leaf_update_count        < t.leaf_update_count
                                                                OR s.range_scan_count         < t.range_scan_count
                                                                OR s.singleton_lookup_count   < t.singleton_lookup_count
                                                                OR s.row_lock_count           < t.row_lock_count
                                                                OR s.page_lock_count          < t.page_lock_count
                                                                OR s.page_io_latch_wait_count < t.page_io_latch_wait_count
                                                            THEN 1
                                                            ELSE 0
                                                        END)
            ) x
            /* If it appears that the stats were not reset, then we want to use the StatsEndTime value from the previous snapshot */
            CROSS APPLY (SELECT EstimatedStatsBeginTime = IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, s.EstimatedStatsBeginTime, t.StatsEndTime)) y
        WHERE s.StatsEndTime > t.StatsEndTime;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Insert
    ------------------------------------------------------------------------------
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dw._dm_db_index_operational_stats_delta (_DatabaseID, _IndexID, _BoundaryValue, partition_number, EstimatedStatsBeginTime, StatsEndTime, StatsAgeMS, WereStatsReset, singleton_lookup_count, range_scan_count, forwarded_fetch_count, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_allocation_count, leaf_page_merge_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, nonleaf_allocation_count, nonleaf_page_merge_count, lob_fetch_in_bytes, lob_fetch_in_pages, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_bytes, row_overflow_fetch_in_pages, ghost_version_inrow, ghost_version_offrow, version_generated_inrow, version_generated_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow, column_value_pull_in_row_count, column_value_push_off_row_count, page_compression_attempt_count, page_compression_success_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms)
        SELECT s._DatabaseID, s._IndexID, s._BoundaryValue, s.partition_number, s.EstimatedStatsBeginTime, s.StatsEndTime, DATEDIFF_BIG(MILLISECOND, s.EstimatedStatsBeginTime, s.StatsEndTime), 0, s.singleton_lookup_count, s.range_scan_count, s.forwarded_fetch_count, s.leaf_insert_count, s.leaf_delete_count, s.leaf_update_count, s.leaf_allocation_count, s.leaf_page_merge_count, s.leaf_ghost_count, s.nonleaf_insert_count, s.nonleaf_delete_count, s.nonleaf_update_count, s.nonleaf_allocation_count, s.nonleaf_page_merge_count, s.lob_fetch_in_bytes, s.lob_fetch_in_pages, s.lob_orphan_create_count, s.lob_orphan_insert_count, s.row_overflow_fetch_in_bytes, s.row_overflow_fetch_in_pages, s.ghost_version_inrow, s.ghost_version_offrow, s.version_generated_inrow, s.version_generated_offrow, s.insert_over_ghost_version_inrow, s.insert_over_ghost_version_offrow, s.column_value_pull_in_row_count, s.column_value_push_off_row_count, s.page_compression_attempt_count, s.page_compression_success_count, s.row_lock_count, s.row_lock_wait_count, s.row_lock_wait_in_ms, s.page_lock_count, s.page_lock_wait_count, s.page_lock_wait_in_ms, s.index_lock_promotion_attempt_count, s.index_lock_promotion_count, s.page_latch_wait_count, s.page_latch_wait_in_ms, s.page_io_latch_wait_count, s.page_io_latch_wait_in_ms, s.tree_page_latch_wait_count, s.tree_page_latch_wait_in_ms, s.tree_page_io_latch_wait_count, s.tree_page_io_latch_wait_in_ms
        FROM #Dataset s
        WHERE NOT EXISTS (SELECT * FROM dw._dm_db_index_operational_stats_delta t WHERE t._DatabaseID = s._DatabaseID AND t._IndexID = s._IndexID AND t._BoundaryValue = s._BoundaryValue);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
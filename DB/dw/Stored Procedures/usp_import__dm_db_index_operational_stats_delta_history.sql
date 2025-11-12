CREATE PROCEDURE dw.usp_import__dm_db_index_operational_stats_delta_history (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_operational_stats READONLY,
    @ItemName   import.ItemName READONLY,
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
    -- Insert stats deltas
    ------------------------------------------------------------------------------
        INSERT dw._dm_db_index_operational_stats_delta_history (
              _DatabaseID, _ObjectID, _IndexID, _BoundaryValue
            , EstimatedStatsBeginTime, StatsEndTime
            , StatsAgeMS
            , WereStatsReset
            , leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, leaf_allocation_count, nonleaf_allocation_count
            , leaf_page_merge_count, nonleaf_page_merge_count, range_scan_count, singleton_lookup_count, forwarded_fetch_count, lob_fetch_in_pages, lob_fetch_in_bytes, lob_orphan_create_count
            , lob_orphan_insert_count, row_overflow_fetch_in_pages, row_overflow_fetch_in_bytes, column_value_push_off_row_count, column_value_pull_in_row_count, row_lock_count, row_lock_wait_count
            , row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms
            , page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms, page_compression_attempt_count
            , page_compression_success_count, version_generated_inrow, version_generated_offrow, ghost_version_inrow, ghost_version_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow
        )
        -- Calcualted fields are being handled here because the destination table is a clustered columnstore index, which currently do not support computed columns
        SELECT @DatabaseID, x._ObjectID, x._IndexID, x._BoundaryValue
            , x.EstimatedStatsBeginTime, x.StatsEndTime
            , StatsAgeMS = DATEDIFF(MILLISECOND, x.EstimatedStatsBeginTime, x.StatsEndTime)
            , x.WereStatsReset
            , x.leaf_insert_count, x.leaf_delete_count, x.leaf_update_count, x.leaf_ghost_count, x.nonleaf_insert_count, x.nonleaf_delete_count, x.nonleaf_update_count, x.leaf_allocation_count, x.nonleaf_allocation_count
            , x.leaf_page_merge_count, x.nonleaf_page_merge_count, x.range_scan_count, x.singleton_lookup_count, x.forwarded_fetch_count, x.lob_fetch_in_pages, x.lob_fetch_in_bytes, x.lob_orphan_create_count
            , x.lob_orphan_insert_count, x.row_overflow_fetch_in_pages, x.row_overflow_fetch_in_bytes, x.column_value_push_off_row_count, x.column_value_pull_in_row_count, x.row_lock_count, x.row_lock_wait_count
            , x.row_lock_wait_in_ms, x.page_lock_count, x.page_lock_wait_count, x.page_lock_wait_in_ms, x.index_lock_promotion_attempt_count, x.index_lock_promotion_count, x.page_latch_wait_count, x.page_latch_wait_in_ms
            , x.page_io_latch_wait_count, x.page_io_latch_wait_in_ms, x.tree_page_latch_wait_count, x.tree_page_latch_wait_in_ms, x.tree_page_io_latch_wait_count, x.tree_page_io_latch_wait_in_ms, x.page_compression_attempt_count
            , x.page_compression_success_count, x.version_generated_inrow, x.version_generated_offrow, x.ghost_version_inrow, x.ghost_version_offrow, x.insert_over_ghost_version_inrow, x.insert_over_ghost_version_offrow
        FROM (
            SELECT i._ObjectID, i._IndexID, s._BoundaryValue
                , EstimatedStatsBeginTime = y.EstimatedStatsBeginTime
                , StatsEndTime            = s.StatsEndTime
                , WereStatsReset          = x.WereStatsReset

                /* If the index's stats have been reset since the last time we took a snapshot, then the delta
                    needs to be based on our best guess of when the stats we're reset, rather than the end of the
                    previous stats snapshot. If it was reset, then we just want to take the whole stats value rather
                    than getting the difference since the last snapshot. */
                , leaf_insert_count                  = s.leaf_insert_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_insert_count)
                , leaf_delete_count                  = s.leaf_delete_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_delete_count)
                , leaf_update_count                  = s.leaf_update_count                  - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_update_count)
                , leaf_ghost_count                   = s.leaf_ghost_count                   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_ghost_count)
                , nonleaf_insert_count               = s.nonleaf_insert_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_insert_count)
                , nonleaf_delete_count               = s.nonleaf_delete_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_delete_count)
                , nonleaf_update_count               = s.nonleaf_update_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_update_count)
                , leaf_allocation_count              = s.leaf_allocation_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_allocation_count)
                , nonleaf_allocation_count           = s.nonleaf_allocation_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_allocation_count)
                , leaf_page_merge_count              = s.leaf_page_merge_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.leaf_page_merge_count)
                , nonleaf_page_merge_count           = s.nonleaf_page_merge_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.nonleaf_page_merge_count)
                , range_scan_count                   = s.range_scan_count                   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.range_scan_count)
                , singleton_lookup_count             = s.singleton_lookup_count             - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.singleton_lookup_count)
                , forwarded_fetch_count              = s.forwarded_fetch_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.forwarded_fetch_count)
                , lob_fetch_in_pages                 = s.lob_fetch_in_pages                 - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_fetch_in_pages)
                , lob_fetch_in_bytes                 = s.lob_fetch_in_bytes                 - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_fetch_in_bytes)
                , lob_orphan_create_count            = s.lob_orphan_create_count            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_orphan_create_count)
                , lob_orphan_insert_count            = s.lob_orphan_insert_count            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.lob_orphan_insert_count)
                , row_overflow_fetch_in_pages        = s.row_overflow_fetch_in_pages        - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_overflow_fetch_in_pages)
                , row_overflow_fetch_in_bytes        = s.row_overflow_fetch_in_bytes        - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_overflow_fetch_in_bytes)
                , column_value_push_off_row_count    = s.column_value_push_off_row_count    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.column_value_push_off_row_count)
                , column_value_pull_in_row_count     = s.column_value_pull_in_row_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.column_value_pull_in_row_count)
                , row_lock_count                     = s.row_lock_count                     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_count)
                , row_lock_wait_count                = s.row_lock_wait_count                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_wait_count)
                , row_lock_wait_in_ms                = s.row_lock_wait_in_ms                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.row_lock_wait_in_ms)
                , page_lock_count                    = s.page_lock_count                    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_count)
                , page_lock_wait_count               = s.page_lock_wait_count               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_wait_count)
                , page_lock_wait_in_ms               = s.page_lock_wait_in_ms               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_lock_wait_in_ms)
                , index_lock_promotion_attempt_count = s.index_lock_promotion_attempt_count - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.index_lock_promotion_attempt_count)
                , index_lock_promotion_count         = s.index_lock_promotion_count         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.index_lock_promotion_count)
                , page_latch_wait_count              = s.page_latch_wait_count              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_latch_wait_count)
                , page_latch_wait_in_ms              = s.page_latch_wait_in_ms              - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_latch_wait_in_ms)
                , page_io_latch_wait_count           = s.page_io_latch_wait_count           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_io_latch_wait_count)
                , page_io_latch_wait_in_ms           = s.page_io_latch_wait_in_ms           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_io_latch_wait_in_ms)
                , tree_page_latch_wait_count         = s.tree_page_latch_wait_count         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_latch_wait_count)
                , tree_page_latch_wait_in_ms         = s.tree_page_latch_wait_in_ms         - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_latch_wait_in_ms)
                , tree_page_io_latch_wait_count      = s.tree_page_io_latch_wait_count      - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_io_latch_wait_count)
                , tree_page_io_latch_wait_in_ms      = s.tree_page_io_latch_wait_in_ms      - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.tree_page_io_latch_wait_in_ms)
                , page_compression_attempt_count     = s.page_compression_attempt_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_compression_attempt_count)
                , page_compression_success_count     = s.page_compression_success_count     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.page_compression_success_count)
                , version_generated_inrow            = s.version_generated_inrow            - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.version_generated_inrow)
                , version_generated_offrow           = s.version_generated_offrow           - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.version_generated_offrow)
                , ghost_version_inrow                = s.ghost_version_inrow                - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.ghost_version_inrow)
                , ghost_version_offrow               = s.ghost_version_offrow               - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.ghost_version_offrow)
                , insert_over_ghost_version_inrow    = s.insert_over_ghost_version_inrow    - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.insert_over_ghost_version_inrow)
                , insert_over_ghost_version_offrow   = s.insert_over_ghost_version_offrow   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.insert_over_ghost_version_offrow)
            FROM dbo._dm_db_index_operational_stats t -- Previous snapshot
                JOIN (@ItemName i
                    JOIN @Dataset s ON s.__ID = i.ID -- New snapshot
                ) ON i._IndexID = t._IndexID AND (s._BoundaryValue = t._BoundaryValue OR (s._BoundaryValue IS NULL AND t._BoundaryValue IS NULL))
                CROSS APPLY (
                    SELECT
                        /*  If the new EstimatedStatsBeginTime is higher than the last snapshot time (StatsEndTime), then we know something was reset.
                            e.g. SQL Server was restarted, database restored, table dropped and recreated, index dropped and recreated, etc.
                            Unfortunately, this isn't a perfect solution. There may be other reasons for a stats record to be reset that we are not detecting. */
                           WereStatsReset    = CONVERT(bit, IIF(s.EstimatedStatsBeginTime > t.StatsEndTime, 1, 0))
                        /*  If the new value is lower than the previous value for counter based stats, then we know it has been reset.
                            This is a safety measure to prevent negative values from being produced due to undetected counter resets. */
                        ,  WereIdxStatsReset = CONVERT(bit, CASE
                                                                WHEN s.leaf_insert_count        < t.leaf_insert_count
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
            WHERE t._DatabaseID = @DatabaseID
                AND s.StatsEndTime > t.StatsEndTime
        ) x;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
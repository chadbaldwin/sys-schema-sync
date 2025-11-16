CREATE PROCEDURE dw.usp_import__dm_db_index_operational_stats_delta (
    @DatabaseID int
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;

    -- This is just for SSDT to stop complaining about the missing temp table
    IF (OBJECT_ID('tempdb..#Dataset') IS NULL) BEGIN; CREATE TABLE #Dataset (x int NOT NULL) END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dw._dm_db_index_operational_stats_delta';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE s FROM dw._dm_db_index_operational_stats_delta s
        WHERE s._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = s._DatabaseID AND d._IndexID = s._IndexID AND d._BoundaryValue = s._BoundaryValue);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
        -- Calcualted fields are being handled here because the destination table is a clustered columnstore index, which currently do not support computed columns
        UPDATE t
        SET t.partition_number                   = n.partition_number
          , t.EstimatedStatsBeginTime            = y.EstimatedStatsBeginTime
          , t.StatsEndTime                       = n.StatsEndTime
          , t.StatsAgeMS                         = DATEDIFF_BIG(MILLISECOND, y.EstimatedStatsBeginTime, n.StatsEndTime)
          , t.WereStatsReset                     = x.WereStatsReset
          /* If the index's stats have been reset since the last time we took a snapshot, then the delta
              needs to be based on our best guess of when the stats we're reset, rather than the end of the
              previous stats snapshot. If it was reset, then we just want to take the whole stats value rather
              than getting the difference since the last snapshot. */
          , t.leaf_insert_count                  = n.leaf_insert_count                  - IIF(x.WereStatsReset = 1, 0, p.leaf_insert_count)
          , t.leaf_delete_count                  = n.leaf_delete_count                  - IIF(x.WereStatsReset = 1, 0, p.leaf_delete_count)
          , t.leaf_update_count                  = n.leaf_update_count                  - IIF(x.WereStatsReset = 1, 0, p.leaf_update_count)
          , t.leaf_ghost_count                   = n.leaf_ghost_count                   - IIF(x.WereStatsReset = 1, 0, p.leaf_ghost_count)
          , t.nonleaf_insert_count               = n.nonleaf_insert_count               - IIF(x.WereStatsReset = 1, 0, p.nonleaf_insert_count)
          , t.nonleaf_delete_count               = n.nonleaf_delete_count               - IIF(x.WereStatsReset = 1, 0, p.nonleaf_delete_count)
          , t.nonleaf_update_count               = n.nonleaf_update_count               - IIF(x.WereStatsReset = 1, 0, p.nonleaf_update_count)
          , t.leaf_allocation_count              = n.leaf_allocation_count              - IIF(x.WereStatsReset = 1, 0, p.leaf_allocation_count)
          , t.nonleaf_allocation_count           = n.nonleaf_allocation_count           - IIF(x.WereStatsReset = 1, 0, p.nonleaf_allocation_count)
          , t.leaf_page_merge_count              = n.leaf_page_merge_count              - IIF(x.WereStatsReset = 1, 0, p.leaf_page_merge_count)
          , t.nonleaf_page_merge_count           = n.nonleaf_page_merge_count           - IIF(x.WereStatsReset = 1, 0, p.nonleaf_page_merge_count)
          , t.range_scan_count                   = n.range_scan_count                   - IIF(x.WereStatsReset = 1, 0, p.range_scan_count)
          , t.singleton_lookup_count             = n.singleton_lookup_count             - IIF(x.WereStatsReset = 1, 0, p.singleton_lookup_count)
          , t.forwarded_fetch_count              = n.forwarded_fetch_count              - IIF(x.WereStatsReset = 1, 0, p.forwarded_fetch_count)
          , t.lob_fetch_in_pages                 = n.lob_fetch_in_pages                 - IIF(x.WereStatsReset = 1, 0, p.lob_fetch_in_pages)
          , t.lob_fetch_in_bytes                 = n.lob_fetch_in_bytes                 - IIF(x.WereStatsReset = 1, 0, p.lob_fetch_in_bytes)
          , t.lob_orphan_create_count            = n.lob_orphan_create_count            - IIF(x.WereStatsReset = 1, 0, p.lob_orphan_create_count)
          , t.lob_orphan_insert_count            = n.lob_orphan_insert_count            - IIF(x.WereStatsReset = 1, 0, p.lob_orphan_insert_count)
          , t.row_overflow_fetch_in_pages        = n.row_overflow_fetch_in_pages        - IIF(x.WereStatsReset = 1, 0, p.row_overflow_fetch_in_pages)
          , t.row_overflow_fetch_in_bytes        = n.row_overflow_fetch_in_bytes        - IIF(x.WereStatsReset = 1, 0, p.row_overflow_fetch_in_bytes)
          , t.column_value_push_off_row_count    = n.column_value_push_off_row_count    - IIF(x.WereStatsReset = 1, 0, p.column_value_push_off_row_count)
          , t.column_value_pull_in_row_count     = n.column_value_pull_in_row_count     - IIF(x.WereStatsReset = 1, 0, p.column_value_pull_in_row_count)
          , t.row_lock_count                     = n.row_lock_count                     - IIF(x.WereStatsReset = 1, 0, p.row_lock_count)
          , t.row_lock_wait_count                = n.row_lock_wait_count                - IIF(x.WereStatsReset = 1, 0, p.row_lock_wait_count)
          , t.row_lock_wait_in_ms                = n.row_lock_wait_in_ms                - IIF(x.WereStatsReset = 1, 0, p.row_lock_wait_in_ms)
          , t.page_lock_count                    = n.page_lock_count                    - IIF(x.WereStatsReset = 1, 0, p.page_lock_count)
          , t.page_lock_wait_count               = n.page_lock_wait_count               - IIF(x.WereStatsReset = 1, 0, p.page_lock_wait_count)
          , t.page_lock_wait_in_ms               = n.page_lock_wait_in_ms               - IIF(x.WereStatsReset = 1, 0, p.page_lock_wait_in_ms)
          , t.index_lock_promotion_attempt_count = n.index_lock_promotion_attempt_count - IIF(x.WereStatsReset = 1, 0, p.index_lock_promotion_attempt_count)
          , t.index_lock_promotion_count         = n.index_lock_promotion_count         - IIF(x.WereStatsReset = 1, 0, p.index_lock_promotion_count)
          , t.page_latch_wait_count              = n.page_latch_wait_count              - IIF(x.WereStatsReset = 1, 0, p.page_latch_wait_count)
          , t.page_latch_wait_in_ms              = n.page_latch_wait_in_ms              - IIF(x.WereStatsReset = 1, 0, p.page_latch_wait_in_ms)
          , t.page_io_latch_wait_count           = n.page_io_latch_wait_count           - IIF(x.WereStatsReset = 1, 0, p.page_io_latch_wait_count)
          , t.page_io_latch_wait_in_ms           = n.page_io_latch_wait_in_ms           - IIF(x.WereStatsReset = 1, 0, p.page_io_latch_wait_in_ms)
          , t.tree_page_latch_wait_count         = n.tree_page_latch_wait_count         - IIF(x.WereStatsReset = 1, 0, p.tree_page_latch_wait_count)
          , t.tree_page_latch_wait_in_ms         = n.tree_page_latch_wait_in_ms         - IIF(x.WereStatsReset = 1, 0, p.tree_page_latch_wait_in_ms)
          , t.tree_page_io_latch_wait_count      = n.tree_page_io_latch_wait_count      - IIF(x.WereStatsReset = 1, 0, p.tree_page_io_latch_wait_count)
          , t.tree_page_io_latch_wait_in_ms      = n.tree_page_io_latch_wait_in_ms      - IIF(x.WereStatsReset = 1, 0, p.tree_page_io_latch_wait_in_ms)
          , t.page_compression_attempt_count     = n.page_compression_attempt_count     - IIF(x.WereStatsReset = 1, 0, p.page_compression_attempt_count)
          , t.page_compression_success_count     = n.page_compression_success_count     - IIF(x.WereStatsReset = 1, 0, p.page_compression_success_count)
          , t.version_generated_inrow            = n.version_generated_inrow            - IIF(x.WereStatsReset = 1, 0, p.version_generated_inrow)
          , t.version_generated_offrow           = n.version_generated_offrow           - IIF(x.WereStatsReset = 1, 0, p.version_generated_offrow)
          , t.ghost_version_inrow                = n.ghost_version_inrow                - IIF(x.WereStatsReset = 1, 0, p.ghost_version_inrow)
          , t.ghost_version_offrow               = n.ghost_version_offrow               - IIF(x.WereStatsReset = 1, 0, p.ghost_version_offrow)
          , t.insert_over_ghost_version_inrow    = n.insert_over_ghost_version_inrow    - IIF(x.WereStatsReset = 1, 0, p.insert_over_ghost_version_inrow)
          , t.insert_over_ghost_version_offrow   = n.insert_over_ghost_version_offrow   - IIF(x.WereStatsReset = 1, 0, p.insert_over_ghost_version_offrow)
        FROM dw._dm_db_index_operational_stats_delta t -- Delta table
            JOIN dbo._dm_db_index_operational_stats p ON p._DatabaseID = t._DatabaseID AND p._IndexID = t._IndexID AND p._BoundaryValue = t._BoundaryValue -- Previous snapshot
            JOIN #Dataset n ON n._DatabaseID = t._DatabaseID AND n._IndexID = t._IndexID AND n._BoundaryValue = t._BoundaryValue -- New snapshot
            CROSS APPLY (
                SELECT WereStatsReset = CASE
                                            /*  If the new EstimatedStatsBeginTime is higher than the last snapshot time (StatsEndTime), then we know something was reset.
                                                e.g. SQL Server was restarted, database restored, table dropped and recreated, index dropped and recreated, etc.
                                                Unfortunately, this isn't a perfect solution. There may be other reasons for a stats record to be reset that we are not detecting. */
                                            WHEN n.EstimatedStatsBeginTime > p.StatsEndTime
                                            THEN 1
                                            /*  If the new value is lower than the previous value for counter based stats, then we know it has been reset.
                                                This is a safety measure to prevent negative values from being produced due to undetected counter resets. 

                                                Just like the other reset detection logic, this is just a best attempt. It's still possible for values to be higher and still
                                                be a reset especially when the values are typically on the low end. By using multiple fields that tend to be the most active,
                                                this can potentially help reduce any false positives on reset detection. */
                                            WHEN   n.leaf_insert_count        < p.leaf_insert_count
                                                OR n.leaf_delete_count        < p.leaf_delete_count
                                                OR n.leaf_update_count        < p.leaf_update_count
                                                OR n.range_scan_count         < p.range_scan_count
                                                OR n.singleton_lookup_count   < p.singleton_lookup_count
                                                OR n.row_lock_count           < p.row_lock_count
                                                OR n.page_lock_count          < p.page_lock_count
                                                OR n.page_io_latch_wait_count < p.page_io_latch_wait_count
                                            THEN 1
                                            ELSE 0
                                        END
            ) x
            /* If it appears that the stats were not reset, then we want to use the StatsEndTime value from the previous snapshot */
            CROSS APPLY (SELECT EstimatedStatsBeginTime = IIF(x.WereStatsReset = 1, n.EstimatedStatsBeginTime, p.StatsEndTime)) y
        WHERE n.StatsEndTime > p.StatsEndTime;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dw._dm_db_index_operational_stats_delta (_DatabaseID, _IndexID, _BoundaryValue, partition_number, EstimatedStatsBeginTime, StatsEndTime, StatsAgeMS, WereStatsReset, singleton_lookup_count, range_scan_count, forwarded_fetch_count, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_allocation_count, leaf_page_merge_count, leaf_ghost_count, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count, nonleaf_allocation_count, nonleaf_page_merge_count, lob_fetch_in_bytes, lob_fetch_in_pages, lob_orphan_create_count, lob_orphan_insert_count, row_overflow_fetch_in_bytes, row_overflow_fetch_in_pages, ghost_version_inrow, ghost_version_offrow, version_generated_inrow, version_generated_offrow, insert_over_ghost_version_inrow, insert_over_ghost_version_offrow, column_value_pull_in_row_count, column_value_push_off_row_count, page_compression_attempt_count, page_compression_success_count, row_lock_count, row_lock_wait_count, row_lock_wait_in_ms, page_lock_count, page_lock_wait_count, page_lock_wait_in_ms, index_lock_promotion_attempt_count, index_lock_promotion_count, page_latch_wait_count, page_latch_wait_in_ms, page_io_latch_wait_count, page_io_latch_wait_in_ms, tree_page_latch_wait_count, tree_page_latch_wait_in_ms, tree_page_io_latch_wait_count, tree_page_io_latch_wait_in_ms)
        SELECT s._DatabaseID, s._IndexID, s._BoundaryValue, s.partition_number, s.EstimatedStatsBeginTime, s.StatsEndTime, DATEDIFF_BIG(MILLISECOND, s.EstimatedStatsBeginTime, s.StatsEndTime), 0, s.singleton_lookup_count, s.range_scan_count, s.forwarded_fetch_count, s.leaf_insert_count, s.leaf_delete_count, s.leaf_update_count, s.leaf_allocation_count, s.leaf_page_merge_count, s.leaf_ghost_count, s.nonleaf_insert_count, s.nonleaf_delete_count, s.nonleaf_update_count, s.nonleaf_allocation_count, s.nonleaf_page_merge_count, s.lob_fetch_in_bytes, s.lob_fetch_in_pages, s.lob_orphan_create_count, s.lob_orphan_insert_count, s.row_overflow_fetch_in_bytes, s.row_overflow_fetch_in_pages, s.ghost_version_inrow, s.ghost_version_offrow, s.version_generated_inrow, s.version_generated_offrow, s.insert_over_ghost_version_inrow, s.insert_over_ghost_version_offrow, s.column_value_pull_in_row_count, s.column_value_push_off_row_count, s.page_compression_attempt_count, s.page_compression_success_count, s.row_lock_count, s.row_lock_wait_count, s.row_lock_wait_in_ms, s.page_lock_count, s.page_lock_wait_count, s.page_lock_wait_in_ms, s.index_lock_promotion_attempt_count, s.index_lock_promotion_count, s.page_latch_wait_count, s.page_latch_wait_in_ms, s.page_io_latch_wait_count, s.page_io_latch_wait_in_ms, s.tree_page_latch_wait_count, s.tree_page_latch_wait_in_ms, s.tree_page_io_latch_wait_count, s.tree_page_io_latch_wait_in_ms
        FROM #Dataset s
        WHERE NOT EXISTS (SELECT * FROM dw._dm_db_index_operational_stats_delta t WHERE t._DatabaseID = s._DatabaseID AND t._IndexID = s._IndexID AND t._BoundaryValue = s._BoundaryValue);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
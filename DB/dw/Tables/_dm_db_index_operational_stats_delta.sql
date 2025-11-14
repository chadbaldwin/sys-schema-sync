CREATE TABLE dw._dm_db_index_operational_stats_delta (
    _DatabaseID                        int           NOT NULL CONSTRAINT FK__dm_db_index_operational_stats_delta__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_operational_stats_delta__DatabaseID,
    _IndexID                           bigint        NOT NULL CONSTRAINT FK__dm_db_index_operational_stats_delta__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_operational_stats_delta__IndexID,
    _BoundaryValue                     nvarchar(100) NOT NULL,
    partition_number                   int           NOT NULL,
    --
    EstimatedStatsBeginTime            datetime2     NOT NULL,
    StatsEndTime                       datetime2     NOT NULL,
    StatsAgeMS                         bigint        NOT NULL,
    WereStatsReset                     bit           NOT NULL,

    -- Since this is a custom table for history, changing the column order to use a more logical grouping made sense.

    -- Access
    singleton_lookup_count             bigint       NOT NULL,
    range_scan_count                   bigint       NOT NULL,
    forwarded_fetch_count              bigint       NOT NULL,

    -- Leaf
    leaf_insert_count                  bigint       NOT NULL,
    leaf_delete_count                  bigint       NOT NULL,
    leaf_update_count                  bigint       NOT NULL,
    leaf_allocation_count              bigint       NOT NULL,
    leaf_page_merge_count              bigint       NOT NULL,
    leaf_ghost_count                   bigint       NOT NULL,

    -- Non-leaf
    nonleaf_insert_count               bigint       NOT NULL,
    nonleaf_delete_count               bigint       NOT NULL,
    nonleaf_update_count               bigint       NOT NULL,
    nonleaf_allocation_count           bigint       NOT NULL,
    nonleaf_page_merge_count           bigint       NOT NULL,

    -- LOB / row-overflow
    lob_fetch_in_bytes                 bigint       NOT NULL,
    lob_fetch_in_pages                 bigint       NOT NULL,
    lob_orphan_create_count            bigint       NOT NULL,
    lob_orphan_insert_count            bigint       NOT NULL,
    row_overflow_fetch_in_bytes        bigint       NOT NULL,
    row_overflow_fetch_in_pages        bigint       NOT NULL,

    -- Versioning / ghosts
    ghost_version_inrow                bigint       NOT NULL,
    ghost_version_offrow               bigint       NOT NULL,
    version_generated_inrow            bigint       NOT NULL,
    version_generated_offrow           bigint       NOT NULL,
    insert_over_ghost_version_inrow    bigint       NOT NULL,
    insert_over_ghost_version_offrow   bigint       NOT NULL,
    column_value_pull_in_row_count     bigint       NOT NULL,
    column_value_push_off_row_count    bigint       NOT NULL,

    -- Compression
    page_compression_attempt_count     bigint       NOT NULL,
    page_compression_success_count     bigint       NOT NULL,

    -- Locks
    row_lock_count                     bigint       NOT NULL,
    row_lock_wait_count                bigint       NOT NULL,
    row_lock_wait_in_ms                bigint       NOT NULL,
    page_lock_count                    bigint       NOT NULL,
    page_lock_wait_count               bigint       NOT NULL,
    page_lock_wait_in_ms               bigint       NOT NULL,
    index_lock_promotion_attempt_count bigint       NOT NULL,
    index_lock_promotion_count         bigint       NOT NULL,

    -- Latches
    page_latch_wait_count              bigint       NOT NULL,
    page_latch_wait_in_ms              bigint       NOT NULL,
    page_io_latch_wait_count           bigint       NOT NULL,
    page_io_latch_wait_in_ms           bigint       NOT NULL,
    tree_page_latch_wait_count         bigint       NOT NULL,
    tree_page_latch_wait_in_ms         bigint       NOT NULL,
    tree_page_io_latch_wait_count      bigint       NOT NULL,
    tree_page_io_latch_wait_in_ms      bigint       NOT NULL,

    ValidFrom                          datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo                            datetime2(7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT CPK__dm_db_index_operational_stats_delta__DatabaseID__IndexID__BoundaryValue PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID, _BoundaryValue) WITH (DATA_COMPRESSION = PAGE),
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dw._dm_db_index_operational_stats_delta_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 180 DAYS));
GO

CREATE TABLE dw._dm_db_index_operational_stats_delta_history (
    _DatabaseID                        int           NOT NULL,
    _IndexID                           bigint        NOT NULL,
    _BoundaryValue                     nvarchar(100) NOT NULL,
    partition_number                   int           NOT NULL,
    --
    EstimatedStatsBeginTime            datetime2     NOT NULL,
    StatsEndTime                       datetime2     NOT NULL,
    StatsAgeMS                         bigint        NOT NULL,
    WereStatsReset                     bit           NOT NULL,

    -- Since this is a custom table for history, changing the column order to use a more logical grouping made sense.

    -- Access
    singleton_lookup_count             bigint       NOT NULL,
    range_scan_count                   bigint       NOT NULL,
    forwarded_fetch_count              bigint       NOT NULL,

    -- Leaf
    leaf_insert_count                  bigint       NOT NULL,
    leaf_delete_count                  bigint       NOT NULL,
    leaf_update_count                  bigint       NOT NULL,
    leaf_allocation_count              bigint       NOT NULL,
    leaf_page_merge_count              bigint       NOT NULL,
    leaf_ghost_count                   bigint       NOT NULL,

    -- Non-leaf
    nonleaf_insert_count               bigint       NOT NULL,
    nonleaf_delete_count               bigint       NOT NULL,
    nonleaf_update_count               bigint       NOT NULL,
    nonleaf_allocation_count           bigint       NOT NULL,
    nonleaf_page_merge_count           bigint       NOT NULL,

    -- LOB / row-overflow
    lob_fetch_in_bytes                 bigint       NOT NULL,
    lob_fetch_in_pages                 bigint       NOT NULL,
    lob_orphan_create_count            bigint       NOT NULL,
    lob_orphan_insert_count            bigint       NOT NULL,
    row_overflow_fetch_in_bytes        bigint       NOT NULL,
    row_overflow_fetch_in_pages        bigint       NOT NULL,

    -- Versioning / ghosts
    ghost_version_inrow                bigint       NOT NULL,
    ghost_version_offrow               bigint       NOT NULL,
    version_generated_inrow            bigint       NOT NULL,
    version_generated_offrow           bigint       NOT NULL,
    insert_over_ghost_version_inrow    bigint       NOT NULL,
    insert_over_ghost_version_offrow   bigint       NOT NULL,
    column_value_pull_in_row_count     bigint       NOT NULL,
    column_value_push_off_row_count    bigint       NOT NULL,

    -- Compression
    page_compression_attempt_count     bigint       NOT NULL,
    page_compression_success_count     bigint       NOT NULL,

    -- Locks
    row_lock_count                     bigint       NOT NULL,
    row_lock_wait_count                bigint       NOT NULL,
    row_lock_wait_in_ms                bigint       NOT NULL,
    page_lock_count                    bigint       NOT NULL,
    page_lock_wait_count               bigint       NOT NULL,
    page_lock_wait_in_ms               bigint       NOT NULL,
    index_lock_promotion_attempt_count bigint       NOT NULL,
    index_lock_promotion_count         bigint       NOT NULL,

    -- Latches
    page_latch_wait_count              bigint       NOT NULL,
    page_latch_wait_in_ms              bigint       NOT NULL,
    page_io_latch_wait_count           bigint       NOT NULL,
    page_io_latch_wait_in_ms           bigint       NOT NULL,
    tree_page_latch_wait_count         bigint       NOT NULL,
    tree_page_latch_wait_in_ms         bigint       NOT NULL,
    tree_page_io_latch_wait_count      bigint       NOT NULL,
    tree_page_io_latch_wait_in_ms      bigint       NOT NULL,

    ValidFrom                          datetime2(7) NOT NULL,
    ValidTo                            datetime2(7) NOT NULL,
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCSIX__dm_db_index_operational_stats_delta_history_ValidTo
    ON dw._dm_db_index_operational_stats_delta_history
    ORDER (ValidTo);
GO

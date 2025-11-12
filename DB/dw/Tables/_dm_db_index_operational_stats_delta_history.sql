CREATE TABLE dw._dm_db_index_operational_stats_delta_history (
    _DatabaseID                        int           NOT NULL CONSTRAINT FK__dm_db_index_operational_stats_delta_history__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_operational_stats_delta_history__DatabaseID,
    _ObjectID                          bigint        NOT NULL CONSTRAINT FK__dm_db_index_operational_stats_delta_history__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__dm_db_index_operational_stats_delta_history__ObjectID,
    _IndexID                           bigint        NOT NULL CONSTRAINT FK__dm_db_index_operational_stats_delta_history__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_operational_stats_delta_history__IndexID,
    _BoundaryValue                     nvarchar(100)     NULL,
    --
    EstimatedStatsBeginTime            datetime2     NOT NULL,
    StatsEndTime                       datetime2     NOT NULL,
    StatsAgeMS                         bigint        NOT NULL,
    WereStatsReset                     bit           NOT NULL,
    --
    leaf_insert_count                  bigint        NOT NULL,
    leaf_delete_count                  bigint        NOT NULL,
    leaf_update_count                  bigint        NOT NULL,
    leaf_ghost_count                   bigint        NOT NULL,
    nonleaf_insert_count               bigint        NOT NULL,
    nonleaf_delete_count               bigint        NOT NULL,
    nonleaf_update_count               bigint        NOT NULL,
    leaf_allocation_count              bigint        NOT NULL,
    nonleaf_allocation_count           bigint        NOT NULL,
    leaf_page_merge_count              bigint        NOT NULL,
    nonleaf_page_merge_count           bigint        NOT NULL,
    range_scan_count                   bigint        NOT NULL,
    singleton_lookup_count             bigint        NOT NULL,
    forwarded_fetch_count              bigint        NOT NULL,
    lob_fetch_in_pages                 bigint        NOT NULL,
    lob_fetch_in_bytes                 bigint        NOT NULL,
    lob_orphan_create_count            bigint        NOT NULL,
    lob_orphan_insert_count            bigint        NOT NULL,
    row_overflow_fetch_in_pages        bigint        NOT NULL,
    row_overflow_fetch_in_bytes        bigint        NOT NULL,
    column_value_push_off_row_count    bigint        NOT NULL,
    column_value_pull_in_row_count     bigint        NOT NULL,
    row_lock_count                     bigint        NOT NULL,
    row_lock_wait_count                bigint        NOT NULL,
    row_lock_wait_in_ms                bigint        NOT NULL,
    page_lock_count                    bigint        NOT NULL,
    page_lock_wait_count               bigint        NOT NULL,
    page_lock_wait_in_ms               bigint        NOT NULL,
    index_lock_promotion_attempt_count bigint        NOT NULL,
    index_lock_promotion_count         bigint        NOT NULL,
    page_latch_wait_count              bigint        NOT NULL,
    page_latch_wait_in_ms              bigint        NOT NULL,
    page_io_latch_wait_count           bigint        NOT NULL,
    page_io_latch_wait_in_ms           bigint        NOT NULL,
    tree_page_latch_wait_count         bigint        NOT NULL,
    tree_page_latch_wait_in_ms         bigint        NOT NULL,
    tree_page_io_latch_wait_count      bigint        NOT NULL,
    tree_page_io_latch_wait_in_ms      bigint        NOT NULL,
    page_compression_attempt_count     bigint        NOT NULL,
    page_compression_success_count     bigint        NOT NULL,
    version_generated_inrow            bigint        NOT NULL, -- Added in SQL Server 2019
    version_generated_offrow           bigint        NOT NULL, -- Added in SQL Server 2019
    ghost_version_inrow                bigint        NOT NULL, -- Added in SQL Server 2019
    ghost_version_offrow               bigint        NOT NULL, -- Added in SQL Server 2019
    insert_over_ghost_version_inrow    bigint        NOT NULL, -- Added in SQL Server 2019
    insert_over_ghost_version_offrow   bigint        NOT NULL, -- Added in SQL Server 2019

    CONSTRAINT UQ__dm_db_index_operational_stats_delta_history_StatsEndTime__DatabaseID__IndexID__BoundaryValue UNIQUE (StatsEndTime, _DatabaseID, _IndexID, _BoundaryValue),
    INDEX IX__dm_db_index_operational_stats_delta_history__DatabaseID__IndexID__BoundaryValue (_DatabaseID, _IndexID, _BoundaryValue)
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCSIX__dm_db_index_operational_stats_delta_history_StatsEndTime__DatabaseID__IndexID__BoundaryValue
    ON dw._dm_db_index_operational_stats_delta_history
    ORDER (StatsEndTime, _DatabaseID, _IndexID, _BoundaryValue);

GO
CREATE TABLE dbo._dm_db_index_operational_stats (
    _DatabaseID                        int           NOT NULL CONSTRAINT FK__dm_db_index_operational_stats__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_operational_stats__DatabaseID,
    _ObjectID                          bigint        NOT NULL CONSTRAINT FK__dm_db_index_operational_stats__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__dm_db_index_operational_stats__ObjectID,
    _IndexID                           bigint        NOT NULL CONSTRAINT FK__dm_db_index_operational_stats__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_operational_stats__IndexID,
    _BoundaryValue                     nvarchar(100)     NULL,
    --
    EstimatedStatsBeginTime            datetime2(7)  NOT NULL,
    StatsEndTime                       datetime2(7)  NOT NULL,
    --
    database_id                        smallint          NULL,
    [object_id]                        int               NULL,
    index_id                           int               NULL,
    partition_number                   int               NULL,
    hobt_id                            bigint            NULL,
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

    CONSTRAINT CUQ__dm_db_index_operational_stats__DatabaseID__IndexID__BoundaryValue UNIQUE CLUSTERED (_DatabaseID, _IndexID, _BoundaryValue) WITH (DATA_COMPRESSION = PAGE),
);
GO
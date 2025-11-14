CREATE TYPE import.import__dm_db_index_operational_stats AS TABLE (
    __ID                               int           NOT NULL,
    _SchemaName                        nvarchar(128) NOT NULL,
    _ObjectName                        nvarchar(128) NOT NULL,
    _ObjectType                        char(2)       NOT NULL,
    _IndexName                         nvarchar(128) NOT NULL,
    _BoundaryValue                     nvarchar(100)     NULL,
    --
    EstimatedStatsBeginTime            datetime2     NOT NULL,
    StatsEndTime                       datetime2     NOT NULL,
    --
    __database_id                      smallint          NULL,
    __object_id                        int               NULL,
    __index_id                         int               NULL,
    __partition_number                 int               NULL,
    __hobt_id                          bigint            NULL,
    --
    database_id                        smallint          NULL,
    [object_id]                        int               NULL,
    index_id                           int               NULL,
    partition_number                   int               NULL,
    hobt_id                            bigint            NULL,
    --
    leaf_insert_count                  bigint            NULL,
    leaf_delete_count                  bigint            NULL,
    leaf_update_count                  bigint            NULL,
    leaf_ghost_count                   bigint            NULL,
    nonleaf_insert_count               bigint            NULL,
    nonleaf_delete_count               bigint            NULL,
    nonleaf_update_count               bigint            NULL,
    leaf_allocation_count              bigint            NULL,
    nonleaf_allocation_count           bigint            NULL,
    leaf_page_merge_count              bigint            NULL,
    nonleaf_page_merge_count           bigint            NULL,
    range_scan_count                   bigint            NULL,
    singleton_lookup_count             bigint            NULL,
    forwarded_fetch_count              bigint            NULL,
    lob_fetch_in_pages                 bigint            NULL,
    lob_fetch_in_bytes                 bigint            NULL,
    lob_orphan_create_count            bigint            NULL,
    lob_orphan_insert_count            bigint            NULL,
    row_overflow_fetch_in_pages        bigint            NULL,
    row_overflow_fetch_in_bytes        bigint            NULL,
    column_value_push_off_row_count    bigint            NULL,
    column_value_pull_in_row_count     bigint            NULL,
    row_lock_count                     bigint            NULL,
    row_lock_wait_count                bigint            NULL,
    row_lock_wait_in_ms                bigint            NULL,
    page_lock_count                    bigint            NULL,
    page_lock_wait_count               bigint            NULL,
    page_lock_wait_in_ms               bigint            NULL,
    index_lock_promotion_attempt_count bigint            NULL,
    index_lock_promotion_count         bigint            NULL,
    page_latch_wait_count              bigint            NULL,
    page_latch_wait_in_ms              bigint            NULL,
    page_io_latch_wait_count           bigint            NULL,
    page_io_latch_wait_in_ms           bigint            NULL,
    tree_page_latch_wait_count         bigint            NULL,
    tree_page_latch_wait_in_ms         bigint            NULL,
    tree_page_io_latch_wait_count      bigint            NULL,
    tree_page_io_latch_wait_in_ms      bigint            NULL,
    page_compression_attempt_count     bigint            NULL,
    page_compression_success_count     bigint            NULL,
    version_generated_inrow            bigint            NULL, -- Added in SQL Server 2019
    version_generated_offrow           bigint            NULL, -- Added in SQL Server 2019
    ghost_version_inrow                bigint            NULL, -- Added in SQL Server 2019
    ghost_version_offrow               bigint            NULL, -- Added in SQL Server 2019
    insert_over_ghost_version_inrow    bigint            NULL, -- Added in SQL Server 2019
    insert_over_ghost_version_offrow   bigint            NULL, -- Added in SQL Server 2019

    INDEX CIX CLUSTERED (__ID)
);
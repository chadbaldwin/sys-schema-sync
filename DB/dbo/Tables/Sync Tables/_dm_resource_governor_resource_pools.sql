CREATE TABLE dbo._dm_resource_governor_resource_pools (
    _InstanceID                             int             NOT NULL CONSTRAINT FK__dm_resource_governor_resource_pools__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    _CollectionDate                         datetime2       NOT NULL,
    --
    pool_id                                 int             NOT NULL,
    [name]                                  nvarchar(256)   NOT NULL,
    statistics_start_time                   datetime        NOT NULL,
    total_cpu_usage_ms                      bigint          NOT NULL,
    cache_memory_kb                         bigint          NOT NULL,
    compile_memory_kb                       bigint          NOT NULL,
    used_memgrant_kb                        bigint          NOT NULL,
    total_memgrant_count                    bigint          NOT NULL,
    total_memgrant_timeout_count            bigint          NOT NULL,
    active_memgrant_count                   int             NOT NULL,
    active_memgrant_kb                      bigint          NOT NULL,
    memgrant_waiter_count                   int             NOT NULL,
    max_memory_kb                           bigint          NOT NULL,
    used_memory_kb                          bigint          NOT NULL,
    target_memory_kb                        bigint          NOT NULL,
    out_of_memory_count                     bigint          NOT NULL,
    min_cpu_percent                         int             NOT NULL,
    max_cpu_percent                         int             NOT NULL,
    min_memory_percent                      int             NOT NULL,
    max_memory_percent                      int             NOT NULL,
    cap_cpu_percent                         int             NOT NULL,
    min_iops_per_volume                     int                 NULL,
    max_iops_per_volume                     int                 NULL,
    read_io_queued_total                    int                 NULL,
    read_io_issued_total                    int                 NULL,
    read_io_completed_total                 int             NOT NULL,
    read_io_throttled_total                 int                 NULL,
    read_bytes_total                        bigint          NOT NULL,
    read_io_stall_total_ms                  bigint          NOT NULL,
    read_io_stall_queued_ms                 bigint              NULL,
    write_io_queued_total                   int                 NULL,
    write_io_issued_total                   int                 NULL,
    write_io_completed_total                int             NOT NULL,
    write_io_throttled_total                int                 NULL,
    write_bytes_total                       bigint          NOT NULL,
    write_io_stall_total_ms                 bigint          NOT NULL,
    write_io_stall_queued_ms                bigint              NULL,
    io_issue_violations_total               int                 NULL,
    io_issue_delay_total_ms                 bigint              NULL,
    io_issue_ahead_total_ms                 bigint              NULL,
    reserved_io_limited_by_volume_total     int                 NULL,
    io_issue_delay_non_throttled_total_ms   bigint              NULL,
    total_cpu_delayed_ms                    bigint          NOT NULL,
    total_cpu_active_ms                     bigint          NOT NULL,
    total_cpu_violation_delay_ms            bigint          NOT NULL,
    total_cpu_violation_sec                 bigint          NOT NULL,
    total_cpu_usage_preemptive_ms           bigint          NOT NULL,

    INDEX CIX__dm_resource_governor_resource_pools__InstanceID CLUSTERED (_InstanceID),
);
GO

CREATE TABLE dbo._dm_os_sys_memory (
    _InstanceID                     int             NOT NULL CONSTRAINT FK__dm_os_sys_memory__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    _CollectionDate                 datetime2       NOT NULL,
    --
    total_physical_memory_kb        bigint          NOT NULL,
    available_physical_memory_kb    bigint          NOT NULL,
    total_page_file_kb              bigint          NOT NULL,
    available_page_file_kb          bigint          NOT NULL,
    system_cache_kb                 bigint          NOT NULL,
    kernel_paged_pool_kb            bigint          NOT NULL,
    kernel_nonpaged_pool_kb         bigint          NOT NULL,
    system_high_memory_signal_state bit             NOT NULL,
    system_low_memory_signal_state  bit             NOT NULL,
    system_memory_state_desc        nvarchar(256)   NOT NULL,

    INDEX CIX__dm_os_sys_memory__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

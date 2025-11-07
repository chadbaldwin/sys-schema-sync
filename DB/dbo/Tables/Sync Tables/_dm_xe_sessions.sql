CREATE TABLE dbo._dm_xe_sessions (
    _InstanceID                int           NOT NULL CONSTRAINT FK__dm_xe_sessions__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate            datetime2     NOT NULL,
    --
    [address]                  varbinary(8)  NOT NULL,
    [name]                     nvarchar(256) NOT NULL,
    pending_buffers            int           NOT NULL,
    total_regular_buffers      int           NOT NULL,
    regular_buffer_size        bigint        NOT NULL,
    total_large_buffers        int           NOT NULL,
    large_buffer_size          bigint        NOT NULL,
    total_buffer_size          bigint        NOT NULL,
    buffer_policy_flags        int           NOT NULL,
    buffer_policy_desc         nvarchar(256) NOT NULL,
    flags                      int           NOT NULL,
    flag_desc                  nvarchar(256) NOT NULL,
    dropped_event_count        int           NOT NULL,
    dropped_buffer_count       int           NOT NULL,
    blocked_event_fire_time    int           NOT NULL,
    create_time                datetime      NOT NULL,
    largest_event_dropped_size int           NOT NULL,
    session_source             nvarchar(256) NOT NULL,
    buffer_processed_count     bigint        NOT NULL,
    buffer_full_count          bigint        NOT NULL,
    total_bytes_generated      bigint        NOT NULL,
    total_target_memory        bigint            NULL, -- Added: SQL Server 2022
    buffer_processing_count    int               NULL, -- Added: SQL Server 2025

    CONSTRAINT CUQ__dm_xe_sessions__InstanceID_address UNIQUE CLUSTERED (_InstanceID, [address]),
);
GO
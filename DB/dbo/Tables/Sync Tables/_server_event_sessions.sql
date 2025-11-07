CREATE TABLE dbo._server_event_sessions (
    _InstanceID                int           NOT NULL CONSTRAINT FK__server_event_sessions__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate            datetime2     NOT NULL,
    --
    event_session_id           int           NOT NULL,
    [name]                     nvarchar(128)     NULL,
    event_retention_mode       char(1)           NULL,
    event_retention_mode_desc  nvarchar(60)      NULL,
    max_dispatch_latency       int               NULL,
    max_memory                 int               NULL,
    max_event_size             int               NULL,
    memory_partition_mode      char(1)           NULL,
    memory_partition_mode_desc nvarchar(60)      NULL,
    track_causality            bit               NULL,
    startup_state              bit               NULL,
    has_long_running_target    bit               NULL, -- Added: SQL Server 2019
    [max_duration]             bigint            NULL, -- Added: SQL Server 2025

    CONSTRAINT CUQ__server_event_sessions__InstanceID_event_session_id UNIQUE CLUSTERED (_InstanceID, event_session_id),
);
GO
CREATE TABLE dbo._dm_os_nodes (
    _InstanceID                     int             NOT NULL CONSTRAINT FK__dm_os_nodes__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    _CollectionDate                 datetime2       NOT NULL,
    --
    node_id                         smallint        NOT NULL,
    node_state_desc                 nvarchar(256)   NOT NULL,
    memory_object_address           varbinary(8)    NOT NULL,
    memory_clerk_address            varbinary(8)    NOT NULL,
    io_completion_worker_address    varbinary(8)        NULL,
    memory_node_id                  smallint        NOT NULL,
    cpu_affinity_mask               bigint          NOT NULL,
    online_scheduler_count          smallint        NOT NULL,
    idle_scheduler_count            smallint        NOT NULL,
    active_worker_count             int             NOT NULL,
    avg_load_balance                int             NOT NULL,
    timer_task_affinity_mask        bigint          NOT NULL,
    permanent_task_affinity_mask    bigint          NOT NULL,
    resource_monitor_state          bit             NOT NULL,
    online_scheduler_mask           bigint          NOT NULL,
    processor_group                 smallint        NOT NULL,
    cpu_count                       int             NOT NULL,
    cached_tasks                    bigint              NULL, -- Added: SQL Server 2022 - Deviation: NOT NULL
    cached_tasks_reused             bigint              NULL, -- Added: SQL Server 2022 - Deviation: NOT NULL
    cached_tasks_removed            bigint              NULL, -- Added: SQL Server 2022 - Deviation: NOT NULL

    INDEX CIX__dm_os_nodes__InstanceID CLUSTERED (_InstanceID),
);
GO

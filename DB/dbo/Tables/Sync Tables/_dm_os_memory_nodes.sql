CREATE TABLE dbo._dm_os_memory_nodes (
    _InstanceID                        int       NOT NULL CONSTRAINT FK__dm_os_memory_nodes__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate                    datetime2 NOT NULL,
    --
    memory_node_id                     smallint  NOT NULL,
    virtual_address_space_reserved_kb  bigint    NOT NULL,
    virtual_address_space_committed_kb bigint    NOT NULL,
    locked_page_allocations_kb         bigint    NOT NULL,
    pages_kb                           bigint    NOT NULL,
    shared_memory_reserved_kb          bigint    NOT NULL,
    shared_memory_committed_kb         bigint    NOT NULL,
    cpu_affinity_mask                  bigint    NOT NULL,
    online_scheduler_mask              bigint    NOT NULL,
    processor_group                    smallint  NOT NULL,
    foreign_committed_kb               bigint    NOT NULL,
    target_kb                          bigint    NOT NULL,

    CONSTRAINT CUQ__dm_os_memory_nodes__InstanceID_memory_node_id UNIQUE CLUSTERED (_InstanceID, memory_node_id),
);
GO
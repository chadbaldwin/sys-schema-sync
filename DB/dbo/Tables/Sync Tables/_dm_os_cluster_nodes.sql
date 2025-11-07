CREATE TABLE dbo._dm_os_cluster_nodes (
    _InstanceID        int           NOT NULL CONSTRAINT FK__dm_os_cluster_nodes__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate    datetime2     NOT NULL,
    --
    NodeName           nvarchar(128)     NULL,
    [status]           int               NULL,
    status_description varchar(7)    NOT NULL,
    is_current_owner   bit               NULL,

    CONSTRAINT CUQ__dm_os_cluster_nodes__InstanceID_NodeName UNIQUE CLUSTERED (_InstanceID, NodeName),
);
GO
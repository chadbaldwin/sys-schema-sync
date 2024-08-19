CREATE TABLE dbo._dm_hadr_cluster (
    _InstanceID         int             NOT NULL CONSTRAINT FK__dm_hadr_cluster__InstanceID REFERENCES dbo.[Instance] (InstanceID),
    _CollectionDate     datetime2       NOT NULL,
    --
    cluster_name        nvarchar(256)   NOT NULL,
    quorum_type         tinyint         NOT NULL,
    quorum_type_desc    nvarchar(60)    NOT NULL,
    quorum_state        tinyint         NOT NULL,
    quorum_state_desc   nvarchar(60)    NOT NULL,

    INDEX CIX__dm_hadr_cluster__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

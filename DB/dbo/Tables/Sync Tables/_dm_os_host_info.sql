CREATE TABLE dbo._dm_os_host_info (
    _InstanceID             int             NOT NULL CONSTRAINT FK__dm_os_host_info__InstanceID REFERENCES dbo.[Instance] (InstanceID),
    _CollectionDate         datetime2       NOT NULL,
    --
    host_platform           nvarchar(256)   NOT NULL,
    host_distribution       nvarchar(256)   NOT NULL,
    host_release            nvarchar(256)   NOT NULL,
    host_service_pack_level nvarchar(256)   NOT NULL,
    host_sku                int                 NULL,
    os_language_version     int             NOT NULL,
    host_architecture       nvarchar(256)       NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL

    INDEX CIX__dm_os_host_info__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

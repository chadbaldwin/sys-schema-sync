CREATE TABLE dbo._global_variables (
    _InstanceID     int           NOT NULL CONSTRAINT FK__global_variables__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate datetime2     NOT NULL,
    --
    SERVERNAME      nvarchar(128)     NULL,
    SERVICENAME     nvarchar(128)     NULL,
    [VERSION]       nvarchar(300)     NULL,

    CONSTRAINT CUQ__global_variables__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO
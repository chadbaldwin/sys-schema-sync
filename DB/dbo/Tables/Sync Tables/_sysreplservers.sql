CREATE TABLE dbo._sysreplservers (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__sysreplservers__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__sysreplservers__DatabaseID,
    _CollectionDate datetime2     NOT NULL,
    --
    srvname         nvarchar(128) NOT NULL,
    srvid           int               NULL,

    CONSTRAINT CUQ__sysreplservers__DatabaseID_srvid UNIQUE CLUSTERED (_DatabaseID, srvid),
);
GO
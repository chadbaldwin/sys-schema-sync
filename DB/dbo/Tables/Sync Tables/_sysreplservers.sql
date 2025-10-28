CREATE TABLE dbo._sysreplservers (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__sysreplservers__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by CIX
    _CollectionDate datetime2     NOT NULL,
    --
    srvname         nvarchar(128) NOT NULL,
    srvid           int               NULL,

    INDEX CIX__sysreplservers__DatabaseID_srvid UNIQUE CLUSTERED (_DatabaseID, srvid),
);
GO
CREATE TABLE import.DatabaseSyncObjectStatus (
    DatabaseSyncObjectID int            NOT NULL IDENTITY(1,1)
                                                 CONSTRAINT PK_DatabaseSyncObjectStatus_DatabaseSyncObjectID PRIMARY KEY NONCLUSTERED,
    _InstanceID          int            NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus__InstanceID          REFERENCES dbo.[Instance] (_InstanceID),
    _DatabaseID          int                NULL CONSTRAINT FK_DatabaseSyncObjectStatus__DatabaseID          REFERENCES dbo.[Database] (_DatabaseID),
    SyncObjectID         int            NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus_SyncObjectID         REFERENCES import.SyncObject (SyncObjectID),
    LastSyncChecksum     int                NULL,
    LastSyncTime         datetime2          NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncTime         DEFAULT (SYSUTCDATETIME()),
    LastSyncCheck        datetime2      NOT NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncCheck        DEFAULT (SYSUTCDATETIME()),
    LastSyncError        datetime2          NULL,
    LastSyncErrorMessage nvarchar(MAX)      NULL,

    INDEX CIX_DatabaseSyncObjectStatus__InstanceID__DatabaseID_SyncObjectID
        UNIQUE CLUSTERED (_InstanceID, _DatabaseID, SyncObjectID),
);
GO

CREATE NONCLUSTERED INDEX IX_DatabaseSyncObjectStatus__DatabaseID_SyncObjectID
    ON import.DatabaseSyncObjectStatus (_DatabaseID, SyncObjectID)
    INCLUDE (LastSyncChecksum, LastSyncTime, LastSyncCheck, LastSyncError, LastSyncErrorMessage);
GO
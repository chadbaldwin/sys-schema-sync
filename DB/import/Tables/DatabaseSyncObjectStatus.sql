CREATE TABLE import.DatabaseSyncObjectStatus (
    DatabaseSyncObjectID int            NOT NULL IDENTITY(1,1)
                                                 CONSTRAINT PK_DatabaseSyncObjectStatus_DatabaseSyncObjectID PRIMARY KEY NONCLUSTERED,
    InstanceID           int            NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus_InstanceID           REFERENCES dbo.[Instance] (InstanceID),
    DatabaseID           int                NULL CONSTRAINT FK_DatabaseSyncObjectStatus_DatabaseID           REFERENCES dbo.[Database] (DatabaseID),
    SyncObjectID         int            NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus_SyncObjectID         REFERENCES import.SyncObject (SyncObjectID),
    LastSyncChecksum     int                NULL,
    LastSyncTime         datetime2          NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncTime         DEFAULT (SYSUTCDATETIME()),
    LastSyncCheck        datetime2      NOT NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncCheck        DEFAULT (SYSUTCDATETIME()),
    LastSyncError        datetime2          NULL,
    LastSyncErrorMessage nvarchar(MAX)      NULL,

    INDEX CIX_DatabaseSyncObjectStatus_InstanceID_DatabaseID_SyncObjectID
        UNIQUE CLUSTERED (InstanceID, DatabaseID, SyncObjectID),
);
GO

CREATE NONCLUSTERED INDEX IX_DatabaseSyncObjectStatus_DatabaseID_SyncObjectID
    ON import.DatabaseSyncObjectStatus (DatabaseID, SyncObjectID)
    INCLUDE (LastSyncChecksum, LastSyncTime, LastSyncCheck, LastSyncError, LastSyncErrorMessage);
GO
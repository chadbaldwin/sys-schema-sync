CREATE TABLE import.DatabaseSyncObjectStatus (
    DatabaseSyncObjectID int           NOT NULL IDENTITY(1,1),
    _InstanceID          int           NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus__InstanceID      REFERENCES dbo.[Instance] (_InstanceID),    -- Covered by CIX
    _DatabaseID          int               NULL CONSTRAINT FK_DatabaseSyncObjectStatus__DatabaseID      REFERENCES dbo.[Database] (_DatabaseID)     INDEX IX_DatabaseSyncObjectStatus__DatabaseID,
    SyncObjectID         int           NOT NULL CONSTRAINT FK_DatabaseSyncObjectStatus_SyncObjectID     REFERENCES import.SyncObject (SyncObjectID) INDEX IX_DatabaseSyncObjectStatus_SyncObjectID,
    LastSyncChecksum     int               NULL,
    LastSyncTime         datetime2         NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncTime     DEFAULT (SYSUTCDATETIME()),
    LastSyncCheck        datetime2     NOT NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncCheck    DEFAULT (SYSUTCDATETIME()),
    LastSyncError        datetime2         NULL,
    LastSyncErrorMessage nvarchar(MAX)     NULL,
    LastSyncWasError     bit           NOT NULL CONSTRAINT DF_DatabaseSyncObjectStatus_LastSyncWasError DEFAULT (0),

    CONSTRAINT CPK_DatabaseSyncObjectStatus_DatabaseSyncObjectID PRIMARY KEY CLUSTERED (DatabaseSyncObjectID),
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DatabaseSyncObjectStatus__InstanceID__DatabaseID_SyncObjectID
    ON import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID);

GO

CREATE NONCLUSTERED INDEX IX_DatabaseSyncObjectStatus__DatabaseID_SyncObjectID
    ON import.DatabaseSyncObjectStatus (_DatabaseID, SyncObjectID)
    INCLUDE (LastSyncChecksum, LastSyncTime, LastSyncCheck, LastSyncError, LastSyncErrorMessage);
GO
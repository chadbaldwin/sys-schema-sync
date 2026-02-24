CREATE TABLE import.SyncObject (
    SyncObjectID                   int           NOT NULL CONSTRAINT CPK_SyncObject_SyncObjectID PRIMARY KEY CLUSTERED,
    SyncObjectName                 nvarchar(128) NOT NULL CONSTRAINT UQ_SyncObject_SyncObjectName UNIQUE,
    SyncObjectLevelID              int           NOT NULL CONSTRAINT FK_SyncObject_SyncObjectLevelID REFERENCES import.SyncObjectLevel (SyncObjectLevelID)
                                                          INDEX IX_SyncObject_SyncObjectLevelID NONCLUSTERED,
    IsEnabled                      bit           NOT NULL CONSTRAINT DF_SyncObject_IsEnabled DEFAULT (1),
    SyncStaleAgeMinutes            int           NOT NULL,
    OpportunisticSchedulingEnabled bit           NOT NULL CONSTRAINT DF_SyncObject_OpportunisticSchedulingEnabled DEFAULT (1),
    ImportTable                    nvarchar(128)     NULL,
    ImportProc                     nvarchar(128)     NULL,
    ExportQueryPath                nvarchar(MAX)     NULL,
    SyncOnZeroChecksum             bit           NOT NULL CONSTRAINT DF_SyncObject_SyncOnZeroChecksum DEFAULT (1),
    ChecksumQueryText              nvarchar(MAX)     NULL,
);
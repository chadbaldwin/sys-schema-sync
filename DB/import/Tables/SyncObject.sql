CREATE TABLE import.SyncObject (
    SyncObjectID        int              NOT NULL CONSTRAINT CPK_SyncObject_SyncObjectID PRIMARY KEY CLUSTERED,
    SyncObjectName      nvarchar(128)    NOT NULL CONSTRAINT UQ_SyncObject_SyncObjectName UNIQUE,
    SyncObjectLevelID   int              NOT NULL CONSTRAINT FK_SyncObject_SyncObjectLevelID REFERENCES import.SyncObjectLevel (SyncObjectLevelID),
    IsEnabled           bit              NOT NULL CONSTRAINT DF_SyncObject_IsEnabled DEFAULT (1),
    SyncStaleAgeMinutes int              NOT NULL,
    ImportTable         nvarchar(128)        NULL,
    ImportProc          nvarchar(128)        NULL,
    ImportType          nvarchar(128)        NULL,
    ExportQueryPath     nvarchar(MAX)        NULL,
    ChecksumQueryText   nvarchar(MAX)        NULL,
);
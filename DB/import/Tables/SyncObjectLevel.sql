CREATE TABLE import.SyncObjectLevel (
    SyncObjectLevelID   int              NOT NULL,
    SyncObjectLevelName nvarchar(128)    NOT NULL,

    CONSTRAINT CPK_SyncObjectLevel_SyncObjectLevelID PRIMARY KEY CLUSTERED (SyncObjectLevelID),
);
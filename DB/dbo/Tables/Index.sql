CREATE TABLE dbo.[Index] (
    _DatabaseID int           NOT NULL CONSTRAINT FK_Index__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by other IX
    _ObjectID   bigint        NOT NULL CONSTRAINT FK_Index__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)    INDEX IX_Index__ObjectID,
    _IndexID    bigint        NOT NULL IDENTITY
                                       CONSTRAINT CPK_Index__IndexID   PRIMARY KEY CLUSTERED WITH (DATA_COMPRESSION = PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON),
    IndexName   nvarchar(128) NOT NULL,
    IsDeleted   bit           NOT NULL CONSTRAINT DF_Index_IsDeleted   DEFAULT (0),
    InsertDate  datetime2     NOT NULL CONSTRAINT DF_Index_InsertDate  DEFAULT (SYSUTCDATETIME()),
    DeleteDate  datetime2         NULL,

    CONSTRAINT UQ_Index__DatabaseID__ObjectID_IndexName UNIQUE (_DatabaseID, _ObjectID, IndexName),

    INDEX IX_Index__DatabaseID_IsDeleted NONCLUSTERED (_DatabaseID, IsDeleted),
    INDEX IX_Index_DeleteDate NONCLUSTERED (DeleteDate),
);
GO
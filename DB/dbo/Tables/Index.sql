CREATE TABLE dbo.[Index] (
    _DatabaseID   int              NOT NULL CONSTRAINT FK_Index__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) ON DELETE CASCADE,
    _ObjectID     bigint           NOT NULL CONSTRAINT FK_Index__ObjectID   REFERENCES dbo.[Object]   (_ObjectID),
    _IndexID      bigint           NOT NULL IDENTITY,
    IndexName     nvarchar(128)    NOT NULL,
    IsDeleted     bit              NOT NULL CONSTRAINT DF_Index_IsDeleted   DEFAULT (0),
    InsertDate    datetime2        NOT NULL CONSTRAINT DF_Index_InsertDate  DEFAULT (SYSUTCDATETIME()),
    DeleteDate    datetime2            NULL,

    CONSTRAINT PK_Index__IndexID PRIMARY KEY NONCLUSTERED (_IndexID),
    INDEX CIX_Index__DatabaseID__IndexID UNIQUE CLUSTERED (_DatabaseID, _IndexID),

    INDEX IX_Index__DatabaseID__ObjectID_IndexName NONCLUSTERED (_DatabaseID, _ObjectID, IndexName),
    INDEX IX_Index__DatabaseID_IsDeleted NONCLUSTERED (_DatabaseID, IsDeleted),
    INDEX IX_Index__ObjectID NONCLUSTERED (_ObjectID),
    INDEX IX_Index_DeleteDate NONCLUSTERED (DeleteDate),
);
GO
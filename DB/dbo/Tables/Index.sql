CREATE TABLE dbo.[Index] (
    _DatabaseID   int              NOT NULL CONSTRAINT FK_Index__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _ObjectID     int              NOT NULL CONSTRAINT FK_Index__ObjectID   REFERENCES dbo.[Object]   (_ObjectID),
    _IndexID      int              NOT NULL IDENTITY,
    IndexName     nvarchar(128)    NOT NULL,
    IsDeleted     bit              NOT NULL CONSTRAINT DF_Index_IsDeleted   DEFAULT (0),
    InsertDate    datetime2        NOT NULL CONSTRAINT DF_Index_InsertDate  DEFAULT (SYSUTCDATETIME()),
    DeleteDate    datetime2            NULL,

    INDEX CIX_Index__DatabaseID__IndexID UNIQUE CLUSTERED (_DatabaseID, _IndexID),
    CONSTRAINT PK_Index__IndexID PRIMARY KEY NONCLUSTERED (_IndexID),
);
GO

CREATE NONCLUSTERED INDEX IX_Index__DatabaseID__ObjectID_IndexName
    ON dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
GO

CREATE NONCLUSTERED INDEX IX_Index__DatabaseID_IsDeleted
    ON dbo.[Index] (_DatabaseID, IsDeleted)
GO

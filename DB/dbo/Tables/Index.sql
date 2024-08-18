CREATE TABLE dbo.[Index] (
    DatabaseID    int              NOT NULL CONSTRAINT FK_Index_DatabaseID REFERENCES dbo.[Database] (DatabaseID),
    ObjectID      int              NOT NULL CONSTRAINT FK_Index_ObjectID   REFERENCES dbo.[Object]   (ObjectID),
    IndexID       int              NOT NULL IDENTITY,
    IndexName     nvarchar(128)    NOT NULL,
    IsDeleted     bit              NOT NULL CONSTRAINT DF_Index_IsDeleted DEFAULT (0),
    InsertDate    datetime2        NOT NULL CONSTRAINT DF_Index_InsertDate DEFAULT (SYSUTCDATETIME()),
    DeleteDate    datetime2            NULL,

    INDEX CIX_Index_DatabaseID_IndexID UNIQUE CLUSTERED (DatabaseID, IndexID),
    CONSTRAINT PK_Index_IndexID PRIMARY KEY NONCLUSTERED (IndexID),
);
GO

CREATE NONCLUSTERED INDEX IX_Index_DatabaseID_ObjectID_IndexName
    ON dbo.[Index] (DatabaseID, ObjectID, IndexName)
GO

CREATE NONCLUSTERED INDEX IX_Index_DatabaseID_IsDeleted
	ON dbo.[Index] (DatabaseID, IsDeleted)
GO

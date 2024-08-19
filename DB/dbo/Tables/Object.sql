CREATE TABLE dbo.[Object] (
    DatabaseID      int             NOT NULL CONSTRAINT FK_Object_DatabaseID    REFERENCES dbo.[Database] (DatabaseID),
    ObjectID        int             NOT NULL IDENTITY,
    SchemaName      nvarchar(128)   NOT NULL,
    ObjectName      nvarchar(128)   NOT NULL,
    ObjectType      char(2)         NOT NULL,
    IsDeleted       bit             NOT NULL CONSTRAINT DF_Object_IsDeleted     DEFAULT (0),
    InsertDate      datetime2       NOT NULL CONSTRAINT DF_Object_InsertDate    DEFAULT (SYSUTCDATETIME()),
    DeleteDate      datetime2           NULL,

    INDEX CIX_Object_DatabaseID_ObjectID UNIQUE CLUSTERED (DatabaseID, ObjectID),
    CONSTRAINT PK_Object_ObjectID PRIMARY KEY NONCLUSTERED (ObjectID),
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Object_DatabaseID_SchemaName_ObjectName_ObjectType
    ON dbo.[Object] (DatabaseID, SchemaName, ObjectName, ObjectType)
GO

CREATE NONCLUSTERED INDEX IX_Object_DatabaseID_IsDeleted
    ON dbo.[Object] (DatabaseID, IsDeleted)
GO

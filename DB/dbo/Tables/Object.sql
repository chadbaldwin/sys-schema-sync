CREATE TABLE dbo.[Object] (
    _DatabaseID     int             NOT NULL CONSTRAINT FK_Object__DatabaseID   REFERENCES dbo.[Database] (_DatabaseID),
    _ObjectID       int             NOT NULL IDENTITY,
    SchemaName      nvarchar(128)   NOT NULL,
    ObjectName      nvarchar(128)   NOT NULL,
    ObjectType      char(2)         NOT NULL,
    IsDeleted       bit             NOT NULL CONSTRAINT DF_Object_IsDeleted     DEFAULT (0),
    InsertDate      datetime2       NOT NULL CONSTRAINT DF_Object_InsertDate    DEFAULT (SYSUTCDATETIME()),
    DeleteDate      datetime2           NULL,

    INDEX CIX_Object__DatabaseID__ObjectID UNIQUE CLUSTERED (_DatabaseID, _ObjectID),
    CONSTRAINT PK_Object__ObjectID PRIMARY KEY NONCLUSTERED (_ObjectID),
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Object__DatabaseID_SchemaName_ObjectName_ObjectType
    ON dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
GO

CREATE NONCLUSTERED INDEX IX_Object__DatabaseID_IsDeleted
    ON dbo.[Object] (_DatabaseID, IsDeleted)
GO

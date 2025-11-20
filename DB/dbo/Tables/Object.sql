CREATE TABLE dbo.[Object] (
    _DatabaseID int           NOT NULL CONSTRAINT FK_Object__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _ObjectID   bigint        NOT NULL IDENTITY
                                       CONSTRAINT CPK_Object__ObjectID  PRIMARY KEY CLUSTERED WITH (DATA_COMPRESSION = PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON),
    SchemaName  nvarchar(128) NOT NULL,
    ObjectName  nvarchar(128) NOT NULL,
    ObjectType  char(2)       NOT NULL,
    IsDeleted   bit           NOT NULL CONSTRAINT DF_Object_IsDeleted   DEFAULT (0),
    InsertDate  datetime2     NOT NULL CONSTRAINT DF_Object_InsertDate  DEFAULT (SYSUTCDATETIME()),
    DeleteDate  datetime2         NULL,
    FQON        AS (CONVERT(nvarchar(300), QUOTENAME(SchemaName) + '.' + QUOTENAME(ObjectName))) PERSISTED,

    CONSTRAINT UQ_Object__DatabaseID_SchemaName_ObjectName_ObjectType UNIQUE NONCLUSTERED (_DatabaseID, SchemaName, ObjectName, ObjectType) WITH (DATA_COMPRESSION = PAGE),

    INDEX IX_Object__DatabaseID_IsDeleted_SchemaName NONCLUSTERED (_DatabaseID, IsDeleted, SchemaName) INCLUDE (DeleteDate),
    INDEX IX_Object_DeleteDate NONCLUSTERED (DeleteDate),
    INDEX IX_Object_FQON NONCLUSTERED (FQON) WITH (DATA_COMPRESSION = PAGE),
);
GO
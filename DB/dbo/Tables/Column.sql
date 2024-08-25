CREATE TABLE dbo.[Column] (
    _DatabaseID     int             NOT NULL CONSTRAINT FK_Column__DatabaseID   REFERENCES dbo.[Database] (_DatabaseID),
    _ObjectID       int             NOT NULL CONSTRAINT FK_Column__ObjectID     REFERENCES dbo.[Object]   (_ObjectID),
    _ColumnID       int             NOT NULL IDENTITY,
    ColumnName      nvarchar(128)   NOT NULL,
    IsDeleted       bit             NOT NULL CONSTRAINT DF_Column_IsDeleted     DEFAULT (0),
    InsertDate      datetime2       NOT NULL CONSTRAINT DF_Column_InsertDate    DEFAULT (SYSUTCDATETIME()),
    DeleteDate      datetime2           NULL,

    INDEX CIX_Column__DatabaseID__ColumnID UNIQUE CLUSTERED (_DatabaseID, _ColumnID),
    CONSTRAINT PK_Column__ColumnID PRIMARY KEY NONCLUSTERED (_ColumnID),
);
GO

CREATE NONCLUSTERED INDEX IX_Column__DatabaseID__ObjectID_ColumnName
    ON dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
GO

CREATE NONCLUSTERED INDEX IX_Column__DatabaseID_IsDeleted
    ON dbo.[Column] (_DatabaseID, IsDeleted)
GO

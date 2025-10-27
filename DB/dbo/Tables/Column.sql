CREATE TABLE dbo.[Column] (
    _DatabaseID     int             NOT NULL CONSTRAINT FK_Column__DatabaseID   REFERENCES dbo.[Database] (_DatabaseID) ON DELETE CASCADE,
    _ObjectID       bigint          NOT NULL CONSTRAINT FK_Column__ObjectID     REFERENCES dbo.[Object]   (_ObjectID),
    _ColumnID       bigint          NOT NULL IDENTITY,
    ColumnName      nvarchar(128)   NOT NULL,
    IsDeleted       bit             NOT NULL CONSTRAINT DF_Column_IsDeleted     DEFAULT (0),
    InsertDate      datetime2       NOT NULL CONSTRAINT DF_Column_InsertDate    DEFAULT (SYSUTCDATETIME()),
    DeleteDate      datetime2           NULL,

    CONSTRAINT PK_Column__ColumnID PRIMARY KEY NONCLUSTERED (_ColumnID),
    INDEX CIX_Column__DatabaseID__ColumnID UNIQUE CLUSTERED (_DatabaseID, _ColumnID) WITH (DATA_COMPRESSION = PAGE),
    INDEX IX_Column__DatabaseID__ObjectID_ColumnName NONCLUSTERED (_DatabaseID, _ObjectID, ColumnName) WITH (DATA_COMPRESSION = PAGE),
    INDEX IX_Column__DatabaseID_IsDeleted NONCLUSTERED (_DatabaseID, IsDeleted),
    INDEX IX_Column__ObjectID NONCLUSTERED (_ObjectID),
);
GO
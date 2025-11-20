CREATE TABLE dbo.[Column] (
    _DatabaseID int           NOT NULL CONSTRAINT FK_Column__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by other IX
    _ObjectID   bigint        NOT NULL CONSTRAINT FK_Column__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)    INDEX IX_Column__ObjectID,
    _ColumnID   bigint        NOT NULL IDENTITY
                                       CONSTRAINT CPK_Column__ColumnID  PRIMARY KEY CLUSTERED WITH (DATA_COMPRESSION = PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON),
    ColumnName  nvarchar(128) NOT NULL,
    IsDeleted   bit           NOT NULL CONSTRAINT DF_Column_IsDeleted   DEFAULT (0),
    InsertDate  datetime2     NOT NULL CONSTRAINT DF_Column_InsertDate  DEFAULT (SYSUTCDATETIME()),
    DeleteDate  datetime2         NULL,

    CONSTRAINT UQ_Column__DatabaseID__ObjectID_ColumnName UNIQUE (_DatabaseID, _ObjectID, ColumnName) WITH (DATA_COMPRESSION = PAGE),

    INDEX IX_Column__DatabaseID_IsDeleted NONCLUSTERED (_DatabaseID, IsDeleted) INCLUDE (DeleteDate),
    INDEX IX_Column_DeleteDate NONCLUSTERED (DeleteDate),
);
GO
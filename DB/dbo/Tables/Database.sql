CREATE TABLE dbo.[Database] (
    _DatabaseID     int             NOT NULL IDENTITY
                                             CONSTRAINT CPK_Database__DatabaseID PRIMARY KEY CLUSTERED,
    _InstanceID     int             NOT NULL CONSTRAINT FK_Database__InstanceID  REFERENCES dbo.Instance (_InstanceID),
    DatabaseName    nvarchar(128)   NOT NULL,
    InsertDate      datetime2       NOT NULL CONSTRAINT DF_Database_InsertDate   DEFAULT (SYSUTCDATETIME()),
    IsEnabled       bit             NOT NULL CONSTRAINT DF_Database_IsEnabled    DEFAULT (1),
);

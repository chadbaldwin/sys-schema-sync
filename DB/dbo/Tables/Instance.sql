CREATE TABLE dbo.[Instance] (
    _InstanceID  int           NOT NULL IDENTITY
                                        CONSTRAINT CPK_Instance__InstanceID PRIMARY KEY CLUSTERED,
    InstanceName nvarchar(257) NOT NULL,
    InsertDate   datetime2     NOT NULL CONSTRAINT DF_Instance_InsertDate   DEFAULT (SYSUTCDATETIME()),
    IsEnabled    bit           NOT NULL CONSTRAINT DF_Instance_IsEnabled    DEFAULT (1),
    DisableDate  datetime2         NULL,

    CONSTRAINT UQ_Instance_InstanceName UNIQUE (InstanceName),
    CONSTRAINT CK_Instance_DisabledInstances_RequireDisableDate CHECK (IsEnabled = 1 OR (IsEnabled = 0 AND DisableDate IS NOT NULL))
);
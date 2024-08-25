CREATE TABLE dbo._objects (
    _DatabaseID         int             NOT NULL CONSTRAINT FK__objects__DatabaseID REFERENCES dbo.[Database]   (_DatabaseID),
    _ObjectID           int             NOT NULL CONSTRAINT FK__objects__ObjectID   REFERENCES dbo.[Object]     (_ObjectID),
    _InsertDate         datetime2       NOT NULL CONSTRAINT DF__objects__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate         datetime2       NOT NULL CONSTRAINT DF__objects__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash            binary(32)      NOT NULL,
    _SchemaName         nvarchar(128)   NOT NULL,
    _ValidFrom          datetime2       GENERATED ALWAYS AS ROW START   NOT NULL,
    _ValidTo            datetime2       GENERATED ALWAYS AS ROW END     NOT NULL,
    --
    [name]              nvarchar(128)   NOT NULL,
    [object_id]         int             NOT NULL,
    principal_id        int                 NULL,
    [schema_id]         int             NOT NULL,
    parent_object_id    int             NOT NULL,
    [type]              char(2)             NULL,
    [type_desc]         nvarchar(60)        NULL,
    create_date         datetime        NOT NULL,
    is_ms_shipped       bit             NOT NULL,
    is_published        bit             NOT NULL,
    is_schema_published bit             NOT NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__objects__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
    INDEX IX__objects__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._objects_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

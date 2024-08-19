CREATE TABLE dbo._views (
    _DatabaseID                 int             NOT NULL CONSTRAINT FK__views__DatabaseID   REFERENCES dbo.[Database]   (DatabaseID),
    _ObjectID                   int             NOT NULL CONSTRAINT FK__views__ObjectID     REFERENCES dbo.[Object]     (ObjectID),
    _InsertDate                 datetime2       NOT NULL CONSTRAINT DF__views__InsertDate   DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                 datetime2       NOT NULL CONSTRAINT DF__views__ModifyDate   DEFAULT (SYSUTCDATETIME()),
    _RowHash                    binary(32)      NOT NULL,
    _ValidFrom                  datetime2       GENERATED ALWAYS AS ROW START   NOT NULL,
    _ValidTo                    datetime2       GENERATED ALWAYS AS ROW END     NOT NULL,
    --
    [name]                      nvarchar(128)   NOT NULL,
    [object_id]                 int             NOT NULL,
    principal_id                int                 NULL,
    [schema_id]                 int             NOT NULL,
    parent_object_id            int             NOT NULL,
    [type]                      char(2)             NULL,
    [type_desc]                 nvarchar(60)        NULL,
    create_date                 datetime        NOT NULL,
    modify_date                 datetime        NOT NULL,
    is_ms_shipped               bit             NOT NULL,
    is_published                bit             NOT NULL,
    is_schema_published         bit             NOT NULL,
    is_replicated               bit                 NULL,
    has_replication_filter      bit                 NULL,
    has_opaque_metadata         bit             NOT NULL,
    has_unchecked_assembly_data bit             NOT NULL,
    with_check_option           bit             NOT NULL,
    is_date_correlation_view    bit             NOT NULL,
    is_tracked_by_cdc           bit                 NULL,
    has_snapshot                bit                 NULL, -- Added: SQL Server 2019
    ledger_view_type            tinyint             NULL, -- Added: SQL Server 2022
    ledger_view_type_desc       nvarchar(60)        NULL, -- Added: SQL Server 2022
    is_dropped_ledger_view      bit                 NULL, -- Added: SQL Server 2022

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__views__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
    INDEX IX__views__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._views_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

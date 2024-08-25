CREATE TABLE dbo._tables (
    _DatabaseID                         int             NOT NULL CONSTRAINT FK__tables__DatabaseID  REFERENCES dbo.[Database]   (_DatabaseID),
    _ObjectID                           int             NOT NULL CONSTRAINT FK__tables__ObjectID    REFERENCES dbo.[Object]     (_ObjectID),
    _InsertDate                         datetime2       NOT NULL CONSTRAINT DF__tables__InsertDate  DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                         datetime2       NOT NULL CONSTRAINT DF__tables__ModifyDate  DEFAULT (SYSUTCDATETIME()),
    _RowHash                            binary(32)      NOT NULL,
    _ValidFrom                          datetime2       GENERATED ALWAYS AS ROW START   NOT NULL,
    _ValidTo                            datetime2       GENERATED ALWAYS AS ROW END     NOT NULL,
    --
    [name]                              nvarchar(128)   NOT NULL,
    [object_id]                         int             NOT NULL,
    principal_id                        int                 NULL,
    [schema_id]                         int             NOT NULL,
    parent_object_id                    int             NOT NULL,
    [type]                              char(2)             NULL,
    [type_desc]                         nvarchar(60)        NULL,
    create_date                         datetime        NOT NULL,
    is_ms_shipped                       bit             NOT NULL,
    is_published                        bit             NOT NULL,
    is_schema_published                 bit             NOT NULL,
    lob_data_space_id                   int             NOT NULL,
    filestream_data_space_id            int                 NULL,
    max_column_id_used                  int             NOT NULL,
    lock_on_bulk_load                   bit             NOT NULL,
    uses_ansi_nulls                     bit                 NULL,
    is_replicated                       bit                 NULL,
    has_replication_filter              bit                 NULL,
    is_merge_published                  bit                 NULL,
    is_sync_tran_subscribed             bit                 NULL,
    has_unchecked_assembly_data         bit             NOT NULL,
    text_in_row_limit                   int                 NULL,
    large_value_types_out_of_row        bit                 NULL,
    is_tracked_by_cdc                   bit                 NULL,
    [lock_escalation]                   tinyint             NULL,
    lock_escalation_desc                nvarchar(60)        NULL,
    is_filetable                        bit                 NULL,
    is_memory_optimized                 bit                 NULL,
    [durability]                        tinyint             NULL,
    durability_desc                     nvarchar(60)        NULL,
    temporal_type                       tinyint             NULL,
    temporal_type_desc                  nvarchar(60)        NULL,
    history_table_id                    int                 NULL,
    is_remote_data_archive_enabled      bit                 NULL,
    is_external                         bit             NOT NULL,
    history_retention_period            int                 NULL,
    history_retention_period_unit       int                 NULL,
    history_retention_period_unit_desc  nvarchar(10)        NULL,
    is_node                             bit                 NULL,
    is_edge                             bit                 NULL,
    data_retention_period               int                 NULL, -- Added: SQL Server 2022
    data_retention_period_unit          int                 NULL, -- Added: SQL Server 2022
    data_retention_period_unit_desc     nvarchar(10)        NULL, -- Added: SQL Server 2022
    ledger_type                         tinyint             NULL, -- Added: SQL Server 2022
    ledger_type_desc                    nvarchar(60)        NULL, -- Added: SQL Server 2022
    ledger_view_id                      int                 NULL, -- Added: SQL Server 2022
    is_dropped_ledger_table             bit                 NULL, -- Added: SQL Server 2022

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__tables__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
    INDEX IX__tables__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._tables_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

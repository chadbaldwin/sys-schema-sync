CREATE TABLE dbo._computed_columns (
    _DatabaseID                         int             NOT NULL CONSTRAINT FK__computed_columns__DatabaseID    REFERENCES dbo.[Database]   (_DatabaseID),
    _ObjectID                           int             NOT NULL CONSTRAINT FK__computed_columns__ObjectID      REFERENCES dbo.[Object]     (_ObjectID),
    _ColumnID                           int             NOT NULL CONSTRAINT FK__computed_columns__ColumnID      REFERENCES dbo.[Column]     (_ColumnID),
    _InsertDate                         datetime2       NOT NULL CONSTRAINT DF__computed_columns__InsertDate    DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                         datetime2       NOT NULL CONSTRAINT DF__computed_columns__ModifyDate    DEFAULT (SYSUTCDATETIME()),
    _RowHash                            binary(32)      NOT NULL,
    _ValidFrom                          datetime2       GENERATED ALWAYS AS ROW START   NOT NULL,
    _ValidTo                            datetime2       GENERATED ALWAYS AS ROW END     NOT NULL,
    --
    [object_id]                         int             NOT NULL,
    [name]                              nvarchar(128)       NULL,
    column_id                           int             NOT NULL,
    system_type_id                      tinyint         NOT NULL,
    user_type_id                        int             NOT NULL,
    max_length                          smallint        NOT NULL,
    [precision]                         tinyint         NOT NULL,
    scale                               tinyint         NOT NULL,
    collation_name                      nvarchar(128)       NULL,
    is_nullable                         bit                 NULL,
    is_ansi_padded                      bit             NOT NULL,
    is_rowguidcol                       bit             NOT NULL,
    is_identity                         bit             NOT NULL,
    is_filestream                       bit             NOT NULL,
    is_replicated                       bit                 NULL,
    is_non_sql_subscribed               bit                 NULL,
    is_merge_published                  bit                 NULL,
    is_dts_replicated                   bit                 NULL,
    is_xml_document                     bit             NOT NULL,
    xml_collection_id                   int             NOT NULL,
    default_object_id                   int             NOT NULL,
    rule_object_id                      int             NOT NULL,
    [definition]                        nvarchar(MAX)       NULL,
    uses_database_collation             bit             NOT NULL,
    is_persisted                        bit             NOT NULL,
    is_computed                         bit                 NULL,
    is_sparse                           bit             NOT NULL,
    is_column_set                       bit             NOT NULL,
    generated_always_type               tinyint             NULL,
    generated_always_type_desc          nvarchar(60)        NULL,
    [encryption_type]                   int                 NULL,
    encryption_type_desc                nvarchar(64)        NULL,
    encryption_algorithm_name           nvarchar(128)       NULL,
    column_encryption_key_id            int                 NULL,
    column_encryption_key_database_name nvarchar(128)       NULL,
    is_hidden                           bit             NOT NULL,
    is_masked                           bit             NOT NULL,
    graph_type                          int                 NULL,
    graph_type_desc                     nvarchar(60)        NULL,
    is_data_deletion_filter_column      bit                 NULL, -- Added: SQL Server 2022
    ledger_view_column_type             int                 NULL, -- Added: SQL Server 2022
    ledger_view_column_type_desc        nvarchar(60)        NULL, -- Added: SQL Server 2022
    is_dropped_ledger_column            bit                 NULL, -- Added: SQL Server 2022

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__computed_columns__ColumnID PRIMARY KEY CLUSTERED (_ColumnID),
    INDEX IX__computed_columns__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._computed_columns_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

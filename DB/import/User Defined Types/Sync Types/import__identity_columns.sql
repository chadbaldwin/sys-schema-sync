CREATE TYPE import.import__identity_columns AS TABLE (
    _SchemaName                         nvarchar(128)   NOT NULL,
    _ObjectName                         nvarchar(128)   NOT NULL,
    _ObjectType                         char(2)         NOT NULL,
    _ColumnName                         nvarchar(128)   NOT NULL,
    _RowHash                            binary(32)      NOT NULL,
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
    seed_value                          bigint              NULL, -- Deviation: sql_variant
    increment_value                     bigint              NULL, -- Deviation: sql_variant
    last_value                          bigint              NULL, -- Deviation: sql_variant
    is_not_for_replication              bit                 NULL,
    is_computed                         bit             NOT NULL,
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

    INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _ColumnName)
);

CREATE TABLE dbo._indexes (
    _DatabaseID                   int           NOT NULL CONSTRAINT FK__indexes__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__indexes__DatabaseID,
    _ObjectID                     bigint        NOT NULL CONSTRAINT FK__indexes__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__indexes__ObjectID,
    _IndexID                      bigint        NOT NULL CONSTRAINT FK__indexes__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__indexes__IndexID,
    --
    _InsertDate                   datetime2     NOT NULL CONSTRAINT DF__indexes__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                   datetime2     NOT NULL CONSTRAINT DF__indexes__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash                      binary(32)    NOT NULL,
    _ValidFrom                    datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                      datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [object_id]                   int           NOT NULL,
    [name]                        nvarchar(128)     NULL,
    index_id                      int           NOT NULL,
    [type]                        tinyint       NOT NULL,
    [type_desc]                   nvarchar(60)      NULL,
    is_unique                     bit               NULL,
    data_space_id                 int               NULL,
    [ignore_dup_key]              bit               NULL,
    is_primary_key                bit               NULL,
    is_unique_constraint          bit               NULL,
    fill_factor                   tinyint       NOT NULL,
    is_padded                     bit               NULL,
    is_disabled                   bit               NULL,
    is_hypothetical               bit               NULL,
    is_ignored_in_optimization    bit               NULL,
    [allow_row_locks]             bit               NULL,
    [allow_page_locks]            bit               NULL,
    has_filter                    bit               NULL,
    filter_definition             nvarchar(MAX)     NULL,
    [compression_delay]           int               NULL,
    suppress_dup_key_messages     bit               NULL,
    auto_created                  bit               NULL,
    [optimize_for_sequential_key] bit               NULL, -- Added: SQL Server 2019

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__indexes__DatabaseID__IndexID PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID),
    CONSTRAINT UQ__indexes__ObjectID_name UNIQUE (_ObjectID, [name]),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._indexes_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

-- Temporal history table
CREATE TABLE dbo._indexes_history (
    _DatabaseID                   int           NOT NULL,
    _ObjectID                     bigint        NOT NULL,
    _IndexID                      bigint        NOT NULL,
    --
    _InsertDate                   datetime2     NOT NULL,
    _ModifyDate                   datetime2     NOT NULL,
    _RowHash                      binary(32)    NOT NULL,
    _ValidFrom                    datetime2     NOT NULL,
    _ValidTo                      datetime2     NOT NULL,
    --
    [object_id]                   int           NOT NULL,
    [name]                        nvarchar(128)     NULL,
    index_id                      int           NOT NULL,
    [type]                        tinyint       NOT NULL,
    [type_desc]                   nvarchar(60)      NULL,
    is_unique                     bit               NULL,
    data_space_id                 int               NULL,
    [ignore_dup_key]              bit               NULL,
    is_primary_key                bit               NULL,
    is_unique_constraint          bit               NULL,
    fill_factor                   tinyint       NOT NULL,
    is_padded                     bit               NULL,
    is_disabled                   bit               NULL,
    is_hypothetical               bit               NULL,
    is_ignored_in_optimization    bit               NULL,
    [allow_row_locks]             bit               NULL,
    [allow_page_locks]            bit               NULL,
    has_filter                    bit               NULL,
    filter_definition             nvarchar(MAX)     NULL,
    [compression_delay]           int               NULL,
    suppress_dup_key_messages     bit               NULL,
    auto_created                  bit               NULL,
    [optimize_for_sequential_key] bit               NULL, -- Added: SQL Server 2019

    INDEX CIX__indexes_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO
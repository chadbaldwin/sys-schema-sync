CREATE TABLE dbo._dm_db_stats_properties (
    _DatabaseID              int        NOT NULL CONSTRAINT FK__dm_db_stats_properties__DatabaseID   REFERENCES dbo.[Database]   (_DatabaseID) ON DELETE CASCADE,
    _ObjectID                bigint     NOT NULL CONSTRAINT FK__dm_db_stats_properties__ObjectID     REFERENCES dbo.[Object]     (_ObjectID),
    _IndexID                 bigint     NOT NULL CONSTRAINT FK__dm_db_stats_properties__IndexID      REFERENCES dbo.[Index]      (_IndexID),
    --
    _InsertDate              datetime2  NOT NULL CONSTRAINT DF__dm_db_stats_properties__InsertDate   DEFAULT (SYSUTCDATETIME()),
    _ModifyDate              datetime2  NOT NULL CONSTRAINT DF__dm_db_stats_properties__ModifyDate   DEFAULT (SYSUTCDATETIME()),
    _RowHash                 binary(32) NOT NULL,
    --
    [object_id]              int        NOT NULL,
    stats_id                 int        NOT NULL,
    last_updated             datetime2      NULL,
    [rows]                   bigint         NULL,
    rows_sampled             bigint         NULL,
    steps                    int            NULL,
    unfiltered_rows          bigint         NULL,
    modification_counter     bigint         NULL,
    persisted_sample_percent float          NULL,

    CONSTRAINT CPK__dm_db_stats_properties__IndexID PRIMARY KEY CLUSTERED (_IndexID),
    INDEX IX__dm_db_stats_properties__DatabaseID NONCLUSTERED (_DatabaseID),
    INDEX IX__dm_db_stats_properties__ObjectID NONCLUSTERED (_ObjectID),
);
GO
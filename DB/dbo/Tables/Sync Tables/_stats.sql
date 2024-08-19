CREATE TABLE dbo._stats (
    _DatabaseID                     int             NOT NULL CONSTRAINT FK__stats__DatabaseID   REFERENCES dbo.[Database]   (DatabaseID),
    _ObjectID                       int             NOT NULL CONSTRAINT FK__stats__ObjectID     REFERENCES dbo.[Object]     (ObjectID),
    _IndexID                        int             NOT NULL CONSTRAINT FK__stats__IndexID      REFERENCES dbo.[Index]      (IndexID),
    _InsertDate                     datetime2       NOT NULL CONSTRAINT DF__stats__InsertDate   DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                     datetime2       NOT NULL CONSTRAINT DF__stats__ModifyDate   DEFAULT (SYSUTCDATETIME()),
    _RowHash                        binary(32)      NOT NULL,
    --
    [object_id]                     int             NOT NULL,
    [name]                          nvarchar(128)       NULL,
    stats_id                        int             NOT NULL,
    auto_created                    bit                 NULL,
    user_created                    bit                 NULL,
    no_recompute                    bit                 NULL,
    has_filter                      bit                 NULL,
    filter_definition               nvarchar(MAX)       NULL,
    is_temporary                    bit                 NULL,
    is_incremental                  bit                 NULL,
    has_persisted_sample            bit                 NULL, -- Added: SQL Server 2019
    stats_generation_method         int                 NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL
    stats_generation_method_desc    varchar(80)         NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL
    auto_drop                       bit                 NULL, -- Added: SQL Server 2022

    CONSTRAINT CPK__stats__IndexID PRIMARY KEY CLUSTERED (_IndexID),
    INDEX IX__stats__DatabaseID NONCLUSTERED (_DatabaseID),
);
GO

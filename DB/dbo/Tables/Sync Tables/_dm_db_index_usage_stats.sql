CREATE TABLE dbo._dm_db_index_usage_stats (
    _DatabaseID             int        NOT NULL CONSTRAINT FK__dm_db_index_usage_stats__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_usage_stats__DatabaseID,
    _IndexID                bigint     NOT NULL CONSTRAINT FK__dm_db_index_usage_stats__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_usage_stats__IndexID,
    --
    EstimatedStatsBeginTime datetime2  NOT NULL,
    StatsEndTime            datetime2  NOT NULL,
    --
    database_id             smallint       NULL,
    [object_id]             int            NULL,
    index_id                int            NULL,
    user_seeks              bigint     NOT NULL,
    user_scans              bigint     NOT NULL,
    user_lookups            bigint     NOT NULL,
    user_updates            bigint     NOT NULL,
    last_user_seek_utc      datetime       NULL,
    last_user_scan_utc      datetime       NULL,
    last_user_lookup_utc    datetime       NULL,
    last_user_update_utc    datetime       NULL,
    system_seeks            bigint     NOT NULL,
    system_scans            bigint     NOT NULL,
    system_lookups          bigint     NOT NULL,
    system_updates          bigint     NOT NULL,
    last_system_seek_utc    datetime       NULL,
    last_system_scan_utc    datetime       NULL,
    last_system_lookup_utc  datetime       NULL,
    last_system_update_utc  datetime       NULL,

    CONSTRAINT CPK__dm_db_index_usage_stats__DatabaseID__IndexID PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID) WITH (DATA_COMPRESSION = PAGE),
);
GO
CREATE TABLE dw._dm_db_index_usage_stats_delta (
    _DatabaseID             int        NOT NULL CONSTRAINT FK__dm_db_index_usage_stats_delta__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_usage_stats_delta__DatabaseID,
    _IndexID                bigint     NOT NULL CONSTRAINT FK__dm_db_index_usage_stats_delta__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_usage_stats_delta__IndexID,
    --
    EstimatedStatsBeginTime datetime2  NOT NULL,
    StatsEndTime            datetime2  NOT NULL,
    StatsAgeMS              bigint     NOT NULL,
    WereStatsReset          bit        NOT NULL,
    --
    user_seeks              bigint     NOT NULL,
    user_scans              bigint     NOT NULL,
    user_lookups            bigint     NOT NULL,
    user_updates            bigint     NOT NULL,
    user_reads              bigint     NOT NULL,
    --
    last_user_seek_utc      datetime       NULL,
    last_user_scan_utc      datetime       NULL,
    last_user_lookup_utc    datetime       NULL,
    last_user_update_utc    datetime       NULL,
    last_user_read_utc      datetime       NULL,
    --
    system_seeks            bigint     NOT NULL,
    system_scans            bigint     NOT NULL,
    system_lookups          bigint     NOT NULL,
    system_updates          bigint     NOT NULL,
    system_reads            bigint     NOT NULL,
    --
    last_system_seek_utc    datetime       NULL,
    last_system_scan_utc    datetime       NULL,
    last_system_lookup_utc  datetime       NULL,
    last_system_update_utc  datetime       NULL,
    last_system_read_utc    datetime       NULL,

    ValidFrom               datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo                 datetime2(7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT CPK__dm_db_index_usage_stats_delta__DatabaseID__IndexID PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID) WITH (DATA_COMPRESSION = PAGE),
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dw._dm_db_index_usage_stats_delta_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 180 DAYS));
GO

CREATE TABLE dw._dm_db_index_usage_stats_delta_history (
    _DatabaseID             int          NOT NULL,
    _IndexID                bigint       NOT NULL,
    --
    EstimatedStatsBeginTime datetime2    NOT NULL,
    StatsEndTime            datetime2    NOT NULL,
    StatsAgeMS              bigint       NOT NULL,
    WereStatsReset          bit          NOT NULL,
    --
    user_seeks              bigint       NOT NULL,
    user_scans              bigint       NOT NULL,
    user_lookups            bigint       NOT NULL,
    user_updates            bigint       NOT NULL,
    user_reads              bigint       NOT NULL,
    --
    last_user_seek_utc      datetime         NULL,
    last_user_scan_utc      datetime         NULL,
    last_user_lookup_utc    datetime         NULL,
    last_user_update_utc    datetime         NULL,
    last_user_read_utc      datetime         NULL,
    --
    system_seeks            bigint       NOT NULL,
    system_scans            bigint       NOT NULL,
    system_lookups          bigint       NOT NULL,
    system_updates          bigint       NOT NULL,
    system_reads            bigint       NOT NULL,
    --
    last_system_seek_utc    datetime         NULL,
    last_system_scan_utc    datetime         NULL,
    last_system_lookup_utc  datetime         NULL,
    last_system_update_utc  datetime         NULL,
    last_system_read_utc    datetime         NULL,

    ValidFrom               datetime2(7) NOT NULL,
    ValidTo                 datetime2(7) NOT NULL,
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCSIX__dm_db_index_usage_stats_delta_history_ValidTo
    ON dw._dm_db_index_usage_stats_delta_history
    ORDER (ValidTo);
GO
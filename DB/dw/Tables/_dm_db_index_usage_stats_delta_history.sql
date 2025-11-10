CREATE TABLE dw._dm_db_index_usage_stats_delta_history (
    _DatabaseID             int        NOT NULL CONSTRAINT FK__dm_db_index_usage_stats_delta_history__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__dm_db_index_usage_stats_delta_history__DatabaseID,
    _ObjectID               bigint     NOT NULL CONSTRAINT FK__dm_db_index_usage_stats_delta_history__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__dm_db_index_usage_stats_delta_history__ObjectID,
    _IndexID                bigint     NOT NULL CONSTRAINT FK__dm_db_index_usage_stats_delta_history__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__dm_db_index_usage_stats_delta_history__IndexID,
    --
    EstimatedStatsBeginTime datetime2  NOT NULL,
    StatsEndTime            datetime2  NOT NULL,
    StatsAgeMS  	        bigint     NOT NULL,
    WereStatsReset          bit		   NOT NULL,
    --
    user_seeks              bigint     NOT NULL,
    user_scans              bigint     NOT NULL,
    user_lookups            bigint     NOT NULL,
    user_updates            bigint     NOT NULL,
    user_reads 		        bigint     NOT NULL,
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
    system_reads 	        bigint     NOT NULL,
    last_system_seek_utc    datetime       NULL,
    last_system_scan_utc    datetime       NULL,
    last_system_lookup_utc  datetime       NULL,
    last_system_update_utc  datetime       NULL,
    last_system_read_utc    datetime       NULL,

    CONSTRAINT UQ__dm_db_index_usage_stats_delta_history_StatsEndTime__DatabaseID__IndexID UNIQUE (StatsEndTime, _DatabaseID, _IndexID),
    INDEX IX__dm_db_index_usage_stats_delta_history__DatabaseID__IndexID (_DatabaseID, _IndexID)
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCSIX__dm_db_index_usage_stats_delta_history_StatsEndTime__DatabaseID__IndexID
    ON dw._dm_db_index_usage_stats_delta_history
    ORDER (StatsEndTime, _DatabaseID, _IndexID);

GO
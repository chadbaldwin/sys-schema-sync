CREATE TYPE import.import__dm_db_index_usage_stats AS TABLE (
    __ID                    int           NOT NULL,
    _SchemaName             nvarchar(128) NOT NULL,
    _ObjectName             nvarchar(128) NOT NULL,
    _ObjectType             char(2)       NOT NULL,
    _IndexName              nvarchar(128) NOT NULL,
    --
    EstimatedStatsBeginTime datetime2     NOT NULL,
    StatsEndTime            datetime2     NOT NULL,
    InstanceTimeZone        nvarchar(128) NOT NULL,
    --
    database_id             smallint          NULL,
    [object_id]             int               NULL,
    index_id                int               NULL,
    user_seeks              bigint            NULL,
    user_scans              bigint            NULL,
    user_lookups            bigint            NULL,
    user_updates            bigint            NULL,
    last_user_seek          datetime          NULL,
    last_user_scan          datetime          NULL,
    last_user_lookup        datetime          NULL,
    last_user_update        datetime          NULL,
    system_seeks            bigint            NULL,
    system_scans            bigint            NULL,
    system_lookups          bigint            NULL,
    system_updates          bigint            NULL,
    last_system_seek        datetime          NULL,
    last_system_scan        datetime          NULL,
    last_system_lookup      datetime          NULL,
    last_system_update      datetime          NULL,

    -- UTC conversion placeholders
    -- Tried using computed columns here, but it fails when using as a TVP. So instead they act as placeholders to be filled later.
    last_user_seek_utc      datetime          NULL,
    last_user_scan_utc      datetime          NULL,
    last_user_lookup_utc    datetime          NULL,
    last_user_update_utc    datetime          NULL,
    last_system_seek_utc    datetime          NULL,
    last_system_scan_utc    datetime          NULL,
    last_system_lookup_utc  datetime          NULL,
    last_system_update_utc  datetime          NULL,

    INDEX CIX CLUSTERED (__ID)
);
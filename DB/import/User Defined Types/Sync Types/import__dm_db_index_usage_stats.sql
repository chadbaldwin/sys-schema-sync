CREATE TYPE import.import__dm_db_index_usage_stats AS TABLE (
    _SchemaName            nvarchar(128) NOT NULL,
    _ObjectName            nvarchar(128) NOT NULL,
    _ObjectType            char(2)       NOT NULL,
    _IndexName             nvarchar(128) NOT NULL,
    _RowHash               binary(32)    NOT NULL,
    --
    database_id            smallint          NULL,
    [object_id]            int               NULL,
    index_id               int               NULL,
    user_seeks             bigint        NOT NULL,
    user_scans             bigint        NOT NULL,
    user_lookups           bigint        NOT NULL,
    user_updates           bigint        NOT NULL,
    last_user_seek_utc     datetime          NULL,
    last_user_scan_utc     datetime          NULL,
    last_user_lookup_utc   datetime          NULL,
    last_user_update_utc   datetime          NULL,
    system_seeks           bigint        NOT NULL,
    system_scans           bigint        NOT NULL,
    system_lookups         bigint        NOT NULL,
    system_updates         bigint        NOT NULL,
    last_system_seek_utc   datetime          NULL,
    last_system_scan_utc   datetime          NULL,
    last_system_lookup_utc datetime          NULL,
    last_system_update_utc datetime          NULL,

    INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName)
);
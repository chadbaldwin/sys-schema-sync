CREATE TYPE import.import__dm_db_stats_properties AS TABLE (
    _SchemaName              nvarchar(128) NOT NULL,
    _ObjectName              nvarchar(128) NOT NULL,
    _ObjectType              char(2)       NOT NULL,
    _IndexName               nvarchar(128) NOT NULL,
    _RowHash                 binary(32)    NOT NULL,
    --
    [object_id]              int           NOT NULL,
    stats_id                 int           NOT NULL,
    last_updated             datetime2         NULL,
    [rows]                   bigint            NULL,
    rows_sampled             bigint            NULL,
    steps                    int               NULL,
    unfiltered_rows          bigint            NULL,
    modification_counter     bigint            NULL,
    persisted_sample_percent float             NULL,

    INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName)
);
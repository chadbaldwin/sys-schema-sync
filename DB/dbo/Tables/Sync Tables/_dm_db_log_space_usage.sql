CREATE TABLE dbo._dm_db_log_space_usage (
    _DatabaseID                             int         NOT NULL CONSTRAINT FK__dm_db_log_space_usage__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate                         datetime2   NOT NULL,
    --
    database_id                             int             NULL,
    total_log_size_in_bytes                 bigint          NULL,
    used_log_space_in_bytes                 bigint          NULL,
    used_log_space_in_percent               real            NULL,
    log_space_in_bytes_since_last_backup    bigint          NULL,

    INDEX CIX__dm_db_log_space_usage__DatabaseID UNIQUE CLUSTERED (_DatabaseID),
);
GO

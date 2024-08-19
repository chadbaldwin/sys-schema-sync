CREATE TYPE import.import__dm_os_wait_stats AS TABLE (
    _CollectionDate     datetime2       NOT NULL,
    --
    wait_type           nvarchar(60)    NOT NULL,
    waiting_tasks_count bigint          NOT NULL,
    wait_time_ms        bigint          NOT NULL,
    max_wait_time_ms    bigint          NOT NULL,
    signal_wait_time_ms bigint          NOT NULL,

    INDEX CIX UNIQUE CLUSTERED (wait_type)
);

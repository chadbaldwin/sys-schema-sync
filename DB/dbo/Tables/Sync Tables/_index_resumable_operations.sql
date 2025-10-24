CREATE TABLE dbo._index_resumable_operations (
    _DatabaseID          int           NOT NULL CONSTRAINT FK__index_resumable_operations__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate      datetime2     NOT NULL,
    --
    [object_id]          int           NOT NULL,
    index_id             int           NOT NULL,
    [name]               nvarchar(128) NOT NULL,
    sql_text             nvarchar(MAX)     NULL,
    last_max_dop_used    smallint      NOT NULL,
    partition_number     int               NULL,
    [state]              tinyint       NOT NULL,
    state_desc           nvarchar(60)      NULL,
    start_time           datetime      NOT NULL,
    last_pause_time      datetime          NULL,
    total_execution_time int           NOT NULL,
    percent_complete     float         NOT NULL,
    page_count           bigint        NOT NULL,

    INDEX CIX__index_resumable_operations__DatabaseID_object_id_index_id UNIQUE CLUSTERED (_DatabaseID, [object_id], index_id),
);
GO
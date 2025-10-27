CREATE TABLE dbo._dm_db_partition_stats (
    _DatabaseID                      int         NOT NULL CONSTRAINT FK__dm_db_partition_stats__DatabaseID   REFERENCES dbo.[Database]   (_DatabaseID) ON DELETE CASCADE,
    _ObjectID                        bigint      NOT NULL CONSTRAINT FK__dm_db_partition_stats__ObjectID     REFERENCES dbo.[Object]     (_ObjectID),
    _IndexID                         bigint      NOT NULL CONSTRAINT FK__dm_db_partition_stats__IndexID      REFERENCES dbo.[Index]      (_IndexID),
    --
    _InsertDate                      datetime2   NOT NULL CONSTRAINT DF__dm_db_partition_stats__InsertDate   DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                      datetime2   NOT NULL CONSTRAINT DF__dm_db_partition_stats__ModifyDate   DEFAULT (SYSUTCDATETIME()),
    _RowHash                         binary(32)  NOT NULL,
    --
    [partition_id]                   bigint          NULL,
    [object_id]                      int         NOT NULL,
    index_id                         int         NOT NULL,
    partition_number                 int         NOT NULL,
    in_row_data_page_count           bigint          NULL,
    in_row_used_page_count           bigint          NULL,
    in_row_reserved_page_count       bigint          NULL,
    lob_used_page_count              bigint          NULL,
    lob_reserved_page_count          bigint          NULL,
    row_overflow_used_page_count     bigint          NULL,
    row_overflow_reserved_page_count bigint          NULL,
    used_page_count                  bigint          NULL,
    reserved_page_count              bigint          NULL,
    row_count                        bigint          NULL,

    INDEX CIX__dm_db_partition_stats__IndexID_partition_number UNIQUE CLUSTERED (_IndexID, partition_number),
    INDEX IX__dm_db_partition_stats__ObjectID NONCLUSTERED (_ObjectID),
    INDEX IX__dm_db_partition_stats__IndexID NONCLUSTERED (_IndexID),
);
GO

CREATE NONCLUSTERED INDEX IX__dm_db_partition_stats__DatabaseID ON dbo._dm_db_partition_stats (_DatabaseID) INCLUDE (_ObjectID, partition_number);
GO
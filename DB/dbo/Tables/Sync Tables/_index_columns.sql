CREATE TABLE dbo._index_columns (
    _DatabaseID                int        NOT NULL CONSTRAINT FK__index_columns__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__index_columns__DatabaseID,
    _ObjectID                  bigint     NOT NULL CONSTRAINT FK__index_columns__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__index_columns__ObjectID,
    _IndexID                   bigint     NOT NULL CONSTRAINT FK__index_columns__IndexID    REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__index_columns__IndexID,
    _ColumnID                  bigint     NOT NULL CONSTRAINT FK__index_columns__ColumnID   REFERENCES dbo.[Column]   (_ColumnID)   INDEX IX__index_columns__ColumnID,
    --
    _InsertDate                datetime2  NOT NULL CONSTRAINT DF__index_columns__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                datetime2  NOT NULL CONSTRAINT DF__index_columns__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash                   binary(32) NOT NULL,
    _ValidFrom                 datetime2  GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                   datetime2  GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [object_id]                int        NOT NULL,
    index_id                   int        NOT NULL,
    index_column_id            int        NOT NULL,
    column_id                  int        NOT NULL,
    key_ordinal                tinyint    NOT NULL,
    partition_ordinal          tinyint    NOT NULL,
    is_descending_key          bit            NULL,
    is_included_column         bit            NULL,
    column_store_order_ordinal tinyint        NULL, -- Added: SQL Server 2019
    data_clustering_ordinal    tinyint        NULL, -- Added: SQL Server 2025

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__index_columns__DatabaseID__IndexID__ColumnID PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID, _ColumnID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._index_columns_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
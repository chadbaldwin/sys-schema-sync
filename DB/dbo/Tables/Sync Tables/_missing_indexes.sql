CREATE TABLE dbo._missing_indexes (
    _DatabaseID         int            NOT NULL CONSTRAINT FK__missing_indexes__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__missing_indexes__DatabaseID,
    _ObjectID           bigint         NOT NULL CONSTRAINT FK__missing_indexes__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__missing_indexes__ObjectID,
    --
    _InsertDate         datetime2      NOT NULL CONSTRAINT DF__missing_indexes__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate         datetime2      NOT NULL CONSTRAINT DF__missing_indexes__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash            binary(32)     NOT NULL,
    --
    missing_index_hash  binary(32)     NOT NULL,
    unique_compiles     bigint         NOT NULL,
    user_seeks          bigint         NOT NULL,
    user_scans          bigint         NOT NULL,
    last_user_seek_utc  datetime2(7)       NULL,
    last_user_scan_utc  datetime2(7)       NULL,
    avg_total_user_cost float          NOT NULL,
    avg_user_impact     float          NOT NULL,
    equality_columns    nvarchar(4000)     NULL,
    inequality_columns  nvarchar(4000)     NULL,
    included_columns    nvarchar(4000)     NULL,
    column_data         nvarchar(MAX)  NOT NULL,

    CONSTRAINT CUQ__missing_indexes__DatabaseID__ObjectID_missing_index_hash UNIQUE CLUSTERED (_DatabaseID, _ObjectID, missing_index_hash),
    INDEX IX__missing_indexes__DatabaseID__ModifyDate NONCLUSTERED (_DatabaseID, _ModifyDate),
);
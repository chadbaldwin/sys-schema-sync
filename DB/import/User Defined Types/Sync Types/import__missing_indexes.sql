CREATE TYPE import.import__missing_indexes AS TABLE (
    __ID                int            NOT NULL,
    _SchemaName         nvarchar(128)  NOT NULL,
    _ObjectName         nvarchar(128)  NOT NULL,
    _ObjectType         char(2)        NOT NULL,
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
    column_data         nvarchar(MAX)  NOT NULL
);
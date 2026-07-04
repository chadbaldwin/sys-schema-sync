CREATE TABLE ext.IndexColumnsSquash (
    _DatabaseID int            NOT NULL,
    _IndexID    bigint         NOT NULL,
    KeyColsN    nvarchar(4000) NOT NULL,
    KeyColsNQ   nvarchar(4000) NOT NULL,
    KeyColsNQO  nvarchar(4000) NOT NULL,
    InclColsNQ  nvarchar(4000)     NULL,

    CONSTRAINT CPK_IndexColumnsSquash__DatabaseID__IndexID PRIMARY KEY CLUSTERED (_DatabaseID, _IndexID) WITH (DATA_COMPRESSION = PAGE)
);
GO
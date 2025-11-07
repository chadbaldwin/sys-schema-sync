CREATE TABLE dbo._data_spaces (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__data_spaces__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by CIX
    _CollectionDate datetime2     NOT NULL,
    --
    [name]          nvarchar(128) NOT NULL,
    data_space_id   int           NOT NULL,
    [type]          char(2)       NOT NULL,
    [type_desc]     nvarchar(60)      NULL,
    is_default      bit           NOT NULL,
    is_system       bit               NULL,

    CONSTRAINT CUQ__data_spaces__DatabaseID_data_space_id UNIQUE CLUSTERED (_DatabaseID, data_space_id),
);
GO
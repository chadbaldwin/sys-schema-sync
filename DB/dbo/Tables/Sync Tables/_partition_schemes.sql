CREATE TABLE dbo._partition_schemes (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__partition_schemes__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate datetime2     NOT NULL,
    --
    [name]          nvarchar(128) NOT NULL,
    data_space_id   int           NOT NULL,
    [type]          char(2)       NOT NULL,
    [type_desc]     nvarchar(60)      NULL,
    is_default      bit               NULL,
    is_system       bit               NULL,
    function_id     int           NOT NULL,

    INDEX CIX__partition_schemes__DatabaseID_data_space_id UNIQUE CLUSTERED (_DatabaseID, data_space_id),
);
GO
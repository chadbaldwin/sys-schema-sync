CREATE TABLE dbo._destination_data_spaces (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__destination_data_spaces__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate datetime2     NOT NULL,
    --
    partition_scheme_id int NOT NULL,
    destination_id      int NOT NULL,
    data_space_id       int NOT NULL,

    INDEX CIX__destination_data_spaces__DatabaseID_partition_scheme_id_destination_id UNIQUE CLUSTERED (_DatabaseID, partition_scheme_id, destination_id),
);
GO
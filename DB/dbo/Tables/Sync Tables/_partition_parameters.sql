CREATE TABLE dbo._partition_parameters (
    _DatabaseID     int           NOT NULL CONSTRAINT FK__partition_parameters__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) ON DELETE CASCADE,
    _CollectionDate datetime2     NOT NULL,
    --
    function_id     int           NOT NULL,
    parameter_id    int           NOT NULL,
    system_type_id  tinyint       NOT NULL,
    max_length      smallint      NOT NULL,
    [precision]     tinyint       NOT NULL,
    scale           tinyint       NOT NULL,
    collation_name  nvarchar(128)     NULL,
    user_type_id    int           NOT NULL,

    INDEX CIX__partition_parameters__DatabaseID_function_id_parameter_id UNIQUE CLUSTERED (_DatabaseID, function_id, parameter_id),
);
GO
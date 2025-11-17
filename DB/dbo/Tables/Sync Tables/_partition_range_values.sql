CREATE TABLE dbo._partition_range_values (
    _DatabaseID     int         NOT NULL CONSTRAINT FK__partition_range_values__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by CIX
    _CollectionDate datetime2   NOT NULL,
    --
    function_id     int         NOT NULL,
    boundary_id     int         NOT NULL,
    parameter_id    int         NOT NULL,
    [value]         sql_variant     NULL, -- TODO: Convert to portable string format since that's what we will use in the rest of the DB

    CONSTRAINT CUQ__partition_range_values__DatabaseID_function_id_boundary_id_parameter_id UNIQUE CLUSTERED (_DatabaseID, function_id, boundary_id, parameter_id),
);
GO
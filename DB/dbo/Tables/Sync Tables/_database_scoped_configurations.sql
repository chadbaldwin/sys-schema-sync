CREATE TABLE dbo._database_scoped_configurations (
    _DatabaseID         int          NOT NULL CONSTRAINT FK__database_scoped_configurations__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by CIX
    _CollectionDate     datetime2    NOT NULL,
    --
    configuration_id    int              NULL,
    [name]              nvarchar(60)     NULL,
    [value]             sql_variant      NULL,
    value_for_secondary sql_variant      NULL,
    is_value_default    bit              NULL,

    CONSTRAINT CUQ__database_scoped_configurations__DatabaseID_configuration_id UNIQUE CLUSTERED (_DatabaseID, configuration_id),
);
GO
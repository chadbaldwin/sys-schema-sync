CREATE TABLE dbo._database_scoped_configurations (
    _DatabaseID         int             NOT NULL CONSTRAINT FK__database_scoped_configurations__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate     datetime2       NOT NULL,
    --
    configuration_id    int                 NULL,
    [name]              nvarchar(60)        NULL,
    [value]             sql_variant         NULL,
    value_for_secondary sql_variant         NULL,
    is_value_default    bit                 NULL,

    INDEX CIX__database_scoped_configurations__DatabaseID CLUSTERED (_DatabaseID),
);
GO

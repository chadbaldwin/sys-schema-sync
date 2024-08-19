CREATE TABLE dbo._configurations_history (
    _InstanceID         int             NOT NULL,
    _InsertDate         datetime2       NOT NULL,
    _ModifyDate         datetime2       NOT NULL,
    _RowHash            binary(32)      NOT NULL,
    _ValidFrom          datetime2       NOT NULL,
    _ValidTo            datetime2       NOT NULL,
    --
    configuration_id    int             NOT NULL,
    [name]              nvarchar(35)    NOT NULL,
    [value]             int                 NULL, -- Deviation: sql_variant
    minimum             int                 NULL, -- Deviation: sql_variant
    maximum             int                 NULL, -- Deviation: sql_variant
    value_in_use        int                 NULL, -- Deviation: sql_variant
    [description]       nvarchar(255)   NOT NULL,
    is_dynamic          bit             NOT NULL,
    is_advanced         bit             NOT NULL,

    INDEX CIX__configurations_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

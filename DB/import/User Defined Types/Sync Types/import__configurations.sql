CREATE TYPE import.import__configurations AS TABLE (
    _RowHash            binary(32)      NOT NULL,
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

    INDEX CIX UNIQUE CLUSTERED (configuration_id)
);

CREATE TYPE import.import__database_automatic_tuning_options AS TABLE (
    _RowHash            binary(32)      NOT NULL,
    --
    [name]              nvarchar(128)   NOT NULL, -- Deviation: NULL - Made NOT NULL in order to include in PK constraint
    [desired_state]     smallint            NULL,
    desired_state_desc  nvarchar(60)        NULL,
    actual_state        smallint            NULL,
    actual_state_desc   nvarchar(60)        NULL,
    reason              smallint            NULL,
    reason_desc         nvarchar(60)        NULL,

    INDEX CIX UNIQUE CLUSTERED ([name])
);
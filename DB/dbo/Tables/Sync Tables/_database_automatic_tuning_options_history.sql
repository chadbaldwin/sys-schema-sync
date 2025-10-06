CREATE TABLE dbo._database_automatic_tuning_options_history (
    _DatabaseID        int           NOT NULL,
    --
    _InsertDate        datetime2     NOT NULL,
    _ModifyDate        datetime2     NOT NULL,
    _RowHash           binary(32)    NOT NULL,
    _ValidFrom         datetime2     NOT NULL,
    _ValidTo           datetime2     NOT NULL,
    --
    [name]             nvarchar(128) NOT NULL, -- Deviation: NULL - Made NOT NULL in order to include in PK constraint
    [desired_state]    smallint          NULL,
    desired_state_desc nvarchar(60)      NULL,
    actual_state       smallint          NULL,
    actual_state_desc  nvarchar(60)      NULL,
    reason             smallint          NULL,
    reason_desc        nvarchar(60)      NULL,

    INDEX CIX__database_automatic_tuning_options_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO
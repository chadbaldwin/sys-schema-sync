CREATE TABLE dbo._database_automatic_tuning_options (
    _DatabaseID         int             NOT NULL CONSTRAINT FK__database_automatic_tuning_options__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _InsertDate         datetime2       NOT NULL CONSTRAINT DF__database_automatic_tuning_options__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate         datetime2       NOT NULL CONSTRAINT DF__database_automatic_tuning_options__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash            binary(32)      NOT NULL,
    _ValidFrom          datetime2       GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo            datetime2       GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [name]              nvarchar(128)   NOT NULL, -- Deviation: NULL - Made NOT NULL in order to include in PK constraint
    [desired_state]     smallint            NULL,
    desired_state_desc  nvarchar(60)        NULL,
    actual_state        smallint            NULL,
    actual_state_desc   nvarchar(60)        NULL,
    reason              smallint            NULL,
    reason_desc         nvarchar(60)        NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__database_automatic_tuning_options__DatabaseID_name PRIMARY KEY CLUSTERED (_DatabaseID, [name]),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._database_automatic_tuning_options_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

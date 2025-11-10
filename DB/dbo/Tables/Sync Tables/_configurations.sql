CREATE TABLE dbo._configurations (
    _InstanceID      int           NOT NULL CONSTRAINT FK__configurations__InstanceID REFERENCES dbo.Instance (_InstanceID), -- Covered by CIX
    --
    _InsertDate      datetime2     NOT NULL CONSTRAINT DF__configurations__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate      datetime2     NOT NULL CONSTRAINT DF__configurations__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash         binary(32)    NOT NULL,
    _ValidFrom       datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo         datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    configuration_id int           NOT NULL,
    [name]           nvarchar(35)  NOT NULL,
    [value]          int               NULL, -- Deviation: Original data type: sql_variant
    minimum          int               NULL, -- Deviation: Original data type: sql_variant
    maximum          int               NULL, -- Deviation: Original data type: sql_variant
    value_in_use     int               NULL, -- Deviation: Original data type: sql_variant
    [description]    nvarchar(255) NOT NULL,
    is_dynamic       bit           NOT NULL,
    is_advanced      bit           NOT NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__configurations__InstanceID_configuration_id PRIMARY KEY CLUSTERED (_InstanceID, configuration_id),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._configurations_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

-- Temporal history table
CREATE TABLE dbo._configurations_history (
    _InstanceID      int           NOT NULL,
    --
    _InsertDate      datetime2     NOT NULL,
    _ModifyDate      datetime2     NOT NULL,
    _RowHash         binary(32)    NOT NULL,
    _ValidFrom       datetime2     NOT NULL,
    _ValidTo         datetime2     NOT NULL,
    --
    configuration_id int           NOT NULL,
    [name]           nvarchar(35)  NOT NULL,
    [value]          int               NULL, -- Deviation: Original data type: sql_variant
    minimum          int               NULL, -- Deviation: Original data type: sql_variant
    maximum          int               NULL, -- Deviation: Original data type: sql_variant
    value_in_use     int               NULL, -- Deviation: Original data type: sql_variant
    [description]    nvarchar(255) NOT NULL,
    is_dynamic       bit           NOT NULL,
    is_advanced      bit           NOT NULL,

    INDEX CIX__configurations_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO
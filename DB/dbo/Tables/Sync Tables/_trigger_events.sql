-- Temporal history table
CREATE TABLE dbo._trigger_events_history (
    _DatabaseID           int           NOT NULL,
    _ObjectID             bigint        NOT NULL,
    --
    _InsertDate           datetime2     NOT NULL,
    _ModifyDate           datetime2     NOT NULL,
    _RowHash              binary(32)    NOT NULL,
    _ValidFrom            datetime2     NOT NULL,
    _ValidTo              datetime2     NOT NULL,
    --
    [object_id]           int           NOT NULL,
    [type]                int           NOT NULL,
    [type_desc]           nvarchar(128) NOT NULL,
    is_first              bit               NULL,
    is_last               bit               NULL,
    event_group_type      int               NULL,
    event_group_type_desc nvarchar(128)     NULL,
    is_trigger_event      bit               NULL,

    INDEX CIX__trigger_events_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

CREATE TABLE dbo._trigger_events (
    _DatabaseID           int           NOT NULL CONSTRAINT FK__trigger_events__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__trigger_events__DatabaseID,
    _ObjectID             bigint        NOT NULL CONSTRAINT FK__trigger_events__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__trigger_events__ObjectID,
    --
    _InsertDate           datetime2     NOT NULL CONSTRAINT DF__trigger_events__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate           datetime2     NOT NULL CONSTRAINT DF__trigger_events__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash              binary(32)    NOT NULL,
    _ValidFrom            datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo              datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [object_id]           int           NOT NULL,
    [type]                int           NOT NULL,
    [type_desc]           nvarchar(128) NOT NULL,
    is_first              bit               NULL,
    is_last               bit               NULL,
    event_group_type      int               NULL,
    event_group_type_desc nvarchar(128)     NULL,
    is_trigger_event      bit               NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__trigger_events__DatabaseID__ObjectID_type PRIMARY KEY CLUSTERED (_DatabaseID, _ObjectID, [type]),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._trigger_events_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
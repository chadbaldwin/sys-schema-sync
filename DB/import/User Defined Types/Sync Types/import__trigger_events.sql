CREATE TYPE import.import__trigger_events AS TABLE (
    __ID                  int           NOT NULL,
    _SchemaName           nvarchar(128) NOT NULL,
    _ObjectName           nvarchar(128) NOT NULL,
    _ObjectType           char(2)       NOT NULL,
    _RowHash              binary(32)    NOT NULL,
    --
    [object_id]           int           NOT NULL,
    [type]                int           NOT NULL,
    [type_desc]           nvarchar(128) NOT NULL,
    is_first              bit               NULL,
    is_last               bit               NULL,
    event_group_type      int               NULL,
    event_group_type_desc nvarchar(128)     NULL,
    is_trigger_event      bit               NULL,

    INDEX CIX CLUSTERED (__ID)
);
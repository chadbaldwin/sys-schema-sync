CREATE TABLE dbo._objects_history (
    _DatabaseID         int             NOT NULL,
    _ObjectID           int             NOT NULL,
    _InsertDate         datetime2       NOT NULL,
    _ModifyDate         datetime2       NOT NULL,
    _RowHash            binary(32)      NOT NULL,
    _SchemaName         nvarchar(128)   NOT NULL,
    _ValidFrom          datetime2       NOT NULL,
    _ValidTo            datetime2       NOT NULL,
    --
    [name]              nvarchar(128)   NOT NULL,
    [object_id]         int             NOT NULL,
    principal_id        int                 NULL,
    [schema_id]         int             NOT NULL,
    parent_object_id    int             NOT NULL,
    [type]              char(2)             NULL,
    [type_desc]         nvarchar(60)        NULL,
    create_date         datetime        NOT NULL,
    is_ms_shipped       bit             NOT NULL,
    is_published        bit             NOT NULL,
    is_schema_published bit             NOT NULL,

    INDEX CIX__objects_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);

CREATE TYPE import.import__key_constraints AS TABLE (
    _SchemaName         nvarchar(128)   NOT NULL,
    _ObjectName         nvarchar(128)   NOT NULL,
    _ObjectType         char(2)         NOT NULL,
    _ParentObjectName   nvarchar(128)       NULL,
    _ParentObjectType   char(2)             NULL,
    _UniqueIndexName    nvarchar(128)   NOT NULL,
    _RowHash            binary(32)      NOT NULL,
    --
    [name]              nvarchar(128)   NOT NULL,
    [object_id]         int             NOT NULL,
    principal_id        int                 NULL,
    [schema_id]         int             NOT NULL,
    parent_object_id    int             NOT NULL,
    [type]              char(2)             NULL,
    [type_desc]         nvarchar(60)        NULL,
    create_date         datetime        NOT NULL,
    modify_date         datetime        NOT NULL,
    is_ms_shipped       bit             NOT NULL,
    is_published        bit             NOT NULL,
    is_schema_published bit             NOT NULL,
    unique_index_id     int                 NULL,
    is_system_named     bit             NOT NULL,
    is_enforced         bit                 NULL,

    INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType)
);

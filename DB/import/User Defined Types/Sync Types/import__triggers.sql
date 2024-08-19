CREATE TYPE import.import__triggers AS TABLE (
    _SchemaName             nvarchar(128)   NOT NULL,
    _ObjectName             nvarchar(128)   NOT NULL,
    _ObjectType             char(2)         NOT NULL,
    _ParentObjectName       nvarchar(128)       NULL,
    _ParentObjectType       char(2)             NULL,
    _RowHash                binary(32)      NOT NULL,
    --
    [name]                  nvarchar(128)   NOT NULL,
    [object_id]             int             NOT NULL,
    parent_class            tinyint         NOT NULL,
    parent_class_desc       nvarchar(60)        NULL,
    parent_id               int             NOT NULL,
    [type]                  char(2)         NOT NULL,
    [type_desc]             nvarchar(60)        NULL,
    create_date             datetime        NOT NULL,
    modify_date             datetime        NOT NULL,
    is_ms_shipped           bit             NOT NULL,
    is_disabled             bit             NOT NULL,
    is_not_for_replication  bit             NOT NULL,
    is_instead_of_trigger   bit             NOT NULL,

    INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType)
);

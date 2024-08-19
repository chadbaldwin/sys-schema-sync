CREATE TYPE import.import__foreign_key_columns AS TABLE (
    _SchemaName             nvarchar(128)   NOT NULL,
    _ObjectName             nvarchar(128)   NOT NULL,
    _ObjectType             char(2)         NOT NULL,
    _ParentSchemaName       nvarchar(128)   NOT NULL,
    _ParentObjectName       nvarchar(128)   NOT NULL,
    _ParentObjectType       char(2)         NOT NULL,
    _ParentColumnName       nvarchar(128)   NOT NULL,
    _ReferencedSchemaName   nvarchar(128)   NOT NULL,
    _ReferencedObjectName   nvarchar(128)   NOT NULL,
    _ReferencedObjectType   char(2)         NOT NULL,
    _ReferencedColumnName   nvarchar(128)   NOT NULL,
    _RowHash                binary(32)      NOT NULL,
    --
    constraint_object_id    int             NOT NULL,
    constraint_column_id    int             NOT NULL,
    parent_object_id        int             NOT NULL,
    parent_column_id        int             NOT NULL,
    referenced_object_id    int             NOT NULL,
    referenced_column_id    int             NOT NULL,

    INDEX CIX CLUSTERED (_SchemaName, _ObjectName, _ObjectType)
);

CREATE TABLE dbo._check_constraints (
    _DatabaseID             int           NOT NULL CONSTRAINT FK__check_constraints__DatabaseID     REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__check_constraints__DatabaseID,
    _ObjectID               bigint        NOT NULL CONSTRAINT FK__check_constraints__ObjectID       REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__check_constraints__ObjectID,
    _ParentObjectID         bigint        NOT NULL CONSTRAINT FK__check_constraints__ParentObjectID REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__check_constraints__ParentObjectID,
    _ParentColumnID         bigint            NULL CONSTRAINT FK__check_constraints__ParentColumnID REFERENCES dbo.[Column]   (_ColumnID)   INDEX IX__check_constraints__ParentColumnID,
    --
    _InsertDate             datetime2     NOT NULL CONSTRAINT DF__check_constraints__InsertDate     DEFAULT (SYSUTCDATETIME()),
    _ModifyDate             datetime2     NOT NULL CONSTRAINT DF__check_constraints__ModifyDate     DEFAULT (SYSUTCDATETIME()),
    _RowHash                binary(32)    NOT NULL,
    _ValidFrom              datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [name]                  nvarchar(128) NOT NULL,
    [object_id]             int           NOT NULL,
    principal_id            int               NULL,
    [schema_id]             int           NOT NULL,
    parent_object_id        int           NOT NULL,
    [type]                  char(2)           NULL,
    [type_desc]             nvarchar(60)      NULL,
    create_date             datetime      NOT NULL,
    modify_date             datetime      NOT NULL,
    is_ms_shipped           bit           NOT NULL,
    is_published            bit           NOT NULL,
    is_schema_published     bit           NOT NULL,
    is_disabled             bit           NOT NULL,
    is_not_for_replication  bit           NOT NULL,
    is_not_trusted          bit           NOT NULL,
    parent_column_id        int           NOT NULL,
    [definition]            nvarchar(MAX)     NULL,
    uses_database_collation bit               NULL,
    is_system_named         bit           NOT NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__check_constraints__DatabaseID__ObjectID PRIMARY KEY CLUSTERED (_DatabaseID, _ObjectID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._check_constraints_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

-- Temporal history table
CREATE TABLE dbo._check_constraints_history (
    _DatabaseID             int           NOT NULL,
    _ObjectID               bigint        NOT NULL,
    _ParentObjectID         bigint        NOT NULL,
    _ParentColumnID         bigint            NULL,
    --
    _InsertDate             datetime2     NOT NULL,
    _ModifyDate             datetime2     NOT NULL,
    _RowHash                binary(32)    NOT NULL,
    _ValidFrom              datetime2     NOT NULL,
    _ValidTo                datetime2     NOT NULL,
    --
    [name]                  nvarchar(128) NOT NULL,
    [object_id]             int           NOT NULL,
    principal_id            int               NULL,
    [schema_id]             int           NOT NULL,
    parent_object_id        int           NOT NULL,
    [type]                  char(2)           NULL,
    [type_desc]             nvarchar(60)      NULL,
    create_date             datetime      NOT NULL,
    modify_date             datetime      NOT NULL,
    is_ms_shipped           bit           NOT NULL,
    is_published            bit           NOT NULL,
    is_schema_published     bit           NOT NULL,
    is_disabled             bit           NOT NULL,
    is_not_for_replication  bit           NOT NULL,
    is_not_trusted          bit           NOT NULL,
    parent_column_id        int           NOT NULL,
    [definition]            nvarchar(MAX)     NULL,
    uses_database_collation bit               NULL,
    is_system_named         bit           NOT NULL,

    INDEX CIX__check_constraints_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO
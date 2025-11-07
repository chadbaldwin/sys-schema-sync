CREATE TABLE dbo._key_constraints (
    _DatabaseID         int           NOT NULL CONSTRAINT FK__key_constraints__DatabaseID     REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__key_constraints__DatabaseID,
    _ObjectID           bigint        NOT NULL CONSTRAINT FK__key_constraints__ObjectID       REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__key_constraints__ObjectID,
    _IndexID            bigint        NOT NULL CONSTRAINT FK__key_constraints__IndexID        REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__key_constraints__IndexID,
    _ParentObjectID     bigint        NOT NULL CONSTRAINT FK__key_constraints__ParentObjectID REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__key_constraints__ParentObjectID,
    --
    _InsertDate         datetime2     NOT NULL CONSTRAINT DF__key_constraints__InsertDate     DEFAULT (SYSUTCDATETIME()),
    _ModifyDate         datetime2     NOT NULL CONSTRAINT DF__key_constraints__ModifyDate     DEFAULT (SYSUTCDATETIME()),
    _RowHash            binary(32)    NOT NULL,
    _ValidFrom          datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo            datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [name]              nvarchar(128) NOT NULL,
    [object_id]         int           NOT NULL,
    principal_id        int               NULL,
    [schema_id]         int           NOT NULL,
    parent_object_id    int           NOT NULL,
    [type]              char(2)           NULL,
    [type_desc]         nvarchar(60)      NULL,
    create_date         datetime      NOT NULL,
    modify_date         datetime      NOT NULL,
    is_ms_shipped       bit           NOT NULL,
    is_published        bit           NOT NULL,
    is_schema_published bit           NOT NULL,
    unique_index_id     int               NULL,
    is_system_named     bit           NOT NULL,
    is_enforced         bit               NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__key_constraints__DatabaseID__ObjectID PRIMARY KEY CLUSTERED (_DatabaseID, _ObjectID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._key_constraints_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
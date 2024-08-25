CREATE TABLE dbo._triggers (
    _DatabaseID             int             NOT NULL CONSTRAINT FK__triggers__DatabaseID        REFERENCES dbo.[Database]   (_DatabaseID),
    _ObjectID               int             NOT NULL CONSTRAINT FK__triggers__ObjectID          REFERENCES dbo.[Object]     (_ObjectID),
    _ParentObjectID         int                 NULL CONSTRAINT FK__triggers__ParentObjectID    REFERENCES dbo.[Object]     (_ObjectID),
    _InsertDate             datetime2       NOT NULL CONSTRAINT DF__triggers__InsertDate        DEFAULT (SYSUTCDATETIME()),
    _ModifyDate             datetime2       NOT NULL CONSTRAINT DF__triggers__ModifyDate        DEFAULT (SYSUTCDATETIME()),
    _RowHash                binary(32)      NOT NULL,
    _ValidFrom              datetime2       GENERATED ALWAYS AS ROW START   NOT NULL,
    _ValidTo                datetime2       GENERATED ALWAYS AS ROW END     NOT NULL,
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

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__triggers__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
    INDEX IX__triggers__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._triggers_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

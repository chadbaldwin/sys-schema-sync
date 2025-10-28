CREATE TABLE dbo._foreign_key_columns (
    _DatabaseID          int        NOT NULL CONSTRAINT FK__foreign_key_columns__DatabaseID         REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__foreign_key_columns__DatabaseID,
    _ObjectID            bigint     NOT NULL CONSTRAINT FK__foreign_key_columns__ObjectID           REFERENCES dbo.[Object]   (_ObjectID),  -- Covered by CIX
    _ParentObjectID      bigint     NOT NULL CONSTRAINT FK__foreign_key_columns__ParentObjectID     REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__foreign_key_columns__ParentObjectID,
    _ParentColumnID      bigint     NOT NULL CONSTRAINT FK__foreign_key_columns__ParentColumnID     REFERENCES dbo.[Column]   (_ColumnID)   INDEX IX__foreign_key_columns__ParentColumnID,
    _ReferencedObjectID  bigint     NOT NULL CONSTRAINT FK__foreign_key_columns__ReferencedObjectID REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__foreign_key_columns__ReferencedObjectID,
    _ReferencedColumnID  bigint     NOT NULL CONSTRAINT FK__foreign_key_columns__ReferencedColumnID REFERENCES dbo.[Column]   (_ColumnID)   INDEX IX__foreign_key_columns__ReferencedColumnID,
    --
    _InsertDate          datetime2  NOT NULL CONSTRAINT DF__foreign_key_columns__InsertDate         DEFAULT (SYSUTCDATETIME()),
    _ModifyDate          datetime2  NOT NULL CONSTRAINT DF__foreign_key_columns__ModifyDate         DEFAULT (SYSUTCDATETIME()),
    _RowHash             binary(32) NOT NULL,
    --
    constraint_object_id int        NOT NULL,
    constraint_column_id int        NOT NULL,
    parent_object_id     int        NOT NULL,
    parent_column_id     int        NOT NULL,
    referenced_object_id int        NOT NULL,
    referenced_column_id int        NOT NULL,

    INDEX CIX__foreign_key_columns__ObjectID__ParentColumnID__ReferencedColumnID
        UNIQUE CLUSTERED (_ObjectID, _ParentColumnID, _ReferencedColumnID),
);
GO
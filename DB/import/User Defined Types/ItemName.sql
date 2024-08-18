CREATE TYPE import.ItemName AS TABLE (
    ID            int              NOT NULL,
    SchemaName    nvarchar(128)    NOT NULL,
    ObjectName    nvarchar(128)    NOT NULL,
    ObjectType    char(2)          NOT NULL,
    IndexName     nvarchar(128)        NULL,
    ColumnName    nvarchar(128)        NULL,
    ObjectID      int                  NULL,
    IndexID       int                  NULL,
    ColumnID      int                  NULL,

    INDEX CIX_ID CLUSTERED (ID),
    INDEX IX_SchemaName_ObjectName_ObjectType_ObjectID NONCLUSTERED (SchemaName, ObjectName, ObjectType, ObjectID),
    INDEX IX_ObjectID_IndexName NONCLUSTERED (ObjectID, IndexName),
    INDEX IX_ObjectID_ColumnName NONCLUSTERED (ObjectID, ColumnName),
    INDEX IX_IndexID NONCLUSTERED (IndexID),
    INDEX IX_ColumnID NONCLUSTERED (ColumnID)
);

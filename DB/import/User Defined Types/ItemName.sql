CREATE TYPE import.ItemName AS TABLE (
    ID            int              NOT NULL,
    SchemaName    nvarchar(128)    NOT NULL,
    ObjectName    nvarchar(128)    NOT NULL,
    ObjectType    char(2)          NOT NULL,
    IndexName     nvarchar(128)        NULL,
    ColumnName    nvarchar(128)        NULL,
    _ObjectID     int                  NULL,
    _IndexID      int                  NULL,
    _ColumnID     int                  NULL,

    INDEX CIX_ItemName_ID CLUSTERED (ID),
    INDEX IX_ItemName_SchemaName_ObjectName_ObjectType__ObjectID NONCLUSTERED (SchemaName, ObjectName, ObjectType, _ObjectID),
    INDEX IX_ItemName__ObjectID_IndexName NONCLUSTERED (_ObjectID, IndexName),
    INDEX IX_ItemName__ObjectID_ColumnName NONCLUSTERED (_ObjectID, ColumnName),
    INDEX IX_ItemName__IndexID NONCLUSTERED (_IndexID),
    INDEX IX_ItemName__ColumnID NONCLUSTERED (_ColumnID)
);
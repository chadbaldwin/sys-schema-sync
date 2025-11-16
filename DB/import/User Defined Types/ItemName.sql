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
    -- Indexes for supporting usp_CreateItems
    INDEX IX_ItemName_SchemaName_ObjectName_ObjectType NONCLUSTERED (SchemaName, ObjectName, ObjectType), -- Supports inserting and updating dbo.[Object]
    INDEX IX_ItemName__ObjectID_IndexName              NONCLUSTERED (_ObjectID, IndexName),               -- Supports inserting and updating dbo.[Index]
    INDEX IX_ItemName__ObjectID_ColumnName             NONCLUSTERED (_ObjectID, ColumnName),              -- Supports inserting and updating dbo.[Column]
    INDEX IX_ItemName__IndexID                         NONCLUSTERED (_IndexID),                           -- Supports dbo.[Index] updates for IsDeleted
    INDEX IX_ItemName__ColumnID                        NONCLUSTERED (_ColumnID)                           -- Supports dbo.[Column] updates for IsDeleted
);
-- TODO: Eventually convert to a memory-optimized table
-- https://www.sommarskog.se/share_data.html#usingtable
CREATE TABLE import.ItemNameProcess (
    ProcessKey           uniqueidentifier NOT NULL,
    ID                   int              NOT NULL,
    InsertDateUTC        datetime2        NOT NULL  CONSTRAINT DF_ItemNameProcess_InsertDateUTC DEFAULT (SYSUTCDATETIME())
                                                    INDEX IX_ItemNameProcess_InsertDateUTC,
    _DatabaseID          int              NOT NULL,
    SchemaName           nvarchar(128)    NOT NULL,
    ObjectName           nvarchar(128)    NOT NULL,
    ObjectType           char(2)          NOT NULL,
    IndexName            nvarchar(128)        NULL,
    ColumnName           nvarchar(128)        NULL,
    ObjectDefinitionHash binary(32)           NULL,
    _ObjectID            int                  NULL,
    _IndexID             int                  NULL,
    _ColumnID            int                  NULL,
    _ObjectDefinitionID  int                  NULL,

    INDEX CIX_ItemNameProcess_ProcessKey_ID CLUSTERED (ProcessKey, ID),
    -- Indexes for supporting usp_CreateItems
  --INDEX IX_ItemNameProcess_ProcessKey__DatabaseID_SchemaName_ObjectName_ObjectType NONCLUSTERED (ProcessKey, _DatabaseID, SchemaName, ObjectName, ObjectType), -- Supports inserting and updating dbo.[Object]
  --INDEX IX_ItemNameProcess_ProcessKey__DatabaseID__ObjectID_IndexName              NONCLUSTERED (ProcessKey, _DatabaseID, _ObjectID, IndexName),               -- Supports inserting and updating dbo.[Index]
    INDEX IX_ItemNameProcess_ProcessKey__DatabaseID__ObjectID_ColumnName             NONCLUSTERED (ProcessKey, _DatabaseID, _ObjectID, ColumnName),              -- Supports inserting and updating dbo.[Column]
  --INDEX IX_ItemNameProcess_ProcessKey__DatabaseID__IndexID                         NONCLUSTERED (ProcessKey, _DatabaseID, _IndexID),                           -- Supports dbo.[Index] updates for IsDeleted
  --INDEX IX_ItemNameProcess_ProcessKey__DatabaseID__ColumnID                        NONCLUSTERED (ProcessKey, _DatabaseID, _ColumnID)                           -- Supports dbo.[Column] updates for IsDeleted
);
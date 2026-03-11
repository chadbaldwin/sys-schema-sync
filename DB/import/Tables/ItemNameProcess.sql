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
    _ObjectID            bigint               NULL,
    _IndexID             bigint               NULL,
    _ColumnID            bigint               NULL,
    _ObjectDefinitionID  int                  NULL,

    INDEX CIX_ItemNameProcess_ProcessKey_ID CLUSTERED (ProcessKey, ID),
);
GO

ALTER TABLE import.ItemNameProcess SET (LOCK_ESCALATION = DISABLE);
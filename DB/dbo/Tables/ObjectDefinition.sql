CREATE TABLE dbo.ObjectDefinition (
    ObjectDefinitionID      int             NOT NULL IDENTITY
                                                     CONSTRAINT CPK_ObjectDefinition_ObjectDefinitionID  PRIMARY KEY CLUSTERED,
    ObjectDefinitionHash    binary(32)      NOT NULL CONSTRAINT UQ_ObjectDefinition_ObjectDefinitionHash UNIQUE,
    ObjectDefinition        nvarchar(MAX)       NULL, -- Encrypted SP's have a NULL definition
    CanonicalSQLHash        binary(32)          NULL,
    InsertDate              datetime2       NOT NULL CONSTRAINT DF_ObjectDefinition_InsertDate DEFAULT (SYSUTCDATETIME()),
);

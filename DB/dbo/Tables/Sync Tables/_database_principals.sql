-- Temporal history table
CREATE TABLE dbo._database_principals_history (
    _DatabaseID                        int           NOT NULL,
    --
    _InsertDate                        datetime2     NOT NULL,
    _ModifyDate                        datetime2     NOT NULL,
    _RowHash                           binary(32)    NOT NULL,
    _ValidFrom                         datetime2     NOT NULL,
    _ValidTo                           datetime2     NOT NULL,
    --
    [name]                                nvarchar(128)    NOT NULL,
    principal_id                          int              NOT NULL,
    [type]                                char(1)          NOT NULL,
    [type_desc]                           nvarchar(60)         NULL,
    default_schema_name                   nvarchar(128)        NULL,
    create_date                           datetime         NOT NULL,
    modify_date                           datetime         NOT NULL,
    owning_principal_id                   int                  NULL,
    [sid]                                 varbinary(85)        NULL,
    is_fixed_role                         bit              NOT NULL,
    authentication_type                   int              NOT NULL,
    authentication_type_desc              nvarchar(60)         NULL,
    default_language_name                 nvarchar(128)        NULL,
    default_language_lcid                 int                  NULL,
    [allow_encrypted_value_modifications] bit              NOT NULL,
    tenant_id                             uniqueidentifier     NULL, -- Added in SQL Server 2022

    INDEX CIX__database_principals_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

CREATE TABLE dbo._database_principals (
    _DatabaseID                        int           NOT NULL CONSTRAINT FK__database_principals__DatabaseID REFERENCES dbo.[Database] (_DatabaseID), -- Covered by CIX
    --
    _InsertDate                        datetime2     NOT NULL CONSTRAINT DF__database_principals__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                        datetime2     NOT NULL CONSTRAINT DF__database_principals__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash                           binary(32)    NOT NULL,
    _ValidFrom                         datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                           datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [name]                                nvarchar(128)    NOT NULL,
    principal_id                          int              NOT NULL,
    [type]                                char(1)          NOT NULL,
    [type_desc]                           nvarchar(60)         NULL,
    default_schema_name                   nvarchar(128)        NULL,
    create_date                           datetime         NOT NULL,
    modify_date                           datetime         NOT NULL,
    owning_principal_id                   int                  NULL,
    [sid]                                 varbinary(85)        NULL,
    is_fixed_role                         bit              NOT NULL,
    authentication_type                   int              NOT NULL,
    authentication_type_desc              nvarchar(60)         NULL,
    default_language_name                 nvarchar(128)        NULL,
    default_language_lcid                 int                  NULL,
    [allow_encrypted_value_modifications] bit              NOT NULL,
    tenant_id                             uniqueidentifier     NULL, -- Added in SQL Server 2022

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__database_principals__DatabaseID_principal_id PRIMARY KEY CLUSTERED (_DatabaseID, principal_id),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._database_principals_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
CREATE TYPE import.import__database_principals AS TABLE (
    _RowHash                           binary(32)    NOT NULL,
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

    INDEX CIX UNIQUE CLUSTERED (principal_id)
);
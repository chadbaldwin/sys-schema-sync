CREATE TYPE import.import__server_principals AS TABLE (
    _RowHash              binary(32)    NOT NULL,
    --
    [name]                nvarchar(128)    NOT NULL,
    principal_id          int              NOT NULL,
    [sid]                 varbinary(85)        NULL,
    [type]                char(1)          NOT NULL,
    [type_desc]           nvarchar(60)         NULL,
    is_disabled           bit                  NULL,
    create_date           datetime         NOT NULL,
    modify_date           datetime         NOT NULL,
    default_database_name nvarchar(128)        NULL,
    default_language_name nvarchar(128)        NULL,
    credential_id         int                  NULL,
    owning_principal_id   int                  NULL,
    is_fixed_role         bit              NOT NULL,
    tenant_id             uniqueidentifier     NULL, -- Added in SQL Server 2022

    INDEX CIX UNIQUE CLUSTERED (principal_id)
);
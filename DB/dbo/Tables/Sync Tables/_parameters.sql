-- Temporal history table
CREATE TABLE dbo._parameters_history (
    _DatabaseID                         int           NOT NULL,
    _ObjectID                           bigint        NOT NULL,
    --
    _InsertDate                         datetime2     NOT NULL,
    _ModifyDate                         datetime2     NOT NULL,
    _RowHash                            binary(32)    NOT NULL,
    _ValidFrom                          datetime2     NOT NULL,
    _ValidTo                            datetime2     NOT NULL,
    --
    [object_id]                         int            NOT NULL,
    [name]                              nvarchar(128)      NULL,
    parameter_id                        int            NOT NULL,
    system_type_id                      tinyint        NOT NULL,
    user_type_id                        int            NOT NULL,
    max_length                          smallint       NOT NULL,
    [precision]                         tinyint        NOT NULL,
    scale                               tinyint        NOT NULL,
    is_output                           bit            NOT NULL,
    is_cursor_ref                       bit            NOT NULL,
    has_default_value                   bit            NOT NULL,
    is_xml_document                     bit            NOT NULL,
    default_value                       nvarchar(MAX)      NULL, -- Deviation: Original data type: sql_variant
    xml_collection_id                   int            NOT NULL,
    is_readonly                         bit            NOT NULL,
    is_nullable                         bit                NULL,
    [encryption_type]                   int                NULL,
    encryption_type_desc                nvarchar(64)       NULL,
    encryption_algorithm_name           nvarchar(128)      NULL,
    column_encryption_key_id            int                NULL,
    column_encryption_key_database_name nvarchar(128)      NULL,
    vector_dimensions                   int                NULL, -- Added in SQL Server 2025
    vector_base_type                    tinyint            NULL, -- Added in SQL Server 2025
    vector_base_type_desc               nvarchar(10)       NULL, -- Added in SQL Server 2025

    INDEX CIX__parameters_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

CREATE TABLE dbo._parameters (
    _DatabaseID                         int           NOT NULL CONSTRAINT FK__parameters__DatabaseID REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__parameters__DatabaseID,
    _ObjectID                           bigint        NOT NULL CONSTRAINT FK__parameters__ObjectID   REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__parameters__ObjectID,
    --
    _InsertDate                         datetime2     NOT NULL CONSTRAINT DF__parameters__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                         datetime2     NOT NULL CONSTRAINT DF__parameters__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash                            binary(32)    NOT NULL,
    _ValidFrom                          datetime2     GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                            datetime2     GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    [object_id]                         int            NOT NULL,
    [name]                              nvarchar(128)      NULL,
    parameter_id                        int            NOT NULL,
    system_type_id                      tinyint        NOT NULL,
    user_type_id                        int            NOT NULL,
    max_length                          smallint       NOT NULL,
    [precision]                         tinyint        NOT NULL,
    scale                               tinyint        NOT NULL,
    is_output                           bit            NOT NULL,
    is_cursor_ref                       bit            NOT NULL,
    has_default_value                   bit            NOT NULL,
    is_xml_document                     bit            NOT NULL,
    default_value                       nvarchar(MAX)      NULL, -- Deviation: Original data type: sql_variant
    xml_collection_id                   int            NOT NULL,
    is_readonly                         bit            NOT NULL,
    is_nullable                         bit                NULL,
    [encryption_type]                   int                NULL,
    encryption_type_desc                nvarchar(64)       NULL,
    encryption_algorithm_name           nvarchar(128)      NULL,
    column_encryption_key_id            int                NULL,
    column_encryption_key_database_name nvarchar(128)      NULL,
    vector_dimensions                   int                NULL, -- Added in SQL Server 2025
    vector_base_type                    tinyint            NULL, -- Added in SQL Server 2025
    vector_base_type_desc               nvarchar(10)       NULL, -- Added in SQL Server 2025

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__parameters__DatabaseID__ObjectID_parameter_id PRIMARY KEY CLUSTERED (_DatabaseID, _ObjectID, parameter_id) WITH (DATA_COMPRESSION = PAGE),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._parameters_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
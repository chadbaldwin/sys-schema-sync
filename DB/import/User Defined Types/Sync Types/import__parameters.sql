CREATE TYPE import.import__parameters AS TABLE (
    __ID                                 int           NOT NULL,
    _SchemaName                          nvarchar(128) NOT NULL,
    _ObjectName                          nvarchar(128) NOT NULL,
    _ObjectType                          char(2)       NOT NULL,
    _RowHash                             binary(32)    NOT NULL,
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

    INDEX CIX CLUSTERED (__ID)
);
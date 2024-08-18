DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _ColumnName = c.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.[object_id], x.[name], x.column_id, x.system_type_id, x.user_type_id, x.max_length, x.[precision], x.scale
        , x.collation_name, x.is_nullable, x.is_ansi_padded, x.is_rowguidcol, x.is_identity, x.is_filestream, x.is_replicated
        , x.is_non_sql_subscribed, x.is_merge_published, x.is_dts_replicated, x.is_xml_document, x.xml_collection_id
        , x.default_object_id, x.rule_object_id
        /*  Prefer to use SELECT * for export queries so that new columns cause exceptions and we know to update
            the schema. But in this case, we need to convert the sql_variant columns to bigint since sql_variant
            is not supported by System.Data.Common.DbDataAdapter.Fill, which is used by dbatools Invoke-DbaQuery
            to populate TVP parameters. */
        , seed_value                     = CONVERT(bigint, x.seed_value)
        , increment_value                = CONVERT(bigint, x.increment_value)
        , last_value                     = CONVERT(bigint, x.last_value)
        , x.is_not_for_replication, x.is_computed, x.is_sparse, x.is_column_set, x.generated_always_type, x.generated_always_type_desc
        , x.[encryption_type], x.encryption_type_desc, x.encryption_algorithm_name, x.column_encryption_key_id, x.column_encryption_key_database_name
        , x.is_hidden, x.is_masked, x.graph_type, x.graph_type_desc
        --
        , is_data_deletion_filter_column = CONVERT(bit         , NULL) -- Added: SQL Server 2022
        , ledger_view_column_type        = CONVERT(int         , NULL) -- Added: SQL Server 2022
        , ledger_view_column_type_desc   = CONVERT(nvarchar(60), NULL) -- Added: SQL Server 2022
        , is_dropped_ledger_column       = CONVERT(bit         , NULL) -- Added: SQL Server 2022
    FROM sys.identity_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.columns c ON c.[object_id] = x.[object_id] AND c.column_id = x.column_id
    WHERE o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT x = 1 INTO #tmp -- hack for deferred name resolution to prevent a compile exception on the new 2022 columns when run on a non 2022 instance
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _ColumnName = c.[name]
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.[object_id], x.[name], x.column_id, x.system_type_id, x.user_type_id, x.max_length, x.[precision], x.scale
        , x.collation_name, x.is_nullable, x.is_ansi_padded, x.is_rowguidcol, x.is_identity, x.is_filestream, x.is_replicated
        , x.is_non_sql_subscribed, x.is_merge_published, x.is_dts_replicated, x.is_xml_document, x.xml_collection_id
        , x.default_object_id, x.rule_object_id
        /*  Prefer to use SELECT * for export queries so that new columns cause exceptions and we know to update
            the schema. But in this case, we need to convert the sql_variant columns to bigint since sql_variant
            is not supported by System.Data.Common.DbDataAdapter.Fill, which is used by dbatools Invoke-DbaQuery
            to populate TVP parameters. */
        , seed_value = CONVERT(bigint, x.seed_value)
        , increment_value = CONVERT(bigint, x.increment_value)
        , last_value = CONVERT(bigint, x.last_value)
        , x.is_not_for_replication, x.is_computed, x.is_sparse, x.is_column_set, x.generated_always_type, x.generated_always_type_desc
        , x.[encryption_type], x.encryption_type_desc, x.encryption_algorithm_name, x.column_encryption_key_id, x.column_encryption_key_database_name
        , x.is_hidden, x.is_masked, x.graph_type, x.graph_type_desc
        --
        , x.is_data_deletion_filter_column, x.ledger_view_column_type, x.ledger_view_column_type_desc, x.is_dropped_ledger_column
    FROM sys.identity_columns x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.columns c ON c.[object_id] = x.[object_id] AND c.column_id = x.column_id
        CROSS JOIN #tmp
    WHERE o.is_ms_shipped = 0;
END;
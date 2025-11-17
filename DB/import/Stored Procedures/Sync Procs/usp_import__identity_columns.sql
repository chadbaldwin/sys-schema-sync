CREATE PROCEDURE import.usp_import__identity_columns (
    @DatabaseID int,
    @Dataset    import.import__identity_columns READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
         EXEC dbo.usp_Raiserror '[%s] Get IDs: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _ColumnName FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._identity_columns;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ColumnID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ColumnID, _RowHash, [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, seed_value, increment_value, last_value, is_not_for_replication, is_computed, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column)
        SELECT @DatabaseID, o._ObjectID, o._ColumnID, d._RowHash, d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.seed_value, d.increment_value, d.last_value, d.is_not_for_replication, d.is_computed, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Get IDs: Done', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._identity_columns';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._identity_columns x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ObjectID                           = d._ObjectID
          , x._ModifyDate                         = SYSUTCDATETIME()
          , x._RowHash                            = d._RowHash
          , x.[object_id]                         = d.[object_id]
          , x.[name]                              = d.[name]
          , x.column_id                           = d.column_id
          , x.system_type_id                      = d.system_type_id
          , x.user_type_id                        = d.user_type_id
          , x.max_length                          = d.max_length
          , x.[precision]                         = d.[precision]
          , x.scale                               = d.scale
          , x.collation_name                      = d.collation_name
          , x.is_nullable                         = d.is_nullable
          , x.is_ansi_padded                      = d.is_ansi_padded
          , x.is_rowguidcol                       = d.is_rowguidcol
          , x.is_identity                         = d.is_identity
          , x.is_filestream                       = d.is_filestream
          , x.is_replicated                       = d.is_replicated
          , x.is_non_sql_subscribed               = d.is_non_sql_subscribed
          , x.is_merge_published                  = d.is_merge_published
          , x.is_dts_replicated                   = d.is_dts_replicated
          , x.is_xml_document                     = d.is_xml_document
          , x.xml_collection_id                   = d.xml_collection_id
          , x.default_object_id                   = d.default_object_id
          , x.rule_object_id                      = d.rule_object_id
          , x.seed_value                          = d.seed_value
          , x.increment_value                     = d.increment_value
          , x.last_value                          = d.last_value
          , x.is_not_for_replication              = d.is_not_for_replication
          , x.is_computed                         = d.is_computed
          , x.is_sparse                           = d.is_sparse
          , x.is_column_set                       = d.is_column_set
          , x.generated_always_type               = d.generated_always_type
          , x.generated_always_type_desc          = d.generated_always_type_desc
          , x.[encryption_type]                   = d.[encryption_type]
          , x.encryption_type_desc                = d.encryption_type_desc
          , x.encryption_algorithm_name           = d.encryption_algorithm_name
          , x.column_encryption_key_id            = d.column_encryption_key_id
          , x.column_encryption_key_database_name = d.column_encryption_key_database_name
          , x.is_hidden                           = d.is_hidden
          , x.is_masked                           = d.is_masked
          , x.graph_type                          = d.graph_type
          , x.graph_type_desc                     = d.graph_type_desc
          , x.is_data_deletion_filter_column      = d.is_data_deletion_filter_column
          , x.ledger_view_column_type             = d.ledger_view_column_type
          , x.ledger_view_column_type_desc        = d.ledger_view_column_type_desc
          , x.is_dropped_ledger_column            = d.is_dropped_ledger_column
        FROM dbo._identity_columns x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._identity_columns (_DatabaseID, _ObjectID, _ColumnID, _RowHash, [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, seed_value, increment_value, last_value, is_not_for_replication, is_computed, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column)
        SELECT d._DatabaseID, d._ObjectID, d._ColumnID, d._RowHash, d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.seed_value, d.increment_value, d.last_value, d.is_not_for_replication, d.is_computed, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._identity_columns x WHERE d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
CREATE PROCEDURE import.usp_import__columns (
    @DatabaseID int,
    @Dataset    import.import__columns READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _ColumnName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._columns;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ColumnID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ColumnID, _RowHash, [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_computed, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column, vector_dimensions, vector_base_type, vector_base_type_desc)
            SELECT @DatabaseID, o._ObjectID, o._ColumnID, d._RowHash, d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_computed, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column, d.vector_dimensions, d.vector_base_type, d.vector_base_type_desc
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._columns';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._columns x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
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
              , x.is_computed                         = d.is_computed
              , x.is_filestream                       = d.is_filestream
              , x.is_replicated                       = d.is_replicated
              , x.is_non_sql_subscribed               = d.is_non_sql_subscribed
              , x.is_merge_published                  = d.is_merge_published
              , x.is_dts_replicated                   = d.is_dts_replicated
              , x.is_xml_document                     = d.is_xml_document
              , x.xml_collection_id                   = d.xml_collection_id
              , x.default_object_id                   = d.default_object_id
              , x.rule_object_id                      = d.rule_object_id
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
              , x.vector_dimensions                   = d.vector_dimensions
              , x.vector_base_type                    = d.vector_base_type
              , x.vector_base_type_desc               = d.vector_base_type_desc
            FROM dbo._columns x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._columns (_DatabaseID, _ObjectID, _ColumnID, _RowHash, [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_computed, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column, vector_dimensions, vector_base_type, vector_base_type_desc)
            SELECT d._DatabaseID, d._ObjectID, d._ColumnID, d._RowHash, d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_computed, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column, d.vector_dimensions, d.vector_base_type, d.vector_base_type_desc
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._columns x WHERE d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
GO
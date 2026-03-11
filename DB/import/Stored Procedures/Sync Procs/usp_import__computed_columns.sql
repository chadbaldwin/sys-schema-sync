CREATE PROC import.usp_import__computed_columns (
    @DatabaseID int,
    @Dataset    import.import__computed_columns READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_DatabaseID', @value = @DatabaseID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _ColumnName FROM @Dataset;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._computed_columns;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ColumnID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ColumnID, _RowHash, [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, [definition], uses_database_collation, is_persisted, is_computed, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column, is_index_column_expression)
            SELECT @DatabaseID, o._ObjectID, o._ColumnID, d._RowHash, d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.[definition], d.uses_database_collation, d.is_persisted, d.is_computed, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column, d.is_index_column_expression
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @TargetTable = 'dbo._computed_columns';
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Error %d, State %d, Line %d)', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror @EventType = 'Error', @ActionName = 'Proc', @Scope1 = @ProcName, @DetailMessage = @ErrorMessage, @ts = @proc_sw;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
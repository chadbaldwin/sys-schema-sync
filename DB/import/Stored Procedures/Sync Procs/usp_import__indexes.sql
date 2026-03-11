CREATE PROC import.usp_import__indexes (
    @DatabaseID int,
    @Dataset    import.import__indexes READONLY,
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
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1, @FullImport_Index = 1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._indexes;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], index_id, [type], [type_desc], is_unique, data_space_id, [ignore_dup_key], is_primary_key, is_unique_constraint, fill_factor, is_padded, is_disabled, is_hypothetical, is_ignored_in_optimization, [allow_row_locks], [allow_page_locks], has_filter, filter_definition, [compression_delay], suppress_dup_key_messages, auto_created, [optimize_for_sequential_key])
            SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[object_id], d.[name], d.index_id, d.[type], d.[type_desc], d.is_unique, d.data_space_id, d.[ignore_dup_key], d.is_primary_key, d.is_unique_constraint, d.fill_factor, d.is_padded, d.is_disabled, d.is_hypothetical, d.is_ignored_in_optimization, d.[allow_row_locks], d.[allow_page_locks], d.has_filter, d.filter_definition, d.[compression_delay], d.suppress_dup_key_messages, d.auto_created, d.[optimize_for_sequential_key]
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @TargetTable = 'dbo._indexes';
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
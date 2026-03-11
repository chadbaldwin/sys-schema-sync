CREATE PROC import.usp_import__views (
    @DatabaseID int,
    @Dataset    import.import__views READONLY,
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
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._views;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_replicated, has_replication_filter, has_opaque_metadata, has_unchecked_assembly_data, with_check_option, is_date_correlation_view, is_tracked_by_cdc, has_snapshot, ledger_view_type, ledger_view_type_desc, is_dropped_ledger_view)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_replicated, d.has_replication_filter, d.has_opaque_metadata, d.has_unchecked_assembly_data, d.with_check_option, d.is_date_correlation_view, d.is_tracked_by_cdc, d.has_snapshot, d.ledger_view_type, d.ledger_view_type_desc, d.is_dropped_ledger_view
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @TargetTable = 'dbo._views';
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
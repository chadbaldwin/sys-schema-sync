CREATE PROCEDURE import.usp_import__views (
    @DatabaseID int,
    @Dataset    import.import__views READONLY,
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
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._views;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_replicated, has_replication_filter, has_opaque_metadata, has_unchecked_assembly_data, with_check_option, is_date_correlation_view, is_tracked_by_cdc, has_snapshot, ledger_view_type, ledger_view_type_desc, is_dropped_ledger_view)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_replicated, d.has_replication_filter, d.has_opaque_metadata, d.has_unchecked_assembly_data, d.with_check_option, d.is_date_correlation_view, d.is_tracked_by_cdc, d.has_snapshot, d.ledger_view_type, d.ledger_view_type_desc, d.is_dropped_ledger_view
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
            SET @TableName = N'dbo._views';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._views x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ModifyDate                 = SYSUTCDATETIME()
              , x._RowHash                    = d._RowHash
              , x.[name]                      = d.[name]
              , x.[object_id]                 = d.[object_id]
              , x.principal_id                = d.principal_id
              , x.[schema_id]                 = d.[schema_id]
              , x.parent_object_id            = d.parent_object_id
              , x.[type]                      = d.[type]
              , x.[type_desc]                 = d.[type_desc]
              , x.create_date                 = d.create_date
              , x.modify_date                 = d.modify_date
              , x.is_ms_shipped               = d.is_ms_shipped
              , x.is_published                = d.is_published
              , x.is_schema_published         = d.is_schema_published
              , x.is_replicated               = d.is_replicated
              , x.has_replication_filter      = d.has_replication_filter
              , x.has_opaque_metadata         = d.has_opaque_metadata
              , x.has_unchecked_assembly_data = d.has_unchecked_assembly_data
              , x.with_check_option           = d.with_check_option
              , x.is_date_correlation_view    = d.is_date_correlation_view
              , x.is_tracked_by_cdc           = d.is_tracked_by_cdc
              , x.has_snapshot                = d.has_snapshot
              , x.ledger_view_type            = d.ledger_view_type
              , x.ledger_view_type_desc       = d.ledger_view_type_desc
              , x.is_dropped_ledger_view      = d.is_dropped_ledger_view
            FROM dbo._views x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._views (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_replicated, has_replication_filter, has_opaque_metadata, has_unchecked_assembly_data, with_check_option, is_date_correlation_view, is_tracked_by_cdc, has_snapshot, ledger_view_type, ledger_view_type_desc, is_dropped_ledger_view)
            SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_replicated, d.has_replication_filter, d.has_opaque_metadata, d.has_unchecked_assembly_data, d.with_check_option, d.is_date_correlation_view, d.is_tracked_by_cdc, d.has_snapshot, d.ledger_view_type, d.ledger_view_type_desc, d.is_dropped_ledger_view
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._views x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
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
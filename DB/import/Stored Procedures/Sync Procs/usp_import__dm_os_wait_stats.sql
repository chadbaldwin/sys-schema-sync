CREATE PROC import.usp_import__dm_os_wait_stats (
    @InstanceID int,
    @Dataset    import.import__dm_os_wait_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_InstanceID', @value = @InstanceID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@InstanceID IS NULL) BEGIN; THROW 51000, 'Required parameter @InstanceID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._dm_os_wait_stats;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_InstanceID, wait_type);

            INSERT #Dataset WITH(TABLOCK) (_InstanceID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
            SELECT @InstanceID, d.wait_type, d.waiting_tasks_count, d.wait_time_ms, d.max_wait_time_ms, d.signal_wait_time_ms
            FROM @Dataset d;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._dm_os_wait_stats';

            /*  Special case for not using import.usp_RunCommonDUI
                This update deviates from the common pattern since we want to set missing wait types to 0 instead of deleting */
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            UPDATE x
            SET   x._ModifyDate         = SYSUTCDATETIME()
                --
                , x.waiting_tasks_count = COALESCE(d.waiting_tasks_count, 0)
                , x.wait_time_ms        = COALESCE(d.wait_time_ms, 0)
                , x.max_wait_time_ms    = COALESCE(d.max_wait_time_ms, 0)
                , x.signal_wait_time_ms = COALESCE(d.signal_wait_time_ms, 0)
            FROM dbo._dm_os_wait_stats x
                LEFT JOIN #Dataset d ON d._InstanceID = x._InstanceID AND d.wait_type = x.wait_type
            WHERE x._InstanceID = @InstanceID;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

            -- Common insert only
            EXEC import.usp_RunCommonDUI @InstanceID = @InstanceID, @TargetTable = @TableName, @DeletesEnabled = 0, @UpdatesEnabled = 0, @InsertsEnabled = 1;
        COMMIT;
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
-- TODO: Convert to similar setup as sys.dm_db_index_usage_stats using delta table with temporal history.
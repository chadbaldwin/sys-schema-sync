CREATE PROC import.usp_import__master_files (
    @InstanceID int,
    @Dataset    import.import__master_files READONLY,
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
            SELECT TOP (0) * INTO #Dataset FROM dbo._master_files;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_InstanceID, _DatabaseName, [file_id]);

            INSERT #Dataset WITH(TABLOCK) (_InstanceID, _DatabaseID, _RowHash, _DatabaseName, database_id, [file_id], file_guid, [type], [type_desc], data_space_id, [name], physical_name, [state], state_desc, size, max_size, growth, is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, is_persistent_log_buffer, create_lsn, drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid, differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, credential_id)
            SELECT @InstanceID, sd._DatabaseID, d._RowHash, d._DatabaseName, d.database_id, d.[file_id], d.file_guid, d.[type], d.[type_desc], d.data_space_id, d.[name], d.physical_name, d.[state], d.state_desc, d.size, d.max_size, d.growth, d.is_media_read_only, d.is_read_only, d.is_sparse, d.is_percent_growth, d.is_name_reserved, d.is_persistent_log_buffer, d.create_lsn, d.drop_lsn, d.read_only_lsn, d.read_write_lsn, d.differential_base_lsn, d.differential_base_guid, d.differential_base_time, d.redo_start_lsn, d.redo_start_fork_guid, d.redo_target_lsn, d.redo_target_fork_guid, d.backup_lsn, d.credential_id
            FROM @Dataset d
                LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d._DatabaseName; -- Get _DatabaseID for ones we do sync
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @InstanceID = @InstanceID, @TargetTable = 'dbo._master_files';
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
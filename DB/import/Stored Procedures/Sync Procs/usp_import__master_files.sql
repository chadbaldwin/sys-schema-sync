CREATE PROCEDURE import.usp_import__master_files (
    @InstanceID int,
    @Dataset    import.import__master_files READONLY,
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
        IF (@InstanceID IS NULL) BEGIN; THROW 51000, 'Required parameter @InstanceID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._master_files';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._master_files x
            WHERE x._InstanceID = @InstanceID
                AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d._DatabaseName = x._DatabaseName AND d.[file_id] = x.[file_id]);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET   x._DatabaseID              = sd._DatabaseID
                , x._ModifyDate              = SYSUTCDATETIME()
                , x._RowHash                 = d._RowHash
                , x._DatabaseName            = d._DatabaseName
                --
                , x.database_id              = d.database_id
                , x.[file_id]                = d.[file_id]
                , x.file_guid                = d.file_guid
                , x.[type]                   = d.[type]
                , x.[type_desc]              = d.[type_desc]
                , x.data_space_id            = d.data_space_id
                , x.[name]                   = d.[name]
                , x.physical_name            = d.physical_name
                , x.[state]                  = d.[state]
                , x.state_desc               = d.state_desc
                , x.size                     = d.size
                , x.max_size                 = d.max_size
                , x.growth                   = d.growth
                , x.is_media_read_only       = d.is_media_read_only
                , x.is_read_only             = d.is_read_only
                , x.is_sparse                = d.is_sparse
                , x.is_percent_growth        = d.is_percent_growth
                , x.is_name_reserved         = d.is_name_reserved
                , x.is_persistent_log_buffer = d.is_persistent_log_buffer
                , x.create_lsn               = d.create_lsn
                , x.drop_lsn                 = d.drop_lsn
                , x.read_only_lsn            = d.read_only_lsn
                , x.read_write_lsn           = d.read_write_lsn
                , x.differential_base_lsn    = d.differential_base_lsn
                , x.differential_base_guid   = d.differential_base_guid
                , x.differential_base_time   = d.differential_base_time
                , x.redo_start_lsn           = d.redo_start_lsn
                , x.redo_start_fork_guid     = d.redo_start_fork_guid
                , x.redo_target_lsn          = d.redo_target_lsn
                , x.redo_target_fork_guid    = d.redo_target_fork_guid
                , x.backup_lsn               = d.backup_lsn
                , x.credential_id            = d.credential_id
            FROM dbo._master_files x
                JOIN @Dataset d ON d._DatabaseName = x._DatabaseName AND d.[file_id] = x.[file_id]
                LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d._DatabaseName -- Get _DatabaseID for ones we do sync
            WHERE x._InstanceID = @InstanceID
                AND x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._master_files (_InstanceID, _DatabaseID, _RowHash, _DatabaseName, database_id, [file_id], file_guid, [type], [type_desc], data_space_id, [name], physical_name, [state], state_desc, size, max_size, growth, is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, is_persistent_log_buffer, create_lsn, drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid, differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, credential_id)
            SELECT @InstanceID, sd._DatabaseID, d._RowHash, d._DatabaseName, d.database_id, d.[file_id], d.file_guid, d.[type], d.[type_desc], d.data_space_id, d.[name], d.physical_name, d.[state], d.state_desc, d.size, d.max_size, d.growth, d.is_media_read_only, d.is_read_only, d.is_sparse, d.is_percent_growth, d.is_name_reserved, d.is_persistent_log_buffer, d.create_lsn, d.drop_lsn, d.read_only_lsn, d.read_write_lsn, d.differential_base_lsn, d.differential_base_guid, d.differential_base_time, d.redo_start_lsn, d.redo_start_fork_guid, d.redo_target_lsn, d.redo_target_fork_guid, d.backup_lsn, d.credential_id
            FROM @Dataset d
                LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d._DatabaseName -- Get _DatabaseID for ones we do sync
            WHERE NOT EXISTS (
                    SELECT *
                    FROM dbo._master_files x
                    WHERE x._InstanceID = @InstanceID
                        AND x._DatabaseName = d._DatabaseName AND x.[file_id] = d.[file_id]
                );
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
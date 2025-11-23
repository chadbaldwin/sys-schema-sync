CREATE PROCEDURE import.usp_import__database_automatic_tuning_options (
    @DatabaseID int,
    @Dataset    import.import__database_automatic_tuning_options READONLY,
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
        BEGIN TRAN;
            SET @TableName = N'dbo._database_automatic_tuning_options';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._database_automatic_tuning_options x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.[name] = x.[name]);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ModifyDate        = SYSUTCDATETIME()
              , x._RowHash           = d._RowHash
              , x.[desired_state]    = d.[desired_state]
              , x.desired_state_desc = d.desired_state_desc
              , x.actual_state       = d.actual_state
              , x.actual_state_desc  = d.actual_state_desc
              , x.reason             = d.reason
              , x.reason_desc        = d.reason_desc
            FROM dbo._database_automatic_tuning_options x
                JOIN @Dataset d ON d.[name] = x.[name]
            WHERE x._DatabaseID = @DatabaseID
                AND x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._database_automatic_tuning_options (_DatabaseID, _RowHash, [name], [desired_state], desired_state_desc, actual_state, actual_state_desc, reason, reason_desc)
            SELECT @DatabaseID, d._RowHash, d.[name], d.[desired_state], d.desired_state_desc, d.actual_state, d.actual_state_desc, d.reason, d.reason_desc
            FROM @Dataset d
            WHERE NOT EXISTS (
                    SELECT *
                    FROM dbo._database_automatic_tuning_options x
                    WHERE x._DatabaseID = @DatabaseID
                        AND x.[name] = d.[name]
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
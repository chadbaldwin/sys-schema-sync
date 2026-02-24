CREATE PROC import.usp_DeleteItemNameProcessByProcessKey (
    @ProcessKey1 uniqueidentifier,
    @ProcessKey2 uniqueidentifier = NULL,
    @ProcessKey3 uniqueidentifier = NULL,
    @BatchSize int = 5000
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Proc', NULL, NULL, @ProcName;
        IF (COALESCE(@ProcessKey1, @ProcessKey2, @ProcessKey3) IS NULL) BEGIN; THROW 51000, 'At least one process key must be provided', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @TableName nvarchar(300) = 'import.ItemNameProcess';
        BEGIN TRY
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; DECLARE @deletes_sw datetime2 = SYSUTCDATETIME();
            DECLARE @delete_batch_sw datetime2 = SYSUTCDATETIME(), @delete_batch_rc bigint;
            WHILE (1=1)
            BEGIN;
                DELETE TOP(@BatchSize) x
                FROM import.ItemNameProcess x
                WHERE x.ProcessKey IN (@ProcessKey1, @ProcessKey2, @ProcessKey3);

                SET @delete_batch_rc = @@ROWCOUNT;
                IF (@delete_batch_rc = 0) BEGIN; BREAK; END;

                EXEC dbo.usp_Raiserror '[%s] Deleted batch', @delete_batch_sw, @delete_batch_rc, @ProcName; SET @delete_batch_sw = SYSUTCDATETIME();
            END;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @deletes_sw, @@ROWCOUNT, @ProcName, @TableName;
        END TRY
        BEGIN CATCH
            DECLARE @errmsg nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
            EXEC dbo.usp_Raiserror '[%s] [%s] Error: Delete - %s', @deletes_sw, @@ROWCOUNT, @ProcName, @TableName, @errmsg;
            -- Purposely eating the exception. Failure to delete should not be a terminating event, just allow database maintenance to cleanup later.
        END CATCH;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Proc', @proc_sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Proc - %s', @proc_sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
CREATE PROC import.usp_DeleteItemNameProcessByProcessKey (
    @ProcessKey1 uniqueidentifier,
    @ProcessKey2 uniqueidentifier = NULL,
    @ProcessKey3 uniqueidentifier = NULL,
    @BatchSize int = 5000
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (COALESCE(@ProcessKey1, @ProcessKey2, @ProcessKey3) IS NULL) BEGIN; THROW 51000, 'At least one process key must be provided', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @TableName nvarchar(300) = 'import.ItemNameProcess', @deletes_sw datetime2, @delete_batch_sw datetime2, @delete_batch_rc bigint;
        BEGIN TRY
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @deletes_sw OUTPUT;
            WHILE (@delete_batch_rc > 0 OR @delete_batch_rc IS NULL)
            BEGIN;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @delete_batch_sw OUTPUT;
                DELETE TOP(@BatchSize) x
                FROM import.ItemNameProcess x
                WHERE x.ProcessKey IN (@ProcessKey1, @ProcessKey2, @ProcessKey3);
                SET @delete_batch_rc = @@ROWCOUNT;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @delete_batch_sw, @rc = @delete_batch_rc;
            END;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @deletes_sw;
        END TRY
        BEGIN CATCH
            DECLARE @errmsg nvarchar(2047) = FORMATMESSAGE('%s (Error %d, State %d, Line %d)', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
            EXEC dbo.usp_Raiserror @EventType = 'Error', @ActionName = 'Delete loop', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = @errmsg, @ts = @deletes_sw;
            -- Purposely eating the exception. Failure to delete should not be a terminating event, just log it and let database maintenance cleanup later.
        END CATCH;
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
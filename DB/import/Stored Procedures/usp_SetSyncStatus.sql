CREATE PROC import.usp_SetSyncStatus (
    @InstanceID     int,
    @DatabaseID     int = NULL,
    @SyncObjectID   int = NULL,
    @Checksum       int = NULL,
    @ErrorMessage   nvarchar(MAX) = NULL,
    @Verbose        bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_InstanceID', @value = @InstanceID;
    EXEC sys.sp_set_session_context @key = N'_DatabaseID', @value = @DatabaseID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        DECLARE @CurrentTime datetime2 = SYSUTCDATETIME(), @rc bigint = 0;

        -- Including the entire exception message in the output is excessive, so reducing it down to just yes/no on IsError
        DECLARE @HasError nvarchar(10) = IIF(@ErrorMessage IS NOT NULL, 'true','false');
        IF (@Verbose = 1)
        BEGIN;
            RAISERROR(N'[%s] Input parameters: @InstanceID = %i, @DatabaseID = %i, @SyncObjectID = %i, @Checksum = %i, @ErrorMessage is populated: %s',0,1
                , @ProcName, @InstanceID, @DatabaseID, @SyncObjectID, @Checksum, @HasError) WITH NOWAIT;
        END;

        IF EXISTS (
            SELECT *
            FROM import.SyncObject
            WHERE SyncObjectID = @SyncObjectID
                AND ChecksumQueryText IS NOT NULL
                AND @Checksum IS NULL
                AND @ErrorMessage IS NULL -- If there's already an error message, then the checksum is likely null for that reason. Once that error is fixed, if it's still null, it will be caught again.
        )
        BEGIN;
            -- This seems to be the easist solution for now...Prepend the existing exception with this one.
            SET @ErrorMessage = 'Error: Checksum value is NULL even though a ChecksumQueryText was provided.';
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        IF (@SyncObjectID IS NOT NULL)
        BEGIN;
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update status record', @Scope1 = @ProcName;
            IF (@ErrorMessage IS NULL)
            BEGIN;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update status record as successful sync', @Scope1 = @ProcName;
                UPDATE x
                SET x.LastSyncChecksum  = @Checksum,
                    /*  '=' logic handles NULL's, be careful changing
                        NULL exceptions are already handled above. So if either side is NULL here, it's intentional
                        and should be counted as a change. NULL on either side of '=' is false, so it is logged.

                        If both sides are NULL, then that means this SyncObject does not utilize Cheecksums, so
                        it should _always_ be logged. */
                    x.LastSyncTime       = IIF(x.LastSyncChecksum = @Checksum, x.LastSyncTime, @CurrentTime),
                    x.LastSyncCheck      = @CurrentTime,
                    x.LastSyncWasError   = 0
                FROM import.DatabaseSyncObjectStatus x
                WHERE EXISTS (
                        SELECT @InstanceID, @DatabaseID, @SyncObjectID
                        INTERSECT
                        SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID
                    );
                SET @rc = @@ROWCOUNT;
            END;
            ELSE
            BEGIN
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update status record as failed sync', @Scope1 = @ProcName;
                UPDATE x
                SET x.LastSyncCheck         = @CurrentTime,
                    x.LastSyncError         = @CurrentTime,
                    x.LastSyncErrorMessage  = @ErrorMessage,
                    x.LastSyncWasError      = 1
                FROM import.DatabaseSyncObjectStatus x
                WHERE EXISTS (
                        SELECT @InstanceID, @DatabaseID, @SyncObjectID
                        INTERSECT
                        SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID
                    );
                SET @rc = @@ROWCOUNT;
            END
            ------------------------------------------------------------------------------

            ------------------------------------------------------------------------------
            IF (@rc = 0)
            BEGIN;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Create status record', @Scope1 = @ProcName;
                IF (@ErrorMessage IS NULL)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Create status record as successful sync', @Scope1 = @ProcName;
                    INSERT import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID, LastSyncChecksum)
                    VALUES (@InstanceID, @DatabaseID, @SyncObjectID, @Checksum);
                END;
                ELSE
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Create status record with error', @Scope1 = @ProcName;
                    -- Note: Leaving LastSyncChecksum NULL so that it is forced to sync the next time it runs
                    INSERT import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID, LastSyncChecksum, LastSyncTime, LastSyncError, LastSyncErrorMessage, LastSyncWasError)
                    VALUES (@InstanceID, @DatabaseID, @SyncObjectID, NULL, NULL, @CurrentTime, @ErrorMessage, 1);
                END;
            END;
        END;
        ELSE
        BEGIN;
            IF (@ErrorMessage IS NOT NULL)
            BEGIN;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Push back all syncs for database', @Scope1 = @ProcName, @DetailMessage = @ErrorMessage;
                /*  In this case, a database wide error is being logged which means we want to push all sync object tasks
                    to prevent them from running until their next interval.
                
                    Known issues: This does not handle delaying instance level syncs because they operate on the master
                    database which does not have an entry in the Database or DatabaseSyncObjectStatus tables.
                */
                UPDATE x
                SET x.LastSyncCheck         = @CurrentTime,
                    x.LastSyncError         = @CurrentTime,
                    x.LastSyncErrorMessage  = @ErrorMessage,
                    x.LastSyncWasError      = 1
                FROM import.DatabaseSyncObjectStatus x
                WHERE EXISTS (
                        SELECT @InstanceID, @DatabaseID
                        INTERSECT
                        SELECT x._InstanceID, x._DatabaseID
                    );

                INSERT import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID, LastSyncError, LastSyncErrorMessage, LastSyncWasError)
                SELECT x._InstanceID, x._DatabaseID, x.SyncObjectID
                    , LastSyncError         = @CurrentTime
                    , LastSyncErrorMessage  = @ErrorMessage
                    , LastSyncWasError      = 1
                FROM import.vw_DatabaseSyncObject x
                WHERE EXISTS (
                        SELECT @InstanceID, @DatabaseID
                        INTERSECT
                        SELECT x._InstanceID, x._DatabaseID
                    )
                    AND NOT EXISTS ( -- Don't insert duplicate records
                        SELECT *
                        FROM import.DatabaseSyncObjectStatus s
                        WHERE EXISTS (
                            SELECT s._InstanceID, s._DatabaseID
                            INTERSECT
                            SELECT x._InstanceID, x._DatabaseID
                        )
                    );

                -- TODO: Consider adding Error info to dbo.[Database] and/or dbo.Instance when DB/Instance level errors occur?
            END;
            ELSE
            BEGIN;
                -- Currently, there is no case where @SyncObjectID is null and it's not an exception
                IF (@Verbose = 1) RAISERROR('[%s] ERROR: Invalid parameters supplied to proc',16,1,@ProcName) WITH NOWAIT;
            END;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw;
    END TRY
    BEGIN CATCH
        DECLARE @ProcErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Error %d, State %d, Line %d)', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror @EventType = 'Error', @ActionName = 'Proc', @Scope1 = @ProcName, @DetailMessage = @ProcErrorMessage, @ts = @proc_sw;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
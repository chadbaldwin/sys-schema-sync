CREATE PROCEDURE import.usp_SetSyncStatus (
    @InstanceID     int,
    @DatabaseID     int = NULL,
    @SyncObjectID   int = NULL,
    @Checksum       int = NULL,
    @ErrorMessage   nvarchar(MAX) = NULL,
    @Verbose        bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    DECLARE @CurrentTime datetime2 = SYSUTCDATETIME();

    -- Including the entire exception message in the output is excessive, so reducing it down to just yes/no on IsError
    DECLARE @HasError nvarchar(10) = IIF(@ErrorMessage IS NOT NULL, 'true','false');
    IF (@Verbose = 1) RAISERROR(N'[%s] Input parameters: @InstanceID = %i, @DatabaseID = %i, @SyncObjectID = %i, @Checksum = %i, @ErrorMessage is populated: %s',0,1
        , @ProcName, @InstanceID, @DatabaseID, @SyncObjectID, @Checksum, @HasError) WITH NOWAIT;

    IF EXISTS (
        SELECT *
        FROM import.SyncObject
        WHERE SyncObjectID = @SyncObjectID
            AND ChecksumQueryText IS NOT NULL
            AND @Checksum IS NULL
    )
    BEGIN;
        -- This seems to be the easist solution for now...Prepend the existing exception with this one.
        SET @ErrorMessage = CONCAT('ERROR: Checksum value is NULL even though a ChecksumQueryText was provided. ', @ErrorMessage)
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @rc int = 0;

    IF (@SyncObjectID IS NOT NULL)
    BEGIN;
        IF (@Verbose = 1) RAISERROR('[%s] Attempting to update status record',0,1,@ProcName) WITH NOWAIT;
        IF (@ErrorMessage IS NULL)
        BEGIN;
            IF (@Verbose = 1) RAISERROR('[%s] Attempting to update status record as a successful sync',0,1,@ProcName) WITH NOWAIT;
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
            IF (@Verbose = 1) RAISERROR('[%s] Attempting to update status record as a failed sync with error message',0,1,@ProcName) WITH NOWAIT;
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
            IF (@Verbose = 1) RAISERROR('[%s] Status record doesn''t exist, creating a new one',0,1,@ProcName) WITH NOWAIT;
            IF (@ErrorMessage IS NULL)
            BEGIN;
                IF (@Verbose = 1) RAISERROR('[%s] Creating new status record as a successful sync',0,1,@ProcName) WITH NOWAIT;
                INSERT import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID, LastSyncChecksum)
                VALUES (@InstanceID, @DatabaseID, @SyncObjectID, @Checksum);
            END;
            ELSE
            BEGIN;
                IF (@Verbose = 1) RAISERROR('[%s] Creating new status record with error',0,1,@ProcName) WITH NOWAIT;
                INSERT import.DatabaseSyncObjectStatus (_InstanceID, _DatabaseID, SyncObjectID, LastSyncChecksum, LastSyncTime, LastSyncError, LastSyncErrorMessage, LastSyncWasError)
                VALUES (@InstanceID, @DatabaseID, @SyncObjectID, @Checksum, NULL, @CurrentTime, @ErrorMessage, 1);
            END;
        END;
    END;
    ELSE
    BEGIN;
        IF (@ErrorMessage IS NOT NULL)
        BEGIN;
            IF (@Verbose = 1) RAISERROR('[%s] A database wide error has occured, pushing back all syncs for database',0,1,@ProcName) WITH NOWAIT;
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
    IF (@Verbose = 1) RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO
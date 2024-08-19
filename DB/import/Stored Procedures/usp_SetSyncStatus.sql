CREATE PROCEDURE import.usp_SetSyncStatus (
    @InstanceID     int,
    @DatabaseID     int,
    @SyncObjectID   int = NULL,
    @Checksum       int = NULL,
    @ErrorMessage   nvarchar(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    -- Including the entire exception message in the output is excessive, so reducing it down to just yes/no on IsError
    DECLARE @HasError nvarchar(10) = IIF(@ErrorMessage IS NOT NULL, 'true','false');
    RAISERROR(N'[%s] Input parameters: @InstanceID = %i, @DatabaseID = %i, @SyncObjectID = %i, @Checksum = %i, @ErrorMessage is populated: %s',0,1
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
        RAISERROR('[%s] Attempting to update status record',0,1,@ProcName) WITH NOWAIT;
        IF (@ErrorMessage IS NULL)
        BEGIN;
            RAISERROR('[%s] Attempting to update status record as a successful sync',0,1,@ProcName) WITH NOWAIT;
            UPDATE x
            SET x.LastSyncChecksum      = @Checksum,
                /*  '=' logic handles NULL's, be careful changing
                    NULL exceptions are already handled above. So if either side is NULL here, it's intentional
                    and should be counted as a change. NULL on either side of '=' is false, so it is logged.

                    If both sides are NULL, then that means this SyncObject does not utilize Cheecksums, so
                    it should _always_ be logged. */
                x.LastSyncTime          = IIF(x.LastSyncChecksum = @Checksum, x.LastSyncTime, SYSUTCDATETIME()),
                x.LastSyncCheck         = SYSUTCDATETIME()
            FROM import.DatabaseSyncObjectStatus x
            WHERE EXISTS (
                    SELECT @InstanceID, @DatabaseID, @SyncObjectID
                    INTERSECT
                    SELECT x.InstanceID, x.DatabaseID, x.SyncObjectID
                );
            SET @rc = @@ROWCOUNT;
        END;
        ELSE
        BEGIN
            RAISERROR('[%s] Attempting to update status record as a failed sync with error message',0,1,@ProcName) WITH NOWAIT;
            UPDATE x
            SET x.LastSyncCheck         = SYSUTCDATETIME(),
                x.LastSyncError         = SYSUTCDATETIME(),
                x.LastSyncErrorMessage  = @ErrorMessage
            FROM import.DatabaseSyncObjectStatus x
            WHERE EXISTS (
                    SELECT @InstanceID, @DatabaseID, @SyncObjectID
                    INTERSECT
                    SELECT x.InstanceID, x.DatabaseID, x.SyncObjectID
                );
            SET @rc = @@ROWCOUNT;
        END
        ------------------------------------------------------------------------------
        
        ------------------------------------------------------------------------------
        IF (@rc = 0)
        BEGIN;
            RAISERROR('[%s] Status record doesn''t exist, creating a new one',0,1,@ProcName) WITH NOWAIT;
            IF (@ErrorMessage IS NULL)
            BEGIN;
                RAISERROR('[%s] Creating new status record as a successful sync',0,1,@ProcName) WITH NOWAIT;
                INSERT INTO import.DatabaseSyncObjectStatus (InstanceID, DatabaseID, SyncObjectID, LastSyncChecksum)
                VALUES (@InstanceID, @DatabaseID, @SyncObjectID, @Checksum);
            END;
            ELSE
            BEGIN;
                RAISERROR('[%s] Creating new status record with error',0,1,@ProcName) WITH NOWAIT;
                INSERT INTO import.DatabaseSyncObjectStatus (InstanceID, DatabaseID, SyncObjectID, LastSyncChecksum, LastSyncTime, LastSyncError, LastSyncErrorMessage)
                VALUES (@InstanceID, @DatabaseID, @SyncObjectID, @Checksum, NULL, SYSUTCDATETIME(), @ErrorMessage);
            END;
        END;
    END;
    ELSE
    BEGIN;
        IF (@ErrorMessage IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] A database wide error has occured, pushing back all syncs for database',0,1,@ProcName) WITH NOWAIT;
            /*  In this case, a database wide error is being logged which means we want to push all sync object tasks
                to prevent them from running until their next interval. */
            UPDATE x
            SET x.LastSyncCheck         = SYSUTCDATETIME(),
                x.LastSyncError         = SYSUTCDATETIME(),
                x.LastSyncErrorMessage  = @ErrorMessage
            FROM import.DatabaseSyncObjectStatus x
            WHERE EXISTS (
                    SELECT @InstanceID, @DatabaseID
                    INTERSECT
                    SELECT x.InstanceID, x.DatabaseID
                );

            INSERT INTO import.DatabaseSyncObjectStatus (InstanceID, DatabaseID, SyncObjectID, LastSyncError, LastSyncErrorMessage)
            SELECT x.InstanceID, x.DatabaseID, x.SyncObjectID
                , LastSyncError         = SYSUTCDATETIME()
                , LastSyncErrorMessage  = @ErrorMessage
            FROM import.vw_DatabaseSyncObject x
            WHERE EXISTS (
                    SELECT @InstanceID, @DatabaseID
                    INTERSECT
                    SELECT x.InstanceID, x.DatabaseID
                )
                AND NOT EXISTS ( -- Don't insert duplicate records
                    SELECT *
                    FROM import.DatabaseSyncObjectStatus s
                    WHERE EXISTS (
                        SELECT s.InstanceID, s.DatabaseID
                        INTERSECT
                        SELECT x.InstanceID, x.DatabaseID
                    )
                );

            -- TODO: Consider adding Error info to dbo.[Database] and/or dbo.Instance when DB/Instance level errors occur?
        END;
        ELSE
        BEGIN;
            -- Currently, there is no case where @SyncObjectID is null and it's not an exception
            RAISERROR('[%s] ERROR: Invalid parameters supplied to proc',16,1,@ProcName) WITH NOWAIT;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

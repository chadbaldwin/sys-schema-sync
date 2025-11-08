CREATE PROC import.usp_DatabaseSyncObjectStatus_Reset (
    @SyncObjectID int = NULL,
    @InstanceID int = NULL,
    @DatabaseID int = NULL,
    @ResetChecksum bit = 0, -- Resetting the checksum will force the data to be refreshed from the database rather than doing a checksum compare
    @ResetErrors bit = 0, -- Does not have any side effects other than clearing error state info
    @Force bit = 0 -- Allows this proc to be run without any filters, resulting in a database wide reset
)
AS
BEGIN;
    IF (COALESCE(@SyncObjectID, @InstanceID, @DatabaseID) IS NULL AND @Force = 0)
    BEGIN;
        THROW 51000, 'At least 1 paramerter needs to be populated as a filter', 1;
    END;

    UPDATE s
    SET   s.LastSyncCheck        = '1900-01-01 00:00:00.0000000'
        , s.LastSyncChecksum     = IIF(@ResetChecksum = 1, NULL, s.LastSyncChecksum)
        , s.LastSyncError        = IIF(@ResetErrors   = 1, NULL, s.LastSyncError)
        , s.LastSyncErrorMessage = IIF(@ResetErrors   = 1, NULL, s.LastSyncErrorMessage)
        , s.LastSyncWasError     = IIF(@ResetErrors   = 1, 0   , s.LastSyncWasError)
    FROM import.DatabaseSyncObjectStatus s
    WHERE   (s.SyncObjectID = @SyncObjectID OR @SyncObjectID IS NULL)
        AND (s._InstanceID  = @InstanceID   OR @InstanceID   IS NULL)
        AND (s._DatabaseID  = @DatabaseID   OR @DatabaseID   IS NULL)
        AND s.LastSyncCheck <> '1900-01-01 00:00:00.0000000'
    OPTION (RECOMPILE);
END;
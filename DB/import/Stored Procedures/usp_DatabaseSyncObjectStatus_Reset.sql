CREATE PROC import.usp_DatabaseSyncObjectStatus_Reset (
    @SyncObjectID int = NULL,
    @InstanceID int = NULL,
    @DatabaseID int = NULL
)
AS
BEGIN;
    IF COALESCE(@SyncObjectID, @InstanceID, @DatabaseID) IS NULL
    BEGIN;
        THROW 51000, 'At least 1 paramerter needs to be populated as a filter', 1;
    END;

    UPDATE s SET s.LastSyncCheck = '1900-01-01', s.LastSyncChecksum = NULL, s.LastSyncError = NULL, s.LastSyncErrorMessage = NULL
    FROM import.DatabaseSyncObjectStatus s
    WHERE   (s.SyncObjectID = @SyncObjectID OR @SyncObjectID IS NULL)
        AND (s._InstanceID  = @InstanceID   OR @InstanceID   IS NULL)
        AND (s._DatabaseID  = @DatabaseID   OR @DatabaseID   IS NULL)
    OPTION (RECOMPILE);
END;
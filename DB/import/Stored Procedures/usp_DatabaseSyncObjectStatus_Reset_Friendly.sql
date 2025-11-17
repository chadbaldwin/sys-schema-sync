CREATE PROC import.usp_DatabaseSyncObjectStatus_Reset_Friendly (
    @SyncObjectName nvarchar(128) = NULL,
    @InstanceName nvarchar(257) = NULL,
    @DatabaseName nvarchar(128) = NULL,
    @ResetChecksum bit = 0,
    @ResetErrors bit = 0
)
AS
BEGIN;
    -- TODO: Add support for filters resulting in multiple matches. Currently, only the first match is executed.
    -- Easiest solution might be to just run through a cursor.

    IF (COALESCE(@SyncObjectName, @InstanceName, @DatabaseName) IS NULL)
    BEGIN;
        THROW 51000, 'At least 1 paramerter needs to be populated as a filter', 1;
    END;

    DECLARE @SyncObjectID int,
            @InstanceID int,
            @DatabaseID int;

    SELECT @SyncObjectID = SyncObjectID FROM import.SyncObject WHERE SyncObjectName = @SyncObjectName;
    SELECT @InstanceID   = _InstanceID  FROM dbo.Instance      WHERE InstanceName = @InstanceName;
    SELECT @DatabaseID   = _DatabaseID  FROM dbo.[Database]    WHERE DatabaseName = @DatabaseName;

    IF (@SyncObjectID IS NULL AND @SyncObjectName IS NOT NULL)
    BEGIN;
        THROW 51000, 'Invalid value for @SyncObjectName', 1;
    END;

    IF (@InstanceID IS NULL AND @InstanceName IS NOT NULL)
    BEGIN;
        THROW 51000, 'Invalid value for @InstanceName', 1;
    END;

    IF (@DatabaseID IS NULL AND @DatabaseName IS NOT NULL)
    BEGIN;
        THROW 51000, 'Invalid value for @DatabaseName', 1;
    END;

    EXEC import.usp_DatabaseSyncObjectStatus_Reset @SyncObjectID = @SyncObjectID,
                                                   @InstanceID = @InstanceID,
                                                   @DatabaseID = @DatabaseID,
                                                   @ResetChecksum = @ResetChecksum,
                                                   @ResetErrors = @ResetErrors;
END;
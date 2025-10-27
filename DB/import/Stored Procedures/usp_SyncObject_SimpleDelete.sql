CREATE PROC import.usp_SyncObject_SimpleDelete (
	@SyncObjectID int,
	@InstanceID int = NULL,
	@DatabaseID int = NULL,
	@ResetSyncObject bit = 0,
	@Verbose bit = 0
)
AS
BEGIN;
	SET XACT_ABORT ON;
	------------------------------------------------------------

	------------------------------------------------------------
	-- Validate parameters
	------------------------------------------------------------
	IF NOT EXISTS (SELECT * FROM import.SyncObject WHERE SyncObjectID = @SyncObjectID)
	BEGIN;
		THROW 51000, 'Invalid SyncObjectID supplied', 1;
	END;

	IF (@InstanceID IS NULL AND @DatabaseID IS NULL)
	BEGIN;
		THROW 51000, 'Either @InstanceID or @DatabaseID must be supplied', 1;
	END;

	IF NOT EXISTS (
		SELECT *
		FROM dbo.vw_Instance vi
			LEFT JOIN dbo.vw_Database vd ON vd._InstanceID = vi._InstanceID
		WHERE   (vi._InstanceID = @InstanceiD OR @InstanceID IS NULL)
			AND (vd._DatabaseID = @DatabaseID OR @DatabaseID IS NULL)
	)
	BEGIN;
		THROW 51000, 'Instance/Database not found', 1;
	END;

	DECLARE @tablename nvarchar(300), @level tinyint;

	-- Look up table name from SyncObjectID - done this way to prevent SQL injection holes
	SELECT @tablename = QUOTENAME(OBJECT_SCHEMA_NAME(x.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(x.[object_id]))
		, @level = so.SyncObjectLevelID
	FROM import.SyncObject so
		CROSS APPLY (SELECT [object_id] = OBJECT_ID(so.ImportTable)) x
	WHERE SyncObjectID = @SyncObjectID;

	IF (@tablename IS NULL)
	BEGIN;
		THROW 51000, 'This SyncObject does not support simple deletes', 1;
	END;
	------------------------------------------------------------

	------------------------------------------------------------
	-- Perform the deletes
	------------------------------------------------------------
	DECLARE @sql nvarchar(MAX);
	IF (@level = 1 AND @InstanceID IS NOT NULL)
	BEGIN;
		SELECT @sql = REPLACE('DELETE {{table}} WHERE _InstanceID = @InstanceID;', '{{table}}', @tablename)
		EXEC sys.sp_executesql @stmt = @sql, @params = N'@InstanceID int', @InstanceID = @InstanceID;
	END;
	ELSE IF (@level = 2 AND @DatabaseID IS NOT NULL)
	BEGIN;
		SELECT @sql = REPLACE('DELETE {{table}} WHERE _DatabaseID = @DatabaseID;', '{{table}}', @tablename)
		EXEC sys.sp_executesql @stmt = @sql, @params = N'@DatabaseID int', @DatabaseID = @DatabaseID;
	END;
	ELSE
	BEGIN;
		THROW 51000, 'Unknown parameter combination', 1;
	END;

	-- Optional DatabaseSyncObject reset
	IF (@ResetSyncObject = 1)
	BEGIN;
		EXEC import.usp_DatabaseSyncObjectStatus_Reset @SyncObjectID = @SyncObjectID, @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
	END;
END;
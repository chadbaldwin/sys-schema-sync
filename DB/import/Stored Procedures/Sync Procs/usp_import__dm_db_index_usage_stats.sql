CREATE PROCEDURE import.usp_import__dm_db_index_usage_stats (
	@DatabaseID	int,
	@Dataset	import.import__dm_db_index_usage_stats READONLY
)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
	RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

	IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
	SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

	DECLARE @input  import.ItemName,
			@output import.ItemName;

	-- object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
	SELECT ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM #Dataset;

	INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_usage_stats';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x FROM dbo._dm_db_index_usage_stats x
	WHERE x._DatabaseID = @DatabaseID
		AND NOT EXISTS (SELECT * FROM @output o WHERE o.IndexID = x._IndexID);
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._ModifyDate			= SYSUTCDATETIME()
		, x._RowHash			= d._RowHash
		--
		, x.database_id			= d.database_id
		, x.[object_id]			= d.[object_id]
		, x.index_id			= d.index_id
		, x.user_seeks			= d.user_seeks
		, x.user_scans			= d.user_scans
		, x.user_lookups		= d.user_lookups
		, x.user_updates		= d.user_updates
		, x.last_user_seek		= COALESCE(d.last_user_seek, x.last_user_seek)
		, x.last_user_scan		= COALESCE(d.last_user_scan, x.last_user_scan)
		, x.last_user_lookup	= COALESCE(d.last_user_lookup, x.last_user_lookup)
		, x.last_user_update	= COALESCE(d.last_user_update, x.last_user_update)
		, x.system_seeks		= d.system_seeks
		, x.system_scans		= d.system_scans
		, x.system_lookups		= d.system_lookups
		, x.system_updates		= d.system_updates
		, x.last_system_seek	= COALESCE(d.last_system_seek, x.last_system_seek)
		, x.last_system_scan	= COALESCE(d.last_system_scan, x.last_system_scan)
		, x.last_system_lookup	= COALESCE(d.last_system_lookup, x.last_system_lookup)
		, x.last_system_update	= COALESCE(d.last_system_update, x.last_system_update)
	FROM dbo._dm_db_index_usage_stats x
		JOIN @output y ON y.IndexID = x._IndexID
		JOIN #Dataset d ON d.ID = y.ID
	WHERE x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._dm_db_index_usage_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash
		, database_id, [object_id], index_id, user_seeks, user_scans, user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update, system_seeks, system_scans, system_lookups, system_updates, last_system_seek, last_system_scan, last_system_lookup, last_system_update)
	SELECT @DatabaseID, y.ObjectID, y.IndexID, d._RowHash
		, d.database_id, d.[object_id], d.index_id, d.user_seeks, d.user_scans, d.user_lookups, d.user_updates, d.last_user_seek, d.last_user_scan, d.last_user_lookup, d.last_user_update, d.system_seeks, d.system_scans, d.system_lookups, d.system_updates, d.last_system_seek, d.last_system_scan, d.last_system_lookup, d.last_system_update
	FROM #Dataset d
		JOIN @output y ON y.ID = d.ID
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._dm_db_index_usage_stats x
			WHERE x._IndexID  = y.IndexID
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

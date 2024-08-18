CREATE PROCEDURE import.usp_import__master_files (
	@InstanceID	int,
	@Dataset	import.import__master_files READONLY
)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
	RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

	IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._master_files';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x
	FROM dbo._master_files x
	WHERE x._InstanceID = @InstanceID
		AND NOT EXISTS (
			SELECT *
			FROM @Dataset d
			WHERE d._DatabaseName = x._DatabaseName AND d.[file_id] = x.[file_id]
		)
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._DatabaseID					= sd.DatabaseID
		, x._ModifyDate					= SYSUTCDATETIME()
		, x._RowHash					= d._RowHash
		, x._DatabaseName				= d._DatabaseName
		--
		, x.database_id					= d.database_id
		, x.[file_id]					= d.[file_id]
		, x.file_guid					= d.file_guid
		, x.[type]						= d.[type]
		, x.[type_desc]					= d.[type_desc]
		, x.data_space_id				= d.data_space_id
		, x.[name]						= d.[name]
		, x.physical_name				= d.physical_name
		, x.[state]						= d.[state]
		, x.state_desc					= d.state_desc
		, x.size						= d.size
		, x.max_size					= d.max_size
		, x.growth						= d.growth
		, x.is_media_read_only			= d.is_media_read_only
		, x.is_read_only				= d.is_read_only
		, x.is_sparse					= d.is_sparse
		, x.is_percent_growth			= d.is_percent_growth
		, x.is_name_reserved			= d.is_name_reserved
		, x.is_persistent_log_buffer	= d.is_persistent_log_buffer
		, x.create_lsn					= d.create_lsn
		, x.drop_lsn					= d.drop_lsn
		, x.read_only_lsn				= d.read_only_lsn
		, x.read_write_lsn				= d.read_write_lsn
		, x.differential_base_lsn		= d.differential_base_lsn
		, x.differential_base_guid		= d.differential_base_guid
		, x.differential_base_time		= d.differential_base_time
		, x.redo_start_lsn				= d.redo_start_lsn
		, x.redo_start_fork_guid		= d.redo_start_fork_guid
		, x.redo_target_lsn				= d.redo_target_lsn
		, x.redo_target_fork_guid		= d.redo_target_fork_guid
		, x.backup_lsn					= d.backup_lsn
		, x.credential_id				= d.credential_id
	FROM dbo._master_files x
		JOIN @Dataset d ON d._DatabaseName = x._DatabaseName AND d.[file_id] = x.[file_id]
		LEFT JOIN dbo.[Database] sd ON sd.InstanceID = @InstanceID AND sd.DatabaseName = d._DatabaseName -- Get DatabaseID for ones we do sync
	WHERE x._InstanceID = @InstanceID
		AND x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._master_files (_InstanceID, _DatabaseID, _RowHash, _DatabaseName
		, database_id, [file_id], file_guid, [type], [type_desc], data_space_id, [name], physical_name, [state], state_desc, size, max_size, growth, is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, is_persistent_log_buffer, create_lsn, drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid, differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, credential_id)
	SELECT @InstanceID, sd.DatabaseID, d._RowHash, d._DatabaseName
		, d.database_id, d.[file_id], d.file_guid, d.[type], d.[type_desc], d.data_space_id, d.[name], d.physical_name, d.[state], d.state_desc, d.size, d.max_size, d.growth, d.is_media_read_only, d.is_read_only, d.is_sparse, d.is_percent_growth, d.is_name_reserved, d.is_persistent_log_buffer, d.create_lsn, d.drop_lsn, d.read_only_lsn, d.read_write_lsn, d.differential_base_lsn, d.differential_base_guid, d.differential_base_time, d.redo_start_lsn, d.redo_start_fork_guid, d.redo_target_lsn, d.redo_target_fork_guid, d.backup_lsn, d.credential_id
	FROM @Dataset d
		LEFT JOIN dbo.[Database] sd ON sd.InstanceID = @InstanceID AND sd.DatabaseName = d._DatabaseName -- Get DatabaseID for ones we do sync
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._master_files x
			WHERE x._InstanceID = @InstanceID
				AND x._DatabaseName = d._DatabaseName AND x.[file_id] = d.[file_id]
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

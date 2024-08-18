CREATE PROCEDURE import.usp_import__sysarticles (
	@DatabaseID	int,
	@Dataset	import.import__sysarticles READONLY
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
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
	SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

	INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._sysarticles';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x FROM dbo._sysarticles x
	WHERE x._DatabaseID = @DatabaseID
		AND NOT EXISTS (
			SELECT *
			FROM @output o
				JOIN #Dataset d ON d.ID = o.ID
			WHERE o.ObjectID = x._ObjectID
				AND d.artid = x.artid
		);
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._ModifyDate					= SYSUTCDATETIME()
		, x._RowHash					= d._RowHash
		--
		, x.artid						= d.artid
		, x.creation_script				= d.creation_script
		, x.del_cmd						= d.del_cmd
		, x.[description]				= d.[description]
		, x.dest_table					= d.dest_table
		, x.[filter]					= d.[filter]
		, x.filter_clause				= d.filter_clause
		, x.ins_cmd						= d.ins_cmd
		, x.[name]						= d.[name]
		, x.[objid]						= d.[objid]
		, x.pubid						= d.pubid
		, x.pre_creation_cmd			= d.pre_creation_cmd
		, x.[status]					= d.[status]
		, x.sync_objid					= d.sync_objid
		, x.[type]						= d.[type]
		, x.upd_cmd						= d.upd_cmd
		, x.schema_option				= d.schema_option
		, x.dest_owner					= d.dest_owner
		, x.ins_scripting_proc			= d.ins_scripting_proc
		, x.del_scripting_proc			= d.del_scripting_proc
		, x.upd_scripting_proc			= d.upd_scripting_proc
		, x.custom_script				= d.custom_script
		, x.fire_triggers_on_snapshot	= d.fire_triggers_on_snapshot
	FROM dbo._sysarticles x
		JOIN @output y ON y.ObjectID = x._ObjectID
		JOIN #Dataset d ON d.ID = y.ID AND d.artid = x.artid
	WHERE x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._sysarticles (_DatabaseID, _ObjectID, _RowHash
		, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
	SELECT @DatabaseID, y.ObjectID, d._RowHash
		, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
	FROM #Dataset d
		JOIN @output y ON y.ID = d.ID
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._sysarticles x
			WHERE x._ObjectID = y.ObjectID
				AND x.artid = d.artid
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

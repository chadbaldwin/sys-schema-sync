CREATE PROCEDURE import.usp_import__configurations (
	@InstanceID	int,
	@Dataset	import.import__configurations READONLY
)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
	RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

	IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._configurations';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x
	FROM dbo._configurations x
	WHERE x._InstanceID = @InstanceID
		AND NOT EXISTS (
			SELECT *
			FROM @Dataset d
			WHERE d.configuration_id = x.configuration_id
		)
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._ModifyDate		= SYSUTCDATETIME()
		, x._RowHash		= d._RowHash
		--
		, x.[name]			= d.[name]
		, x.[value]			= d.[value]
		, x.minimum			= d.minimum
		, x.maximum			= d.maximum
		, x.value_in_use	= d.value_in_use
		, x.[description]	= d.[description]
		, x.is_dynamic		= d.is_dynamic
		, x.is_advanced		= d.is_advanced
	FROM dbo._configurations x
		JOIN @Dataset d ON d.configuration_id = x.configuration_id
	WHERE x._InstanceID = @InstanceID
		AND x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._configurations (_InstanceID, _RowHash, configuration_id, [name], [value], minimum, maximum, value_in_use, [description], is_dynamic, is_advanced)
	SELECT @InstanceID, d._RowHash, d.configuration_id, d.[name], d.[value], d.minimum, d.maximum, d.value_in_use, d.[description], d.is_dynamic, d.is_advanced
	FROM @Dataset d
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._configurations x
			WHERE x._InstanceID = @InstanceID
				AND x.configuration_id = d.configuration_id
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

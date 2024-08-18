CREATE PROCEDURE import.usp_import__default_constraints (
	@DatabaseID	int,
	@Dataset	import.import__default_constraints READONLY
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
			@output import.ItemName,
			@parent import.ItemName;

	-- object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
	SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

	INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

	DELETE @input;

	-- parent object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
	SELECT ID, _SchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM #Dataset;

	INSERT INTO @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._default_constraints';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x FROM dbo._default_constraints x
	WHERE x._DatabaseID = @DatabaseID
		AND NOT EXISTS (SELECT * FROM @output o WHERE o.ObjectID = x._ObjectID);
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._ParentObjectID			= p.ObjectID
		, x._ParentColumnID			= p.ColumnID
		, x._ModifyDate				= SYSUTCDATETIME()
		, x._RowHash				= d._RowHash
		--
		, x.[name]					= d.[name]
		, x.[object_id]				= d.[object_id]
		, x.principal_id			= d.principal_id
		, x.[schema_id]				= d.[schema_id]
		, x.parent_object_id		= d.parent_object_id
		, x.[type]					= d.[type]
		, x.[type_desc]				= d.[type_desc]
		, x.create_date				= d.create_date
		, x.modify_date				= d.modify_date
		, x.is_ms_shipped			= d.is_ms_shipped
		, x.is_published			= d.is_published
		, x.is_schema_published		= d.is_schema_published
		--
		, x.parent_column_id		= d.parent_column_id
		, x.[definition]			= d.[definition]
		, x.is_system_named			= d.is_system_named
	FROM dbo._default_constraints x
		JOIN @output y ON y.ObjectID = x._ObjectID
		JOIN #Dataset d ON d.ID = y.ID
		JOIN @parent p ON p.ID = y.ID
	WHERE x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._default_constraints (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash
		, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published
		, parent_column_id, [definition], is_system_named)
	SELECT @DatabaseID, y.ObjectID, p.ObjectID, p.ColumnID, d._RowHash
		, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published
		, d.parent_column_id, d.[definition], d.is_system_named
	FROM #Dataset d
		JOIN @output y ON y.ID = d.ID
		JOIN @parent p ON p.ID = d.ID
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._default_constraints x
			WHERE x._ObjectID  = y.ObjectID
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

CREATE PROCEDURE import.usp_import__foreign_keys (
	@DatabaseID	int,
	@Dataset	import.import__foreign_keys READONLY
)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
	RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

	IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Create missing object and get IDs',0,1,@ProcName) WITH NOWAIT;

	IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
	SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

	DECLARE @input     import.ItemName,
			@output    import.ItemName,
			@parent    import.ItemName,
			@reference import.ItemName;

	-- object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
	SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

	INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

	DELETE @input;

	-- parent object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
	SELECT ID, _ParentSchemaName, _ParentObjectName, _ParentObjectType FROM #Dataset;

	INSERT INTO @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

	DELETE @input;

	-- reference object
	INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
	SELECT ID, _ReferencedSchemaName, _ReferencedObjectName, _ReferencedObjectType, _ReferencedIndexName FROM #Dataset;

	INSERT INTO @reference (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
	EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	DECLARE @tableName nvarchar(128) = N'dbo._foreign_keys';

	RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	DELETE x FROM dbo._foreign_keys x
	WHERE x._DatabaseID = @DatabaseID
		AND NOT EXISTS (SELECT * FROM @output o WHERE o.ObjectID = x._ObjectID);
	RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	UPDATE x
	SET   x._ParentObjectID					= p.ObjectID
		, x._ReferencedObjectID				= r.ObjectID
		, x._ReferencedIndexID				= r.IndexID
		, x._ModifyDate						= SYSUTCDATETIME()
		, x._RowHash						= d._RowHash
		--
		, x.[name]							= d.[name]
		, x.[object_id]						= d.[object_id]
		, x.principal_id					= d.principal_id
		, x.[schema_id]						= d.[schema_id]
		, x.parent_object_id				= d.parent_object_id
		, x.[type]							= d.[type]
		, x.[type_desc]						= d.[type_desc]
		, x.create_date						= d.create_date
		, x.modify_date						= d.modify_date
		, x.is_ms_shipped					= d.is_ms_shipped
		, x.is_published					= d.is_published
		, x.is_schema_published				= d.is_schema_published
		--
		, x.referenced_object_id			= d.referenced_object_id
		, x.key_index_id					= d.key_index_id
		, x.is_disabled						= d.is_disabled
		, x.is_not_for_replication			= d.is_not_for_replication
		, x.is_not_trusted					= d.is_not_trusted
		, x.delete_referential_action		= d.delete_referential_action
		, x.delete_referential_action_desc	= d.delete_referential_action_desc
		, x.update_referential_action		= d.update_referential_action
		, x.update_referential_action_desc	= d.update_referential_action_desc
		, x.is_system_named					= d.is_system_named
	FROM dbo._foreign_keys x
		JOIN @output y ON y.ObjectID = x._ObjectID
		JOIN #Dataset d ON d.ID = y.ID
		JOIN @parent p ON p.ID = y.ID
		JOIN @reference r ON r.ID = y.ID
	WHERE x._RowHash <> d._RowHash;
	RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

	RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
	INSERT INTO dbo._foreign_keys (_DatabaseID, _ObjectID, _ParentObjectID, _ReferencedObjectID, _ReferencedIndexID, _RowHash
		, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published
		, referenced_object_id, key_index_id, is_disabled, is_not_for_replication, is_not_trusted, delete_referential_action, delete_referential_action_desc, update_referential_action, update_referential_action_desc, is_system_named)
	SELECT @DatabaseID, y.ObjectID, p.ObjectID, r.ObjectID, r.IndexID, d._RowHash
		, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published
		, d.referenced_object_id, d.key_index_id, d.is_disabled, d.is_not_for_replication, d.is_not_trusted, d.delete_referential_action, d.delete_referential_action_desc, d.update_referential_action, d.update_referential_action_desc, d.is_system_named
	FROM #Dataset d
		JOIN @output y ON y.ID = d.ID
		JOIN @parent p ON p.ID = d.ID
		JOIN @reference r ON r.ID = d.ID
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo._foreign_keys x
			WHERE x._ObjectID  = y.ObjectID
		);
	RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

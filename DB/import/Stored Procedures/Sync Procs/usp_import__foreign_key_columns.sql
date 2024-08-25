CREATE PROCEDURE import.usp_import__foreign_key_columns (
    @DatabaseID int,
    @Dataset    import.import__foreign_key_columns READONLY
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

    DECLARE @input     import.ItemName,
            @output    import.ItemName,
            @parent    import.ItemName,
            @reference import.ItemName;

    -- object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

    DELETE @input;

    -- parent object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
    SELECT ID, _ParentSchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM #Dataset;

    INSERT INTO @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

    DELETE @input;

    -- reference object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
    SELECT ID, _ReferencedSchemaName, _ReferencedObjectName, _ReferencedObjectType, _ReferencedColumnName FROM #Dataset;

    INSERT INTO @reference (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._foreign_key_columns';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._foreign_keys x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ParentObjectID         = p._ObjectID
        , x._ParentColumnID         = p._ColumnID
        , x._ReferencedObjectID     = r._ObjectID
        , x._ReferencedColumnID     = r._ColumnID
        , x._ModifyDate             = SYSUTCDATETIME()
        , x._RowHash                = d._RowHash
        --
        , x.constraint_object_id    = d.constraint_object_id
        , x.constraint_column_id    = d.constraint_column_id
        , x.parent_object_id        = d.parent_object_id
        , x.parent_column_id        = d.parent_column_id
        , x.referenced_object_id    = d.referenced_object_id
        , x.referenced_column_id    = d.referenced_column_id
    FROM dbo._foreign_key_columns x
        JOIN @output y ON y._ObjectID = x._ObjectID
        JOIN #Dataset d ON d.ID = y.ID AND d.constraint_column_id = x.constraint_column_id
        JOIN @parent p ON p.ID = y.ID
        JOIN @reference r ON r.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._foreign_key_columns (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _ReferencedObjectID, _ReferencedColumnID, _RowHash
        , constraint_object_id, constraint_column_id, parent_object_id, parent_column_id, referenced_object_id, referenced_column_id)
    SELECT @DatabaseID, y._ObjectID, p._ObjectID, p._ColumnID, r._ObjectID, r._ColumnID, d._RowHash
        , d.constraint_object_id, d.constraint_column_id, d.parent_object_id, d.parent_column_id, d.referenced_object_id, d.referenced_column_id
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
        JOIN @parent p ON p.ID = d.ID
        JOIN @reference r ON r.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._foreign_key_columns x
            WHERE x._ObjectID  = y._ObjectID AND x.constraint_column_id = d.constraint_column_id
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

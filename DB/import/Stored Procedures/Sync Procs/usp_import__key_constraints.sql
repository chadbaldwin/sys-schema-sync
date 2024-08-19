CREATE PROCEDURE import.usp_import__key_constraints (
    @DatabaseID int,
    @Dataset    import.import__key_constraints READONLY
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
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT ID, _SchemaName, _ParentObjectName, _ParentObjectType, _UniqueIndexName FROM #Dataset;

    INSERT INTO @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._key_constraints';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._key_constraints x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o.ObjectID = x._ObjectID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._IndexID            = p.IndexID
        , x._ParentObjectID     = p.ObjectID
        , x._ModifyDate         = SYSUTCDATETIME()
        , x._RowHash            = d._RowHash
        --
        , x.[name]              = d.[name]
        , x.[object_id]         = d.[object_id]
        , x.principal_id        = d.principal_id
        , x.[schema_id]         = d.[schema_id]
        , x.parent_object_id    = d.parent_object_id
        , x.[type]              = d.[type]
        , x.[type_desc]         = d.[type_desc]
        , x.create_date         = d.create_date
        , x.modify_date         = d.modify_date
        , x.is_ms_shipped       = d.is_ms_shipped
        , x.is_published        = d.is_published
        , x.is_schema_published = d.is_schema_published
        --
        , x.unique_index_id     = d.unique_index_id
        , x.is_system_named     = d.is_system_named
        , x.is_enforced         = d.is_enforced
    FROM dbo._key_constraints x
        JOIN @output y ON y.ObjectID = x._ObjectID
        JOIN #Dataset d ON d.ID = y.ID
        JOIN @parent p ON p.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._key_constraints (_DatabaseID, _ObjectID, _IndexID, _ParentObjectID, _RowHash
        , [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published
        , unique_index_id, is_system_named, is_enforced)
    SELECT @DatabaseID, y.ObjectID, p.IndexID, p.ObjectID, d._RowHash
        , d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published
        , d.unique_index_id, d.is_system_named, d.is_enforced
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
        JOIN @parent p ON p.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._key_constraints x
            WHERE x._ObjectID  = y.ObjectID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

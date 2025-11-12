CREATE PROCEDURE import.usp_import__key_constraints (
    @DatabaseID int,
    @Dataset    import.import__key_constraints READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @input  import.ItemName,
            @output import.ItemName,
            @parent import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    DELETE @input;

    -- parent object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT __ID, _SchemaName, _ParentObjectName, _ParentObjectType, _UniqueIndexName FROM @Dataset;

    INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT _DatabaseID    = @DatabaseID
        , _ObjectID       = o._ObjectID
        , _IndexID        = p._IndexID
        , _ParentObjectID = p._ObjectID
        , d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.unique_index_id, d.is_system_named, d.is_enforced
    INTO #tmp_Dataset
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID
        JOIN @parent p ON p.ID = d.__ID;

    CREATE INDEX IX ON #tmp_Dataset (_DatabaseID, _ObjectID);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._key_constraints';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._key_constraints x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #tmp_Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET x._IndexID            = d._IndexID
          , x._ParentObjectID     = d._ParentObjectID
          , x._ModifyDate         = SYSUTCDATETIME()
          , x._RowHash            = d._RowHash
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
          , x.unique_index_id     = d.unique_index_id
          , x.is_system_named     = d.is_system_named
          , x.is_enforced         = d.is_enforced
        FROM dbo._key_constraints x
            JOIN #tmp_Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._key_constraints (_DatabaseID, _ObjectID, _IndexID, _ParentObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, unique_index_id, is_system_named, is_enforced)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._ParentObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.unique_index_id, d.is_system_named, d.is_enforced
        FROM #tmp_Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._key_constraints x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
CREATE PROCEDURE import.usp_import__triggers (
    @DatabaseID int,
    @Dataset    import.import__triggers READONLY,
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
    INSERT @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT __ID, _SchemaName, _ParentObjectName, _ParentObjectType FROM @Dataset WHERE _ParentObjectName IS NOT NULL;

    INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT TOP (0) * INTO #Dataset FROM dbo._triggers;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
    CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

    INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _RowHash, [name], [object_id], parent_class, parent_class_desc, parent_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_disabled, is_not_for_replication, is_instead_of_trigger)
    SELECT @DatabaseID, o._ObjectID, p._ObjectID, d._RowHash, d.[name], d.[object_id], d.parent_class, d.parent_class_desc, d.parent_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_disabled, d.is_not_for_replication, d.is_instead_of_trigger
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID
        LEFT JOIN @parent p ON p.ID = d.__ID;
------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._triggers';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._triggers x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET x._ParentObjectID        = d._ParentObjectID
          , x._ModifyDate            = SYSUTCDATETIME()
          , x._RowHash               = d._RowHash
          , x.[name]                 = d.[name]
          , x.[object_id]            = d.[object_id]
          , x.parent_class           = d.parent_class
          , x.parent_class_desc      = d.parent_class_desc
          , x.parent_id              = d.parent_id
          , x.[type]                 = d.[type]
          , x.[type_desc]            = d.[type_desc]
          , x.create_date            = d.create_date
          , x.modify_date            = d.modify_date
          , x.is_ms_shipped          = d.is_ms_shipped
          , x.is_disabled            = d.is_disabled
          , x.is_not_for_replication = d.is_not_for_replication
          , x.is_instead_of_trigger  = d.is_instead_of_trigger
        FROM dbo._triggers x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._triggers (_DatabaseID, _ObjectID, _ParentObjectID, _RowHash, [name], [object_id], parent_class, parent_class_desc, parent_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_disabled, is_not_for_replication, is_instead_of_trigger)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._RowHash, d.[name], d.[object_id], d.parent_class, d.parent_class_desc, d.parent_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_disabled, d.is_not_for_replication, d.is_instead_of_trigger
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._triggers x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
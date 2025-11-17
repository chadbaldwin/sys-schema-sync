CREATE PROCEDURE import.usp_import__default_constraints (
    @DatabaseID int,
    @Dataset    import.import__default_constraints READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
        DECLARE @input  import.ItemName,
                @output import.ItemName,
                @parent import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        DELETE @input;

        -- parent object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
        SELECT __ID, _SchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM @Dataset;

        INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._default_constraints;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, parent_column_id, [definition], is_system_named)
        SELECT @DatabaseID, o._ObjectID, p._ObjectID, p._ColumnID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.parent_column_id, d.[definition], d.is_system_named
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID
            JOIN @parent p ON p.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._default_constraints';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._default_constraints x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ParentObjectID     = d._ParentObjectID
          , x._ParentColumnID     = d._ParentColumnID
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
          , x.parent_column_id    = d.parent_column_id
          , x.[definition]        = d.[definition]
          , x.is_system_named     = d.is_system_named
        FROM dbo._default_constraints x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._default_constraints (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, parent_column_id, [definition], is_system_named)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._ParentColumnID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.parent_column_id, d.[definition], d.is_system_named
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._default_constraints x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
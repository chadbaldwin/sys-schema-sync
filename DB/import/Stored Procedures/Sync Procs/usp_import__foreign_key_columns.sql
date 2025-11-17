CREATE PROCEDURE import.usp_import__foreign_key_columns (
    @DatabaseID int,
    @Dataset    import.import__foreign_key_columns READONLY,
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
        DECLARE @input     import.ItemName,
                @output    import.ItemName,
                @parent    import.ItemName,
                @reference import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        DELETE @input;

        -- parent object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
        SELECT __ID, _ParentSchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM @Dataset;

        INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        DELETE @input;

        -- reference object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
        SELECT __ID, _ReferencedSchemaName, _ReferencedObjectName, _ReferencedObjectType, _ReferencedColumnName FROM @Dataset;

        INSERT @reference (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._foreign_key_columns;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, constraint_column_id);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _ReferencedObjectID, _ReferencedColumnID, _RowHash, constraint_object_id, constraint_column_id, parent_object_id, parent_column_id, referenced_object_id, referenced_column_id)
        SELECT @DatabaseID, o._ObjectID, p._ObjectID, p._ColumnID, r._ObjectID, r._ColumnID, d._RowHash, d.constraint_object_id, d.constraint_column_id, d.parent_object_id, d.parent_column_id, d.referenced_object_id, d.referenced_column_id
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID
            JOIN @parent p ON p.ID = d.__ID
            JOIN @reference r ON r.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._foreign_key_columns';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._foreign_key_columns x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.constraint_column_id = x.constraint_column_id);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ParentObjectID      = d._ParentObjectID
          , x._ParentColumnID      = d._ParentColumnID
          , x._ReferencedObjectID  = d._ReferencedObjectID
          , x._ReferencedColumnID  = d._ReferencedColumnID
          , x._ModifyDate          = SYSUTCDATETIME()
          , x._RowHash             = d._RowHash
          , x.constraint_object_id = d.constraint_object_id
          , x.parent_object_id     = d.parent_object_id
          , x.parent_column_id     = d.parent_column_id
          , x.referenced_object_id = d.referenced_object_id
          , x.referenced_column_id = d.referenced_column_id
        FROM dbo._foreign_key_columns x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.constraint_column_id = x.constraint_column_id
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._foreign_key_columns (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _ReferencedObjectID, _ReferencedColumnID, _RowHash, constraint_object_id, constraint_column_id, parent_object_id, parent_column_id, referenced_object_id, referenced_column_id)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._ParentColumnID, d._ReferencedObjectID, d._ReferencedColumnID, d._RowHash, d.constraint_object_id, d.constraint_column_id, d.parent_object_id, d.parent_column_id, d.referenced_object_id, d.referenced_column_id
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._foreign_key_columns x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.constraint_column_id = x.constraint_column_id);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
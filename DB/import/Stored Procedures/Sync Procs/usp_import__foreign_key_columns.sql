CREATE PROCEDURE import.usp_import__foreign_key_columns (
    @DatabaseID int,
    @Dataset    import.import__foreign_key_columns READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            -- parent object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey2 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
            SELECT @ProcessKey2, __ID, @DatabaseID, _ParentSchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey2;
            ----------------------------------------

            ----------------------------------------
            -- referenced object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey3 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
            SELECT @ProcessKey3, __ID, @DatabaseID, _ReferencedSchemaName, _ReferencedObjectName, _ReferencedObjectType, _ReferencedColumnName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey3;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._foreign_key_columns;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, constraint_column_id);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _ReferencedObjectID, _ReferencedColumnID, _RowHash, constraint_object_id, constraint_column_id, parent_object_id, parent_column_id, referenced_object_id, referenced_column_id)
            SELECT @DatabaseID, o._ObjectID, p._ObjectID, p._ColumnID, r._ObjectID, r._ColumnID, d._RowHash, d.constraint_object_id, d.constraint_column_id, d.parent_object_id, d.parent_column_id, d.referenced_object_id, d.referenced_column_id
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID
                JOIN import.ItemNameProcess p ON p.ProcessKey = @ProcessKey2 AND p.ID = d.__ID
                JOIN import.ItemNameProcess r ON r.ProcessKey = @ProcessKey3 AND r.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1, @ProcessKey2, @ProcessKey3);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._foreign_key_columns';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._foreign_key_columns x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.constraint_column_id = x.constraint_column_id);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
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
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._foreign_key_columns (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _ReferencedObjectID, _ReferencedColumnID, _RowHash, constraint_object_id, constraint_column_id, parent_object_id, parent_column_id, referenced_object_id, referenced_column_id)
            SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._ParentColumnID, d._ReferencedObjectID, d._ReferencedColumnID, d._RowHash, d.constraint_object_id, d.constraint_column_id, d.parent_object_id, d.parent_column_id, d.referenced_object_id, d.referenced_column_id
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._foreign_key_columns x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.constraint_column_id = x.constraint_column_id);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
GO
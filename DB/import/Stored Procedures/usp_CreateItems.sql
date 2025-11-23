CREATE PROCEDURE import.usp_CreateItems (
    @DatabaseID         int,
    @ProcessKey         uniqueidentifier,
    @FullImport_Object  bit = 0,
    @FullImport_Index   bit = 0,
    @FullImport_Column  bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Proc', NULL, NULL, @ProcName;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Perform inserts
        ------------------------------------------------------------------------------
        BEGIN;
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Object';
                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                INSERT dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
                SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey
                EXCEPT
                SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM dbo.[Object] WHERE _DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

                UPDATE x SET x._ObjectID = o._ObjectID
                FROM import.ItemNameProcess x
                    JOIN dbo.[Object] o ON o._DatabaseID = x._DatabaseID
                                       AND o.SchemaName  = x.SchemaName
                                       AND o.ObjectName  = x.ObjectName
                                       AND o.ObjectType  = x.ObjectType
                WHERE x.ProcessKey = @ProcessKey;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND IndexName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Index';
                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                INSERT dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
                SELECT d._DatabaseID, d._ObjectID, d.IndexName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.IndexName IS NOT NULL
                EXCEPT
                SELECT _DatabaseID, _ObjectID, IndexName FROM dbo.[Index] WHERE _DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

                UPDATE x SET x._IndexID = i._IndexID
                FROM import.ItemNameProcess x
                    JOIN dbo.[Index] i ON i._DatabaseID = x._DatabaseID
                                      AND i._ObjectID   = x._ObjectID
                                      AND i.IndexName   = x.IndexName
                WHERE x.ProcessKey = @ProcessKey;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ColumnName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Column';
                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                INSERT dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
                SELECT d._DatabaseID, d._ObjectID, d.ColumnName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.ColumnName IS NOT NULL
                EXCEPT
                SELECT _DatabaseID, _ObjectID, ColumnName FROM dbo.[Column] WHERE _DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

                UPDATE x SET x._ColumnID = c._ColumnID
                FROM import.ItemNameProcess x
                    JOIN dbo.[Column] c ON c._DatabaseID = x._DatabaseID
                                       AND c._ObjectID   = x._ObjectID
                                       AND c.ColumnName  = x.ColumnName
                WHERE x.ProcessKey = @ProcessKey;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectDefinitionHash IS NOT NULL)
            BEGIN;
                UPDATE x SET x._ObjectDefinitionID = od._ObjectDefinitionID
                FROM import.ItemNameProcess x
                    JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = x.ObjectDefinitionHash
                WHERE x.ProcessKey = @ProcessKey;
            END;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Perform updates and deletes
        ------------------------------------------------------------------------------
        BEGIN;
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Object';
                IF (@FullImport_Object = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark deleted', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                    -- TODO: Revert back to retreive _then_ update. Doing it all in one go causes locks and deadlocks
                    UPDATE x
                    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                    FROM dbo.[Object] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess p WHERE p.ProcessKey = @ProcessKey AND p._DatabaseID = x._DatabaseID AND p._ObjectID = x._ObjectID)
                        AND x.IsDeleted = 0
                        AND x.SchemaName <> '<<DB>>'
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark deleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
                END;

                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark undeleted', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 0, x.DeleteDate = NULL
                FROM dbo.[Object] x
                WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID)
                    AND x.IsDeleted = 1;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark undeleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND IndexName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Index';
                IF (@FullImport_Index = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark deleted', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                    -- TODO: Revert back to retreive _then_ update. Doing it all in one go causes locks and deadlocks
                    UPDATE x
                    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                    FROM dbo.[Index] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                        AND x.IsDeleted = 0;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark deleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
                END;

                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark undeleted', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 0, x.DeleteDate = NULL
                FROM dbo.[Index] x
                WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                    AND x.IsDeleted = 1;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark undeleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ColumnName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Column';
                IF (@FullImport_Column = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark deleted', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();
                    -- TODO: Revert back to retreive _then_ update. Doing it all in one go @ProcName, @TableName locks and deadlocks
                    UPDATE x
                    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                    FROM dbo.[Column] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID)
                        AND x.IsDeleted = 0;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark deleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
                END;

                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark undeleted', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 0, x.DeleteDate = NULL
                FROM dbo.[Column] x
                WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID)
                    AND x.IsDeleted = 1;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark undeleted', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            END;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Proc', @sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @CaughtErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Proc - %s', @sw, NULL, @ProcName, @CaughtErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
GO
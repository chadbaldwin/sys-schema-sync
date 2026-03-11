CREATE PROC import.usp_CreateItems (
    @DatabaseID         int,
    @ProcessKey         uniqueidentifier,
    @FullImport_Object  bit = 0,
    @FullImport_Index   bit = 0,
    @FullImport_Column  bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'_DatabaseID', @value = @DatabaseID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2, @sw3 datetime2, @rc int, @BatchSize int = 5000;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Perform inserts
        ------------------------------------------------------------------------------
        BEGIN;
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Object';
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                INSERT dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
                SELECT DISTINCT i._DatabaseID, i.SchemaName, i.ObjectName, i.ObjectType
                FROM import.ItemNameProcess i
                WHERE i.ProcessKey = @ProcessKey
                    AND NOT EXISTS (
                        SELECT *
                        FROM dbo.[Object] o
                        WHERE o._DatabaseID = i._DatabaseID
                            AND o.SchemaName = i.SchemaName
                            AND o.ObjectName = i.ObjectName
                            AND o.ObjectType = i.ObjectType
                    );
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

                SELECT @TableName = 'import.ItemNameProcess', @rc = NULL;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ObjectID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                WHILE (@rc > 0 OR @rc IS NULL)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ObjectID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3 OUTPUT;
                    UPDATE TOP(@BatchSize) x SET x._ObjectID = o._ObjectID
                    FROM import.ItemNameProcess x
                        JOIN dbo.[Object] o ON o._DatabaseID = x._DatabaseID
                                           AND o.SchemaName  = x.SchemaName
                                           AND o.ObjectName  = x.ObjectName
                                           AND o.ObjectType  = x.ObjectType
                    WHERE x.ProcessKey = @ProcessKey
                        AND x._ObjectID IS NULL;
                    SET @rc = @@ROWCOUNT;
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ObjectID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3, @rc = @rc;
                END;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ObjectID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND IndexName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Index';
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                INSERT dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
                SELECT d._DatabaseID, d._ObjectID, d.IndexName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.IndexName IS NOT NULL
                EXCEPT
                SELECT _DatabaseID, _ObjectID, IndexName FROM dbo.[Index] WHERE _DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

                SELECT @TableName = 'import.ItemNameProcess', @rc = NULL;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _IndexID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                WHILE (@rc > 0 OR @rc IS NULL)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _IndexID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3 OUTPUT;
                    UPDATE TOP(@BatchSize) x SET x._IndexID = i._IndexID
                    FROM import.ItemNameProcess x
                        JOIN dbo.[Index] i ON i._DatabaseID = x._DatabaseID
                                          AND i._ObjectID   = x._ObjectID
                                          AND i.IndexName   = x.IndexName
                    WHERE x.ProcessKey = @ProcessKey
                        AND x._IndexID IS NULL;
                    SET @rc = @@ROWCOUNT;
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _IndexID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3, @rc = @rc;
                END
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _IndexID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ColumnName IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Column';
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                INSERT dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
                SELECT d._DatabaseID, d._ObjectID, d.ColumnName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.ColumnName IS NOT NULL
                EXCEPT
                SELECT _DatabaseID, _ObjectID, ColumnName FROM dbo.[Column] WHERE _DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

                SELECT @TableName = 'import.ItemNameProcess', @rc = NULL;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ColumnID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                WHILE (@rc > 0 OR @rc IS NULL)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ColumnID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3 OUTPUT;
                    UPDATE TOP(@BatchSize) x SET x._ColumnID = c._ColumnID
                    FROM import.ItemNameProcess x
                        JOIN dbo.[Column] c ON c._DatabaseID = x._DatabaseID
                                           AND c._ObjectID   = x._ObjectID
                                           AND c.ColumnName  = x.ColumnName
                    WHERE x.ProcessKey = @ProcessKey
                        AND x._ColumnID IS NULL;
                    SET @rc = @@ROWCOUNT;
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ColumnID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3, @rc = @rc;
                END;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ColumnID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectDefinitionHash IS NOT NULL)
            BEGIN;
                SELECT @TableName = 'import.ItemNameProcess', @rc = NULL;
                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ObjectDefinitionID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                WHILE (@rc > 0 OR @rc IS NULL)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update _ObjectDefinitionID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3 OUTPUT;
                    UPDATE TOP(@BatchSize) x SET x._ObjectDefinitionID = od._ObjectDefinitionID
                    FROM import.ItemNameProcess x
                        JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = x.ObjectDefinitionHash
                    WHERE x.ProcessKey = @ProcessKey
                        AND x._ObjectDefinitionID IS NULL;
                    SET @rc = @@ROWCOUNT;
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ObjectDefinitionID batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw3, @rc = @rc;
                END;
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update _ObjectDefinitionID loop', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2;
            END;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Perform updates and deletes
        ------------------------------------------------------------------------------
        BEGIN;
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND _ObjectID IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Object';
                IF (@FullImport_Object = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    -- TODO: Revert back to retrieve _then_ update. Doing it all in one go causes locks and deadlocks
                    UPDATE x
                    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                    FROM dbo.[Object] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess p WHERE p.ProcessKey = @ProcessKey AND p._DatabaseID = x._DatabaseID AND p._ObjectID = x._ObjectID)
                        AND x.IsDeleted = 0
                        AND x.SchemaName <> '<<DB>>';
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                END;

                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                SELECT x._ObjectID
                INTO #undelete_object
                FROM dbo.[Object] x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.IsDeleted = 1
                    AND EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID)
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @rc;

                IF EXISTS (SELECT * FROM #undelete_object)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    UPDATE x
                    SET x.IsDeleted = 0, x.DeleteDate = NULL
                    FROM dbo.[Object] x
                    WHERE EXISTS (SELECT * FROM #undelete_object u WHERE u._ObjectID = x._ObjectID);
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                END;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND _IndexID IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Index';
                IF (@FullImport_Index = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    -- TODO: Revert back to retrieve _then_ update. Doing it all in one go causes locks and deadlocks
                    UPDATE x
                    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                    FROM dbo.[Index] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                        AND x.IsDeleted = 0;
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                END;

                EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                SELECT x._IndexID
                INTO #undelete_index
                FROM dbo.[Index] x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.IsDeleted = 1
                    AND EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @rc;

                IF EXISTS (SELECT * FROM #undelete_index)
                BEGIN;
                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    UPDATE x
                    SET x.IsDeleted = 0, x.DeleteDate = NULL
                    FROM dbo.[Index] x
                    WHERE EXISTS (SELECT * FROM #undelete_index u WHERE u._IndexID = x._IndexID);
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                END;
            END;
            -------------------------------------

            -------------------------------------
            IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND _ColumnID IS NOT NULL)
            BEGIN;
                SET @TableName = 'dbo.Column';

                -- Perform deletes
                IF (@FullImport_Column = 1)
                BEGIN;
                    CREATE TABLE #delete_column (_ColumnID int NOT NULL PRIMARY KEY CLUSTERED);

                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Find deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    INSERT #delete_column WITH(TABLOCK) (_ColumnID)
                    SELECT x._ColumnID
                    FROM dbo.[Column] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND x.IsDeleted = 0
                        AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._ColumnID = x._ColumnID)
                    OPTION (OPTIMIZE FOR UNKNOWN);
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Find deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

                    IF EXISTS (SELECT * FROM #delete_column)
                    BEGIN;
                        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                        UPDATE x
                        SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                        FROM dbo.[Column] x
                        WHERE EXISTS (SELECT * FROM #delete_column d WHERE d._ColumnID = x._ColumnID);
                        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark deleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                    END;
                END;

                -- Perform undeletes
                BEGIN;
                    CREATE TABLE #undelete_column (_ColumnID int NOT NULL PRIMARY KEY CLUSTERED);

                    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                    INSERT #undelete_column WITH(TABLOCK) (_ColumnID)
                    SELECT x._ColumnID
                    FROM dbo.[Column] x
                    WHERE x._DatabaseID = @DatabaseID
                        AND x.IsDeleted = 1
                        AND EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._ColumnID = x._ColumnID)
                    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Find undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @rc;

                    IF EXISTS (SELECT * FROM #undelete_column)
                    BEGIN;
                        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
                        UPDATE x
                        SET x.IsDeleted = 0, x.DeleteDate = NULL
                        FROM dbo.[Column] x
                        WHERE EXISTS (SELECT * FROM #undelete_column u WHERE u._ColumnID = x._ColumnID);
                        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark undeleted', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
                    END;
                END;
            END;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Error %d, State %d, Line %d)', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror @EventType = 'Error', @ActionName = 'Proc', @Scope1 = @ProcName, @DetailMessage = @ErrorMessage, @ts = @proc_sw;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
CREATE PROCEDURE import.usp_CreateItems (
    @DatabaseID         int,
    @FullImport_Object  bit = 0,
    @FullImport_Index   bit = 0,
    @FullImport_Column  bit = 0,
    @Dataset            import.ItemName READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.',OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    DECLARE @DataSet2 import.ItemName;

    INSERT INTO @DataSet2 (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
    SELECT ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID
    FROM @Dataset;
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- Perform inserts
    ------------------------------------------------------------------------------
    IF (1=1)
    BEGIN;
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ObjectName IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] [dbo.Object] Insert: Start',0,1,@ProcName) WITH NOWAIT;
            INSERT INTO dbo.[Object] (DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @DatabaseID, SchemaName, ObjectName, ObjectType FROM @DataSet2
            EXCEPT
            SELECT DatabaseID, SchemaName, ObjectName, ObjectType FROM dbo.[Object] WHERE DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Object] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x.ObjectID = o.ObjectID
            FROM @DataSet2 x
                JOIN dbo.[Object] o ON  o.DatabaseID = @DatabaseID
                                    AND o.SchemaName = x.SchemaName
                                    AND o.ObjectName = x.ObjectName
                                    AND o.ObjectType = x.ObjectType;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE IndexName IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] [dbo.Index] Insert: Start',0,1,@ProcName) WITH NOWAIT;
            INSERT INTO dbo.[Index] (DatabaseID, ObjectID, IndexName)
            SELECT o.DatabaseID, o.ObjectID, d.IndexName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d.ObjectID = o.ObjectID
            WHERE o.DatabaseID = @DatabaseID
                AND d.IndexName IS NOT NULL
            EXCEPT
            SELECT DatabaseID, ObjectID, IndexName FROM dbo.[Index] WHERE DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Index] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x.IndexID = i.IndexID
            FROM @DataSet2 x
                JOIN dbo.[Index] i ON i.DatabaseID = @DatabaseID
                                    AND i.ObjectID = x.ObjectID
                                    AND i.IndexName = x.IndexName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ColumnName IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] [dbo.Column] Insert: Start',0,1,@ProcName) WITH NOWAIT;
            INSERT INTO dbo.[Column] (DatabaseID, ObjectID, ColumnName)
            SELECT o.DatabaseID, o.ObjectID, d.ColumnName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d.ObjectID = o.ObjectID
            WHERE o.DatabaseID = @DatabaseID
                AND d.ColumnName IS NOT NULL
            EXCEPT
            SELECT DatabaseID, ObjectID, ColumnName FROM dbo.[Column] WHERE DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Column] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x.ColumnID = c.ColumnID
            FROM @DataSet2 x
                JOIN dbo.[Column] c ON c.DatabaseID = @DatabaseID
                                    AND c.ObjectID = x.ObjectID
                                    AND c.ColumnName = x.ColumnName;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Perform updates and deletes
    ------------------------------------------------------------------------------
    IF (1=1)
    BEGIN;
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ObjectName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Object = 1)
            BEGIN;
                RAISERROR('[%s] [dbo.Object] Find deleted: Start',0,1,@ProcName) WITH NOWAIT;
                SELECT x.ObjectID
                INTO #del_Object
                FROM dbo.[Object] x
                WHERE x.DatabaseID = @DatabaseID
                    AND x.SchemaName <> '<<DB>>' -- Ignore database level items - e.g. database triggers
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d.ObjectID = x.ObjectID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Object] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Object] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Object] x
                WHERE EXISTS (SELECT * FROM #del_Object do WHERE do.ObjectID = x.ObjectID);
                RAISERROR('[%s] [dbo.Object] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Object] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(ROWLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Object] x
            WHERE x.DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d.ObjectID = x.ObjectID)
                AND x.IsDeleted = 1;
            RAISERROR('[%s] [dbo.Object] Mark undeleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE IndexName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Index = 1)
            BEGIN;
                RAISERROR('[%s] [dbo.Index] Find deleted: Start',0,1,@ProcName) WITH NOWAIT;
                SELECT x.IndexID
                INTO #del_Index
                FROM dbo.[Index] x
                WHERE x.DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d.IndexID = x.IndexID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Index] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Index] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Index] x
                WHERE EXISTS (SELECT * FROM #del_Index do WHERE do.IndexID = x.IndexID);
                RAISERROR('[%s] [dbo.Index] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Index] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Index] x
            WHERE x.DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d.IndexID = x.IndexID)
                AND x.IsDeleted = 1;
            RAISERROR('[%s] [dbo.Index] Mark undeleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ColumnName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Column = 1)
            BEGIN;
                RAISERROR('[%s] [dbo.Column] Find deleted: Start',0,1,@ProcName) WITH NOWAIT;
                SELECT x.ColumnID
                INTO #del_Column
                FROM dbo.[Column] x
                WHERE x.DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d.ColumnID = x.ColumnID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Column] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Column] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Column] x
                WHERE EXISTS (SELECT * FROM #del_Column do WHERE do.ColumnID = x.ColumnID);
                RAISERROR('[%s] [dbo.Column] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Column] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Column] x
            WHERE x.DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d.ColumnID = x.ColumnID)
                AND x.IsDeleted = 1;
            RAISERROR('[%s] [dbo.Column] Mark undeleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    SELECT ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID
    FROM @DataSet2;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

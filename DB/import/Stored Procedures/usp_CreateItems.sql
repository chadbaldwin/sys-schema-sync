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

    INSERT INTO @DataSet2 (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    SELECT ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID
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
            INSERT INTO dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @DatabaseID, SchemaName, ObjectName, ObjectType FROM @DataSet2
            EXCEPT
            SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM dbo.[Object] WHERE _DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Object] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x._ObjectID = o._ObjectID
            FROM @DataSet2 x
                JOIN dbo.[Object] o ON  o._DatabaseID = @DatabaseID
                                    AND o.SchemaName = x.SchemaName
                                    AND o.ObjectName = x.ObjectName
                                    AND o.ObjectType = x.ObjectType;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE IndexName IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] [dbo.Index] Insert: Start',0,1,@ProcName) WITH NOWAIT;
            INSERT INTO dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
            SELECT o._DatabaseID, o._ObjectID, d.IndexName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d._ObjectID = o._ObjectID
            WHERE o._DatabaseID = @DatabaseID
                AND d.IndexName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, IndexName FROM dbo.[Index] WHERE _DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Index] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x._IndexID = i._IndexID
            FROM @DataSet2 x
                JOIN dbo.[Index] i ON i._DatabaseID = @DatabaseID
                                    AND i._ObjectID = x._ObjectID
                                    AND i.IndexName = x.IndexName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ColumnName IS NOT NULL)
        BEGIN;
            RAISERROR('[%s] [dbo.Column] Insert: Start',0,1,@ProcName) WITH NOWAIT;
            INSERT INTO dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
            SELECT o._DatabaseID, o._ObjectID, d.ColumnName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d._ObjectID = o._ObjectID
            WHERE o._DatabaseID = @DatabaseID
                AND d.ColumnName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, ColumnName FROM dbo.[Column] WHERE _DatabaseID = @DatabaseID;
            RAISERROR('[%s] [dbo.Column] Insert: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

            UPDATE x SET x._ColumnID = c._ColumnID
            FROM @DataSet2 x
                JOIN dbo.[Column] c ON c._DatabaseID = @DatabaseID
                                    AND c._ObjectID = x._ObjectID
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
                SELECT x._ObjectID
                INTO #del_Object
                FROM dbo.[Object] x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.SchemaName <> '<<DB>>' -- Ignore database level items - e.g. database triggers
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._ObjectID = x._ObjectID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Object] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Object] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Object] x
                WHERE EXISTS (SELECT * FROM #del_Object do WHERE do._ObjectID = x._ObjectID);
                RAISERROR('[%s] [dbo.Object] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Object] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(ROWLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Object] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._ObjectID = x._ObjectID)
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
                SELECT x._IndexID
                INTO #del_Index
                FROM dbo.[Index] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._IndexID = x._IndexID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Index] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Index] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Index] x
                WHERE EXISTS (SELECT * FROM #del_Index do WHERE do._IndexID = x._IndexID);
                RAISERROR('[%s] [dbo.Index] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Index] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Index] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._IndexID = x._IndexID)
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
                SELECT x._ColumnID
                INTO #del_Column
                FROM dbo.[Column] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._ColumnID = x._ColumnID)
                    AND x.IsDeleted = 0;
                RAISERROR('[%s] [dbo.Column] Find deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

                RAISERROR('[%s] [dbo.Column] Mark deleted: Start',0,1,@ProcName) WITH NOWAIT;
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Column] x
                WHERE EXISTS (SELECT * FROM #del_Column do WHERE do._ColumnID = x._ColumnID);
                RAISERROR('[%s] [dbo.Column] Mark deleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
            END;

            RAISERROR('[%s] [dbo.Column] Mark undeleted: Start',0,1,@ProcName) WITH NOWAIT;
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Column] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._ColumnID = x._ColumnID)
                AND x.IsDeleted = 1;
            RAISERROR('[%s] [dbo.Column] Mark undeleted: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    SELECT ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID
    FROM @DataSet2;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

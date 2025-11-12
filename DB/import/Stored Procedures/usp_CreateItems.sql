CREATE PROCEDURE import.usp_CreateItems (
    @DatabaseID         int,
    @FullImport_Object  bit = 0,
    @FullImport_Index   bit = 0,
    @FullImport_Column  bit = 0,
    @Dataset            import.ItemName READONLY,
    @Verbose            bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.',OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    DECLARE @sw2 datetime2 = SYSUTCDATETIME();
    DECLARE @rc bigint = 0;


    DECLARE @DataSet2 import.ItemName;

    INSERT @DataSet2 (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
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
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @DatabaseID, SchemaName, ObjectName, ObjectType FROM @DataSet2
            EXCEPT
            SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM dbo.[Object] WHERE _DatabaseID = @DatabaseID;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Insert: Done', @sw2, @rc, @ProcName;

            UPDATE x SET x._ObjectID = o._ObjectID
            FROM @DataSet2 x
                JOIN dbo.[Object] o ON o._DatabaseID = @DatabaseID
                                   AND o.SchemaName  = x.SchemaName
                                   AND o.ObjectName  = x.ObjectName
                                   AND o.ObjectType  = x.ObjectType;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE IndexName IS NOT NULL)
        BEGIN;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
            SELECT o._DatabaseID, o._ObjectID, d.IndexName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d._ObjectID = o._ObjectID
            WHERE o._DatabaseID = @DatabaseID
                AND d.IndexName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, IndexName FROM dbo.[Index] WHERE _DatabaseID = @DatabaseID;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Insert: Done', @sw2, @rc, @ProcName;

            UPDATE x SET x._IndexID = i._IndexID
            FROM @DataSet2 x
                JOIN dbo.[Index] i ON i._DatabaseID = @DatabaseID
                                  AND i._ObjectID   = x._ObjectID
                                  AND i.IndexName   = x.IndexName;
        END;
        -------------------------------------
                -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ColumnName IS NOT NULL)
        BEGIN;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
            SELECT o._DatabaseID, o._ObjectID, d.ColumnName
            FROM dbo.[Object] o
                JOIN @DataSet2 d ON d._ObjectID = o._ObjectID
            WHERE o._DatabaseID = @DatabaseID
                AND d.ColumnName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, ColumnName FROM dbo.[Column] WHERE _DatabaseID = @DatabaseID;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Insert: Done', @sw2, @rc, @ProcName;

            UPDATE x SET x._ColumnID = c._ColumnID
            FROM @DataSet2 x
                JOIN dbo.[Column] c ON c._DatabaseID = @DatabaseID
                                   AND c._ObjectID   = x._ObjectID
                                   AND c.ColumnName  = x.ColumnName;
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
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Find deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                SELECT x._ObjectID
                INTO #del_Object
                FROM dbo.[Object] x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.SchemaName <> '<<DB>>' -- Ignore database level items - e.g. database triggers
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._ObjectID = x._ObjectID)
                    AND x.IsDeleted = 0;
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Find deleted: Done', @sw2, @rc, @ProcName;

                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Object] x
                WHERE EXISTS (SELECT * FROM #del_Object do WHERE do._ObjectID = x._ObjectID);
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted: Done', @sw2, @rc, @ProcName;
            END;

            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x WITH(ROWLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Object] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._ObjectID = x._ObjectID)
                AND x.IsDeleted = 1;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark undeleted: Done', @sw2, @rc, @ProcName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE IndexName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Index = 1)
            BEGIN;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Find deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                SELECT x._IndexID
                INTO #del_Index
                FROM dbo.[Index] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._IndexID = x._IndexID)
                    AND x.IsDeleted = 0;
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Find deleted: Done', @sw2, @rc, @ProcName;

                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Index] x
                WHERE EXISTS (SELECT * FROM #del_Index do WHERE do._IndexID = x._IndexID);
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark deleted: Done', @sw2, @rc, @ProcName;
            END;

            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Index] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._IndexID = x._IndexID)
                AND x.IsDeleted = 1;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark undeleted: Done', @sw2, @rc, @ProcName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM @DataSet2 WHERE ColumnName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Column = 1)
            BEGIN;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Find deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                SELECT x._ColumnID
                INTO #del_Column
                FROM dbo.[Column] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM @DataSet2 d WHERE d._ColumnID = x._ColumnID)
                    AND x.IsDeleted = 0;
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Find deleted: Done', @sw2, @rc, @ProcName;

                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x WITH(ROWLOCK)
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Column] x
                WHERE EXISTS (SELECT * FROM #del_Column do WHERE do._ColumnID = x._ColumnID);
                SET @rc = @@ROWCOUNT;
                IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark deleted: Done', @sw2, @rc, @ProcName;
            END;

            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x WITH(UPDLOCK)
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Column] x
            WHERE x._DatabaseID = @DatabaseID
                AND EXISTS (SELECT * FROM @DataSet2 d WHERE d._ColumnID = x._ColumnID)
                AND x.IsDeleted = 1;
            SET @rc = @@ROWCOUNT;
            IF (@Verbose = 1) EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark undeleted: Done', @sw2, @rc, @ProcName;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    SELECT ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID
    FROM @DataSet2;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
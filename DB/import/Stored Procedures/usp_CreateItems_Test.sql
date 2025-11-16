CREATE PROCEDURE import.usp_CreateItems_Test (
    @DatabaseID         int,
    @ProcessKey         uniqueidentifier,
    @FullImport_Object  bit = 0,
    @FullImport_Index   bit = 0,
    @FullImport_Column  bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.',OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    DECLARE @sw2 datetime2 = SYSUTCDATETIME();
    DECLARE @rc bigint = 0;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Perform inserts
    ------------------------------------------------------------------------------
    IF (1=1)
    BEGIN;
        IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectName IS NOT NULL)
        BEGIN;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Object] (_DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey
            EXCEPT
            SELECT _DatabaseID, SchemaName, ObjectName, ObjectType FROM dbo.[Object] WHERE _DatabaseID = @DatabaseID;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Insert: Done', @sw2, @@ROWCOUNT, @ProcName;

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
            EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Index] (_DatabaseID, _ObjectID, IndexName)
            SELECT d._DatabaseID, d._ObjectID, d.IndexName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.IndexName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, IndexName FROM dbo.[Index] WHERE _DatabaseID = @DatabaseID;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Insert: Done', @sw2, @@ROWCOUNT, @ProcName;

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
            EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Insert: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo.[Column] (_DatabaseID, _ObjectID, ColumnName)
            SELECT d._DatabaseID, d._ObjectID, d.ColumnName FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d.ColumnName IS NOT NULL
            EXCEPT
            SELECT _DatabaseID, _ObjectID, ColumnName FROM dbo.[Column] WHERE _DatabaseID = @DatabaseID;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Insert: Done', @sw2, @@ROWCOUNT, @ProcName;

            UPDATE x SET x._ColumnID = c._ColumnID
            FROM import.ItemNameProcess x
                JOIN dbo.[Column] c ON c._DatabaseID = x._DatabaseID
                                   AND c._ObjectID   = x._ObjectID
                                   AND c.ColumnName  = x.ColumnName
            WHERE x.ProcessKey = @ProcessKey;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Perform updates and deletes
    ------------------------------------------------------------------------------
    IF (1=1)
    BEGIN;
        IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ObjectName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Object = 1)
            BEGIN;
                EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Object] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM import.ItemNameProcess p WHERE p.ProcessKey = @ProcessKey AND p._DatabaseID = x._DatabaseID AND p._ObjectID   = x._ObjectID)
                    AND x.IsDeleted = 0
                    AND x.SchemaName <> '<<DB>>'
                EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted: Done', @sw2, @@ROWCOUNT, @ProcName;
            END;

            EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Object] x
            WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID)
                AND x.IsDeleted = 1;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark undeleted: Done', @sw2, @@ROWCOUNT, @ProcName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND IndexName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Index = 1)
            BEGIN;
                EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Index] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                    AND x.IsDeleted = 0;
                EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark deleted: Done', @sw2, @@ROWCOUNT, @ProcName;
            END;

            EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Index] x
            WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID)
                AND x.IsDeleted = 1;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Index] Mark undeleted: Done', @sw2, @@ROWCOUNT, @ProcName;
        END;
        -------------------------------------

        -------------------------------------
        IF EXISTS (SELECT * FROM import.ItemNameProcess WHERE ProcessKey = @ProcessKey AND ColumnName IS NOT NULL)
        BEGIN;
            IF (@FullImport_Column = 1)
            BEGIN;
                EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark deleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
                UPDATE x
                SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
                FROM dbo.[Column] x
                WHERE x._DatabaseID = @DatabaseID
                    AND NOT EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID)
                    AND x.IsDeleted = 0;
                EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark deleted: Done', @sw2, @@ROWCOUNT, @ProcName;
            END;

            EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark undeleted: Start', @s1 = @ProcName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x.IsDeleted = 0, x.DeleteDate = NULL
            FROM dbo.[Column] x
            WHERE EXISTS (SELECT * FROM import.ItemNameProcess d WHERE d.ProcessKey = @ProcessKey AND d._DatabaseID = x._DatabaseID AND d._ColumnID = x._ColumnID)
                AND x.IsDeleted = 1;
            EXEC dbo.usp_Raiserror '[%s] [dbo.Column] Mark undeleted: Done', @sw2, @@ROWCOUNT, @ProcName;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
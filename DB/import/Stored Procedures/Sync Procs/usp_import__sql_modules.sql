CREATE PROCEDURE import.usp_import__sql_modules (
    @DatabaseID int,
    @Dataset    import.import__sql_modules READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;

    DECLARE @tableName nvarchar(128);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    SET @tableName = 'dbo.ObjectDefinition'
    EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
    WITH cte AS (
        SELECT rn = ROW_NUMBER() OVER (PARTITION BY d._ObjectDefinitionHash ORDER BY d.[object_id])
            , d._ObjectDefinitionHash, d.[definition]
        FROM @Dataset d
    )
    INSERT dbo.ObjectDefinition WITH(TABLOCKX) (ObjectDefinitionHash, ObjectDefinition)
    SELECT d._ObjectDefinitionHash, d.[definition]
    FROM cte d
    WHERE d.rn = 1
        AND NOT EXISTS (
            SELECT *
            FROM dbo.ObjectDefinition od WITH(TABLOCKX)
            WHERE od.ObjectDefinitionHash = d._ObjectDefinitionHash
        );
    EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    /*  For some reason, SQL Server stores database level items, like database triggers, in sys.sql_modules
        Because of this, when the full import for sys.objects runs, it sees those as missing and marks them
        as deleted. So instead, we exclude them from the normal delete process and handle them here.

        The normal undelete process isn't affected though since they are still created/imported the same way.
    */
    EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Find deleted database level items: Start', @s1 = @ProcName;
    SELECT x._ObjectID
    INTO #del_Object
    FROM dbo.[Object] x
    WHERE x._DatabaseID = @DatabaseID
        AND x.SchemaName = '<<DB>>' -- Limit to database level items - e.g. database triggers
        AND NOT EXISTS (SELECT * FROM @output d WHERE d._ObjectID = x._ObjectID)
        AND x.IsDeleted = 0;
    EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Find deleted database level items: Done', @s1 = @ProcName, @rc = @@ROWCOUNT;

    EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted database level items: Start', @s1 = @ProcName;
    UPDATE x WITH(ROWLOCK)
    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
    FROM dbo.[Object] x
    WHERE x._DatabaseID = @DatabaseID
        AND EXISTS (SELECT * FROM #del_Object do WHERE do._ObjectID = x._ObjectID);
    EXEC dbo.usp_Raiserror '[%s] [dbo.Object] Mark deleted database level items: Done', @s1 = @ProcName, @rc = @@ROWCOUNT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    SET @tableName = 'dbo._sql_modules'
    BEGIN TRAN;
        /* -- Turning off delete logic; rely on soft delete logic instead by joining to vw_Object
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._sql_modules x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
        */

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET   x._ModifyDate             = SYSUTCDATETIME()
            , x._RowHash                = d._RowHash
            --
            , x.[object_id]             = d.[object_id]
            , x._ObjectDefinitionID     = od._ObjectDefinitionID
            , x.uses_ansi_nulls         = d.uses_ansi_nulls
            , x.uses_quoted_identifier  = d.uses_quoted_identifier
            , x.is_schema_bound         = d.is_schema_bound
            , x.uses_database_collation = d.uses_database_collation
            , x.is_recompiled           = d.is_recompiled
            , x.null_on_null_input      = d.null_on_null_input
            , x.execute_as_principal_id = d.execute_as_principal_id
            , x.uses_native_compilation = d.uses_native_compilation
            , x.inline_type             = d.inline_type
            , x.is_inlineable           = d.is_inlineable
        FROM dbo._sql_modules x
            JOIN @output o ON o._ObjectID = x._ObjectID
            JOIN @Dataset d ON d.__ID = o.ID
            JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = d._ObjectDefinitionHash
        WHERE x._DatabaseID = @DatabaseID
            AND (x._RowHash <> d._RowHash OR x._ObjectDefinitionID <> od._ObjectDefinitionID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._sql_modules (_DatabaseID, _ObjectID, _RowHash
            , [object_id], _ObjectDefinitionID, uses_ansi_nulls, uses_quoted_identifier, is_schema_bound, uses_database_collation, is_recompiled, null_on_null_input, execute_as_principal_id, uses_native_compilation, inline_type, is_inlineable)
        SELECT @DatabaseID, y._ObjectID, d._RowHash
            , d.[object_id], od._ObjectDefinitionID, d.uses_ansi_nulls, d.uses_quoted_identifier, d.is_schema_bound, d.uses_database_collation, d.is_recompiled, d.null_on_null_input, d.execute_as_principal_id, d.uses_native_compilation, d.inline_type, d.is_inlineable
        FROM @Dataset d
            JOIN @output y ON y.ID = d.__ID
            JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = d._ObjectDefinitionHash
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._sql_modules x
                WHERE x._DatabaseID = @DatabaseID
                    AND x._ObjectID = y._ObjectID
            );
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
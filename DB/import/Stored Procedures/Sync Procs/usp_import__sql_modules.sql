CREATE PROCEDURE import.usp_import__sql_modules (
    @DatabaseID int,
    @Dataset    import.import__sql_modules READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
    SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Insert into dbo.ObjectDefinition',0,1,@ProcName) WITH NOWAIT;
    WITH cte AS (
        SELECT rn = ROW_NUMBER() OVER (PARTITION BY d._ObjectDefinitionHash ORDER BY d.[object_id])
            , d._ObjectDefinitionHash, d.[definition]
        FROM @Dataset d
    )
    INSERT INTO dbo.ObjectDefinition WITH(TABLOCKX) (ObjectDefinitionHash, ObjectDefinition)
    SELECT d._ObjectDefinitionHash, d.[definition]
    FROM cte d
    WHERE d.rn = 1
        AND NOT EXISTS (
            SELECT *
            FROM dbo.ObjectDefinition od WITH(TABLOCKX)
            WHERE od.ObjectDefinitionHash = d._ObjectDefinitionHash
        );
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    /*  For some reason, SQL Server stores database level items, like database triggers, in sys.sql_modules
        Because of this, when the full import for sys.objects runs, it sees those as missing and marks them
        as deleted. So instead, we exclude them from the normal delete process and handle them here.

        The normal undelete process isn't affected though since they are still created/imported the same way.
    */
    RAISERROR('[%s] [dbo.Object] Find deleted database level items: Start',0,1,@ProcName) WITH NOWAIT;
    SELECT x._ObjectID
    INTO #del_Object
    FROM dbo.[Object] x
    WHERE x._DatabaseID = @DatabaseID
        AND x.SchemaName = '<<DB>>' -- Limit to database level items - e.g. database triggers
        AND NOT EXISTS (SELECT * FROM @output d WHERE d._ObjectID = x._ObjectID)
        AND x.IsDeleted = 0;
    RAISERROR('[%s] [dbo.Object] Find deleted database level items: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [dbo.Object] Mark deleted database level items: Start',0,1,@ProcName) WITH NOWAIT;
    UPDATE x WITH(ROWLOCK)
    SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
    FROM dbo.[Object] x
    WHERE EXISTS (SELECT * FROM #del_Object do WHERE do._ObjectID = x._ObjectID);
    RAISERROR('[%s] [dbo.Object] Mark deleted database level items: Done (%i)',0,1,@ProcName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._sql_modules';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._sql_modules x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
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
        JOIN #Dataset d ON d.ID = o.ID
        JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = d._ObjectDefinitionHash
    WHERE x._RowHash <> d._RowHash OR x._ObjectDefinitionID <> od._ObjectDefinitionID;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._sql_modules (_DatabaseID, _ObjectID, _RowHash
        , [object_id], _ObjectDefinitionID, uses_ansi_nulls, uses_quoted_identifier, is_schema_bound, uses_database_collation, is_recompiled, null_on_null_input, execute_as_principal_id, uses_native_compilation, inline_type, is_inlineable)
    SELECT @DatabaseID, y._ObjectID, d._RowHash
        , d.[object_id], od._ObjectDefinitionID, d.uses_ansi_nulls, d.uses_quoted_identifier, d.is_schema_bound, d.uses_database_collation, d.is_recompiled, d.null_on_null_input, d.execute_as_principal_id, d.uses_native_compilation, d.inline_type, d.is_inlineable
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
        JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionHash = d._ObjectDefinitionHash
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._sql_modules x
            WHERE x._ObjectID = y._ObjectID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

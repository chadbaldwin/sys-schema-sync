CREATE PROC import.usp_import__sql_modules (
    @DatabaseID int,
    @Dataset    import.import__sql_modules READONLY,
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
        SET @TableName = 'dbo.ObjectDefinition'
        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ObjectDefinitionHash)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _ObjectDefinitionHash FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._sql_modules;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [object_id], _ObjectDefinitionID, uses_ansi_nulls, uses_quoted_identifier, is_schema_bound, uses_database_collation, is_recompiled, null_on_null_input, execute_as_principal_id, uses_native_compilation, inline_type, is_inlineable)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[object_id], o._ObjectDefinitionID, d.uses_ansi_nulls, d.uses_quoted_identifier, d.is_schema_bound, d.uses_database_collation, d.is_recompiled, d.null_on_null_input, d.execute_as_principal_id, d.uses_native_compilation, d.inline_type, d.is_inlineable
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        /*  For some reason, SQL Server stores database level items, like database triggers, in sys.sql_modules
            Because of this, when the full import for sys.objects runs, it sees those as missing and marks them
            as deleted. So instead, we exclude them from the normal delete process and handle them here.

            The normal undelete process isn't affected though since they are still created/imported the same way.
        */
        SET @TableName = 'dbo.Object';
        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Find deleted database level items', NULL, NULL, @ProcName, @TableName;
        SELECT x._DatabaseID, x._ObjectID
        INTO #del_Object
        FROM dbo.[Object] x
        WHERE x._DatabaseID = @DatabaseID
            AND x.SchemaName = '<<DB>>' -- Limit to database level items - e.g. database triggers
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID)
            AND x.IsDeleted = 0;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Find deleted database level items', NULL, @@ROWCOUNT, @ProcName, @TableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Mark deleted database level items', NULL, NULL, @ProcName, @TableName;
        UPDATE x WITH(ROWLOCK)
        SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
        FROM dbo.[Object] x
        WHERE EXISTS (SELECT * FROM #del_Object do WHERE do._DatabaseID = x._DatabaseID AND do._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Mark deleted database level items', NULL, @@ROWCOUNT, @ProcName, @TableName;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        SET @TableName = 'dbo._sql_modules'
        BEGIN TRAN;
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET   x._ModifyDate             = SYSUTCDATETIME()
                , x._RowHash                = d._RowHash
                , x.[object_id]             = d.[object_id]
                , x._ObjectDefinitionID     = d._ObjectDefinitionID
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
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
            WHERE (x._RowHash <> d._RowHash OR x._ObjectDefinitionID <> d._ObjectDefinitionID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._sql_modules (_DatabaseID, _ObjectID, _RowHash, [object_id], _ObjectDefinitionID, uses_ansi_nulls, uses_quoted_identifier, is_schema_bound, uses_database_collation, is_recompiled, null_on_null_input, execute_as_principal_id, uses_native_compilation, inline_type, is_inlineable)
            SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.[object_id], d._ObjectDefinitionID, d.uses_ansi_nulls, d.uses_quoted_identifier, d.is_schema_bound, d.uses_database_collation, d.is_recompiled, d.null_on_null_input, d.execute_as_principal_id, d.uses_native_compilation, d.inline_type, d.is_inlineable
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._sql_modules x WHERE x._DatabaseID = d._DatabaseID AND x._ObjectID = d._ObjectID);
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
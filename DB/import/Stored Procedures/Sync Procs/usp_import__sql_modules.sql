CREATE PROC import.usp_import__sql_modules (
    @DatabaseID int,
    @Dataset    import.import__sql_modules READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_DatabaseID', @value = @DatabaseID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        SET @TableName = 'dbo.ObjectDefinition';
        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
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
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ObjectDefinitionHash)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _ObjectDefinitionHash FROM @Dataset;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._sql_modules;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [object_id], _ObjectDefinitionID, uses_ansi_nulls, uses_quoted_identifier, is_schema_bound, uses_database_collation, is_recompiled, null_on_null_input, execute_as_principal_id, uses_native_compilation, inline_type, is_inlineable)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[object_id], o._ObjectDefinitionID, d.uses_ansi_nulls, d.uses_quoted_identifier, d.is_schema_bound, d.uses_database_collation, d.is_recompiled, d.null_on_null_input, d.execute_as_principal_id, d.uses_native_compilation, d.inline_type, d.is_inlineable
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        /*  For some reason, SQL Server stores database level items, like database triggers, in sys.sql_modules.

            Because of this, when the full import for sys.objects runs, it sees those database level objects as
            missing and marks them as deleted. So instead we exclude them from the normal delete process and
            handle them here.

            The normal undelete process isn't affected though since they are still created/imported the same way.
        */
        SET @TableName = 'dbo.Object';
        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Find deleted database level items', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
        SELECT x._DatabaseID, x._ObjectID
        INTO #del_Object
        FROM dbo.[Object] x
        WHERE x._DatabaseID = @DatabaseID
            AND x.SchemaName = '<<DB>>' -- Limit to database level items - e.g. database triggers
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID)
            AND x.IsDeleted = 0;
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Find deleted database level items', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;

        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Mark deleted database level items', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
        UPDATE x WITH(ROWLOCK)
        SET x.IsDeleted = 1, x.DeleteDate = SYSUTCDATETIME()
        FROM dbo.[Object] x
        WHERE EXISTS (SELECT * FROM #del_Object do WHERE do._DatabaseID = x._DatabaseID AND do._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Mark deleted database level items', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @TargetTable = 'dbo._sql_modules';
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
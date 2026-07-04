CREATE PROC import.usp_import__server_principals (
    @InstanceID int,
    @Dataset    import.import__server_principals READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_InstanceID', @value = @InstanceID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@InstanceID IS NULL) BEGIN; THROW 51000, 'Required parameter @InstanceID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._server_principals;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_InstanceID, principal_id);

            INSERT #Dataset WITH(TABLOCK) (_InstanceID, _RowHash, [name], principal_id, [sid], [type], [type_desc], is_disabled, create_date, modify_date, default_database_name, default_language_name, credential_id, owning_principal_id, is_fixed_role, tenant_id)
            SELECT @InstanceID, d._RowHash, d.[name], d.principal_id, d.[sid], d.[type], d.[type_desc], d.is_disabled, d.create_date, d.modify_date, d.default_database_name, d.default_language_name, d.credential_id, d.owning_principal_id, d.is_fixed_role, d.tenant_id
            FROM @Dataset d;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @InstanceID = @InstanceID, @TargetTable = 'dbo._server_principals';
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
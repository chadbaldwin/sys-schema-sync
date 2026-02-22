CREATE PROC import.usp_import__OBJECTPROPERTYEX (
    @DatabaseID int,
    @Dataset    import.import__OBJECTPROPERTYEX READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;
    EXEC sp_set_session_context N'_DatabaseID', @DatabaseID;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._OBJECTPROPERTYEX;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, BaseType, CnstIsClustKey, CnstIsColumn, CnstIsDeleteCascade, CnstIsDisabled, CnstIsNonclustKey, CnstIsNotRepl, CnstIsNotTrusted, CnstIsUpdateCascade, ExecIsAfterTrigger, ExecIsAnsiNullsOn, ExecIsDeleteTrigger, ExecIsFirstDeleteTrigger, ExecIsFirstInsertTrigger, ExecIsFirstUpdateTrigger, ExecIsInsertTrigger, ExecIsInsteadOfTrigger, ExecIsLastDeleteTrigger, ExecIsLastInsertTrigger, ExecIsLastUpdateTrigger, ExecIsQuotedIdentOn, ExecIsStartup, ExecIsTriggerDisabled, ExecIsTriggerNotForRepl, ExecIsUpdateTrigger, ExecIsWithNativeCompilation, HasAfterTrigger, HasDeleteTrigger, HasInsertTrigger, HasInsteadOfTrigger, HasUpdateTrigger, IsAnsiNullsOn, IsCheckCnst, IsConstraint, IsDefault, IsDefaultCnst, IsDeterministic, IsEncrypted, IsExecuted, IsExtendedProc, IsForeignKey, IsIndexed, IsIndexable, IsInlineFunction, IsMSShipped, IsPrecise, IsPrimaryKey, IsProcedure, IsQuotedIdentOn, IsQueue, IsReplProc, IsRule, IsScalarFunction, IsSchemaBound, IsSystemTable, IsSystemVerified, IsTable, IsTableFunction, IsTrigger, IsUniqueCnst, IsUserTable, IsView, OwnerId, SchemaId, SystemDataAccess, TableDeleteTrigger, TableDeleteTriggerCount, TableFullTextMergeStatus, TableFullTextBackgroundUpdateIndexOn, TableFulltextCatalogId, TableFullTextChangeTrackingOn, TableFulltextKeyColumn, TableFulltextPopulateStatus, TableFullTextSemanticExtraction, TableHasActiveFulltextIndex, TableHasCheckCnst, TableHasClustIndex, TableHasDefaultCnst, TableHasDeleteTrigger, TableHasForeignKey, TableHasForeignRef, TableHasIdentity, TableHasIndex, TableHasInsertTrigger, TableHasNonclustIndex, TableHasPrimaryKey, TableHasRowGuidCol, TableHasTextImage, TableHasTimestamp, TableHasUniqueCnst, TableHasUpdateTrigger, TableHasVarDecimalStorageFormat, TableInsertTrigger, TableInsertTriggerCount, TableIsFake, TableIsLockedOnBulkLoad, TableIsMemoryOptimized, TableIsPinned, TableTextInRowLimit, TableUpdateTrigger, TableUpdateTriggerCount, UserDataAccess, TableHasColumnSet, Cardinality, TableTemporalType)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.BaseType, d.CnstIsClustKey, d.CnstIsColumn, d.CnstIsDeleteCascade, d.CnstIsDisabled, d.CnstIsNonclustKey, d.CnstIsNotRepl, d.CnstIsNotTrusted, d.CnstIsUpdateCascade, d.ExecIsAfterTrigger, d.ExecIsAnsiNullsOn, d.ExecIsDeleteTrigger, d.ExecIsFirstDeleteTrigger, d.ExecIsFirstInsertTrigger, d.ExecIsFirstUpdateTrigger, d.ExecIsInsertTrigger, d.ExecIsInsteadOfTrigger, d.ExecIsLastDeleteTrigger, d.ExecIsLastInsertTrigger, d.ExecIsLastUpdateTrigger, d.ExecIsQuotedIdentOn, d.ExecIsStartup, d.ExecIsTriggerDisabled, d.ExecIsTriggerNotForRepl, d.ExecIsUpdateTrigger, d.ExecIsWithNativeCompilation, d.HasAfterTrigger, d.HasDeleteTrigger, d.HasInsertTrigger, d.HasInsteadOfTrigger, d.HasUpdateTrigger, d.IsAnsiNullsOn, d.IsCheckCnst, d.IsConstraint, d.IsDefault, d.IsDefaultCnst, d.IsDeterministic, d.IsEncrypted, d.IsExecuted, d.IsExtendedProc, d.IsForeignKey, d.IsIndexed, d.IsIndexable, d.IsInlineFunction, d.IsMSShipped, d.IsPrecise, d.IsPrimaryKey, d.IsProcedure, d.IsQuotedIdentOn, d.IsQueue, d.IsReplProc, d.IsRule, d.IsScalarFunction, d.IsSchemaBound, d.IsSystemTable, d.IsSystemVerified, d.IsTable, d.IsTableFunction, d.IsTrigger, d.IsUniqueCnst, d.IsUserTable, d.IsView, d.OwnerId, d.SchemaId, d.SystemDataAccess, d.TableDeleteTrigger, d.TableDeleteTriggerCount, d.TableFullTextMergeStatus, d.TableFullTextBackgroundUpdateIndexOn, d.TableFulltextCatalogId, d.TableFullTextChangeTrackingOn, d.TableFulltextKeyColumn, d.TableFulltextPopulateStatus, d.TableFullTextSemanticExtraction, d.TableHasActiveFulltextIndex, d.TableHasCheckCnst, d.TableHasClustIndex, d.TableHasDefaultCnst, d.TableHasDeleteTrigger, d.TableHasForeignKey, d.TableHasForeignRef, d.TableHasIdentity, d.TableHasIndex, d.TableHasInsertTrigger, d.TableHasNonclustIndex, d.TableHasPrimaryKey, d.TableHasRowGuidCol, d.TableHasTextImage, d.TableHasTimestamp, d.TableHasUniqueCnst, d.TableHasUpdateTrigger, d.TableHasVarDecimalStorageFormat, d.TableInsertTrigger, d.TableInsertTriggerCount, d.TableIsFake, d.TableIsLockedOnBulkLoad, d.TableIsMemoryOptimized, d.TableIsPinned, d.TableTextInRowLimit, d.TableUpdateTrigger, d.TableUpdateTriggerCount, d.UserDataAccess, d.TableHasColumnSet, d.Cardinality, d.TableTemporalType
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @CallingProcName = @ProcName, @TargetTable = 'dbo._OBJECTPROPERTYEX';
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
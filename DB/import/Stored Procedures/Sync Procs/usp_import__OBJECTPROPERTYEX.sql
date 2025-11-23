CREATE PROCEDURE import.usp_import__OBJECTPROPERTYEX (
    @DatabaseID int,
    @Dataset    import.import__OBJECTPROPERTYEX READONLY,
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
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._OBJECTPROPERTYEX';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._OBJECTPROPERTYEX x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ModifyDate                          = SYSUTCDATETIME()
              , x._RowHash                             = d._RowHash
              , x.BaseType                             = d.BaseType
              , x.CnstIsClustKey                       = d.CnstIsClustKey
              , x.CnstIsColumn                         = d.CnstIsColumn
              , x.CnstIsDeleteCascade                  = d.CnstIsDeleteCascade
              , x.CnstIsDisabled                       = d.CnstIsDisabled
              , x.CnstIsNonclustKey                    = d.CnstIsNonclustKey
              , x.CnstIsNotRepl                        = d.CnstIsNotRepl
              , x.CnstIsNotTrusted                     = d.CnstIsNotTrusted
              , x.CnstIsUpdateCascade                  = d.CnstIsUpdateCascade
              , x.ExecIsAfterTrigger                   = d.ExecIsAfterTrigger
              , x.ExecIsAnsiNullsOn                    = d.ExecIsAnsiNullsOn
              , x.ExecIsDeleteTrigger                  = d.ExecIsDeleteTrigger
              , x.ExecIsFirstDeleteTrigger             = d.ExecIsFirstDeleteTrigger
              , x.ExecIsFirstInsertTrigger             = d.ExecIsFirstInsertTrigger
              , x.ExecIsFirstUpdateTrigger             = d.ExecIsFirstUpdateTrigger
              , x.ExecIsInsertTrigger                  = d.ExecIsInsertTrigger
              , x.ExecIsInsteadOfTrigger               = d.ExecIsInsteadOfTrigger
              , x.ExecIsLastDeleteTrigger              = d.ExecIsLastDeleteTrigger
              , x.ExecIsLastInsertTrigger              = d.ExecIsLastInsertTrigger
              , x.ExecIsLastUpdateTrigger              = d.ExecIsLastUpdateTrigger
              , x.ExecIsQuotedIdentOn                  = d.ExecIsQuotedIdentOn
              , x.ExecIsStartup                        = d.ExecIsStartup
              , x.ExecIsTriggerDisabled                = d.ExecIsTriggerDisabled
              , x.ExecIsTriggerNotForRepl              = d.ExecIsTriggerNotForRepl
              , x.ExecIsUpdateTrigger                  = d.ExecIsUpdateTrigger
              , x.ExecIsWithNativeCompilation          = d.ExecIsWithNativeCompilation
              , x.HasAfterTrigger                      = d.HasAfterTrigger
              , x.HasDeleteTrigger                     = d.HasDeleteTrigger
              , x.HasInsertTrigger                     = d.HasInsertTrigger
              , x.HasInsteadOfTrigger                  = d.HasInsteadOfTrigger
              , x.HasUpdateTrigger                     = d.HasUpdateTrigger
              , x.IsAnsiNullsOn                        = d.IsAnsiNullsOn
              , x.IsCheckCnst                          = d.IsCheckCnst
              , x.IsConstraint                         = d.IsConstraint
              , x.IsDefault                            = d.IsDefault
              , x.IsDefaultCnst                        = d.IsDefaultCnst
              , x.IsDeterministic                      = d.IsDeterministic
              , x.IsEncrypted                          = d.IsEncrypted
              , x.IsExecuted                           = d.IsExecuted
              , x.IsExtendedProc                       = d.IsExtendedProc
              , x.IsForeignKey                         = d.IsForeignKey
              , x.IsIndexed                            = d.IsIndexed
              , x.IsIndexable                          = d.IsIndexable
              , x.IsInlineFunction                     = d.IsInlineFunction
              , x.IsMSShipped                          = d.IsMSShipped
              , x.IsPrecise                            = d.IsPrecise
              , x.IsPrimaryKey                         = d.IsPrimaryKey
              , x.IsProcedure                          = d.IsProcedure
              , x.IsQuotedIdentOn                      = d.IsQuotedIdentOn
              , x.IsQueue                              = d.IsQueue
              , x.IsReplProc                           = d.IsReplProc
              , x.IsRule                               = d.IsRule
              , x.IsScalarFunction                     = d.IsScalarFunction
              , x.IsSchemaBound                        = d.IsSchemaBound
              , x.IsSystemTable                        = d.IsSystemTable
              , x.IsSystemVerified                     = d.IsSystemVerified
              , x.IsTable                              = d.IsTable
              , x.IsTableFunction                      = d.IsTableFunction
              , x.IsTrigger                            = d.IsTrigger
              , x.IsUniqueCnst                         = d.IsUniqueCnst
              , x.IsUserTable                          = d.IsUserTable
              , x.IsView                               = d.IsView
              , x.OwnerId                              = d.OwnerId
              , x.SchemaId                             = d.SchemaId
              , x.SystemDataAccess                     = d.SystemDataAccess
              , x.TableDeleteTrigger                   = d.TableDeleteTrigger
              , x.TableDeleteTriggerCount              = d.TableDeleteTriggerCount
              , x.TableFullTextMergeStatus             = d.TableFullTextMergeStatus
              , x.TableFullTextBackgroundUpdateIndexOn = d.TableFullTextBackgroundUpdateIndexOn
              , x.TableFulltextCatalogId               = d.TableFulltextCatalogId
              , x.TableFullTextChangeTrackingOn        = d.TableFullTextChangeTrackingOn
              , x.TableFulltextKeyColumn               = d.TableFulltextKeyColumn
              , x.TableFulltextPopulateStatus          = d.TableFulltextPopulateStatus
              , x.TableFullTextSemanticExtraction      = d.TableFullTextSemanticExtraction
              , x.TableHasActiveFulltextIndex          = d.TableHasActiveFulltextIndex
              , x.TableHasCheckCnst                    = d.TableHasCheckCnst
              , x.TableHasClustIndex                   = d.TableHasClustIndex
              , x.TableHasDefaultCnst                  = d.TableHasDefaultCnst
              , x.TableHasDeleteTrigger                = d.TableHasDeleteTrigger
              , x.TableHasForeignKey                   = d.TableHasForeignKey
              , x.TableHasForeignRef                   = d.TableHasForeignRef
              , x.TableHasIdentity                     = d.TableHasIdentity
              , x.TableHasIndex                        = d.TableHasIndex
              , x.TableHasInsertTrigger                = d.TableHasInsertTrigger
              , x.TableHasNonclustIndex                = d.TableHasNonclustIndex
              , x.TableHasPrimaryKey                   = d.TableHasPrimaryKey
              , x.TableHasRowGuidCol                   = d.TableHasRowGuidCol
              , x.TableHasTextImage                    = d.TableHasTextImage
              , x.TableHasTimestamp                    = d.TableHasTimestamp
              , x.TableHasUniqueCnst                   = d.TableHasUniqueCnst
              , x.TableHasUpdateTrigger                = d.TableHasUpdateTrigger
              , x.TableHasVarDecimalStorageFormat      = d.TableHasVarDecimalStorageFormat
              , x.TableInsertTrigger                   = d.TableInsertTrigger
              , x.TableInsertTriggerCount              = d.TableInsertTriggerCount
              , x.TableIsFake                          = d.TableIsFake
              , x.TableIsLockedOnBulkLoad              = d.TableIsLockedOnBulkLoad
              , x.TableIsMemoryOptimized               = d.TableIsMemoryOptimized
              , x.TableIsPinned                        = d.TableIsPinned
              , x.TableTextInRowLimit                  = d.TableTextInRowLimit
              , x.TableUpdateTrigger                   = d.TableUpdateTrigger
              , x.TableUpdateTriggerCount              = d.TableUpdateTriggerCount
              , x.UserDataAccess                       = d.UserDataAccess
              , x.TableHasColumnSet                    = d.TableHasColumnSet
              , x.Cardinality                          = d.Cardinality
              , x.TableTemporalType                    = d.TableTemporalType
            FROM dbo._OBJECTPROPERTYEX x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._OBJECTPROPERTYEX (_DatabaseID, _ObjectID, _RowHash, BaseType, CnstIsClustKey, CnstIsColumn, CnstIsDeleteCascade, CnstIsDisabled, CnstIsNonclustKey, CnstIsNotRepl, CnstIsNotTrusted, CnstIsUpdateCascade, ExecIsAfterTrigger, ExecIsAnsiNullsOn, ExecIsDeleteTrigger, ExecIsFirstDeleteTrigger, ExecIsFirstInsertTrigger, ExecIsFirstUpdateTrigger, ExecIsInsertTrigger, ExecIsInsteadOfTrigger, ExecIsLastDeleteTrigger, ExecIsLastInsertTrigger, ExecIsLastUpdateTrigger, ExecIsQuotedIdentOn, ExecIsStartup, ExecIsTriggerDisabled, ExecIsTriggerNotForRepl, ExecIsUpdateTrigger, ExecIsWithNativeCompilation, HasAfterTrigger, HasDeleteTrigger, HasInsertTrigger, HasInsteadOfTrigger, HasUpdateTrigger, IsAnsiNullsOn, IsCheckCnst, IsConstraint, IsDefault, IsDefaultCnst, IsDeterministic, IsEncrypted, IsExecuted, IsExtendedProc, IsForeignKey, IsIndexed, IsIndexable, IsInlineFunction, IsMSShipped, IsPrecise, IsPrimaryKey, IsProcedure, IsQuotedIdentOn, IsQueue, IsReplProc, IsRule, IsScalarFunction, IsSchemaBound, IsSystemTable, IsSystemVerified, IsTable, IsTableFunction, IsTrigger, IsUniqueCnst, IsUserTable, IsView, OwnerId, SchemaId, SystemDataAccess, TableDeleteTrigger, TableDeleteTriggerCount, TableFullTextMergeStatus, TableFullTextBackgroundUpdateIndexOn, TableFulltextCatalogId, TableFullTextChangeTrackingOn, TableFulltextKeyColumn, TableFulltextPopulateStatus, TableFullTextSemanticExtraction, TableHasActiveFulltextIndex, TableHasCheckCnst, TableHasClustIndex, TableHasDefaultCnst, TableHasDeleteTrigger, TableHasForeignKey, TableHasForeignRef, TableHasIdentity, TableHasIndex, TableHasInsertTrigger, TableHasNonclustIndex, TableHasPrimaryKey, TableHasRowGuidCol, TableHasTextImage, TableHasTimestamp, TableHasUniqueCnst, TableHasUpdateTrigger, TableHasVarDecimalStorageFormat, TableInsertTrigger, TableInsertTriggerCount, TableIsFake, TableIsLockedOnBulkLoad, TableIsMemoryOptimized, TableIsPinned, TableTextInRowLimit, TableUpdateTrigger, TableUpdateTriggerCount, UserDataAccess, TableHasColumnSet, Cardinality, TableTemporalType)
            SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.BaseType, d.CnstIsClustKey, d.CnstIsColumn, d.CnstIsDeleteCascade, d.CnstIsDisabled, d.CnstIsNonclustKey, d.CnstIsNotRepl, d.CnstIsNotTrusted, d.CnstIsUpdateCascade, d.ExecIsAfterTrigger, d.ExecIsAnsiNullsOn, d.ExecIsDeleteTrigger, d.ExecIsFirstDeleteTrigger, d.ExecIsFirstInsertTrigger, d.ExecIsFirstUpdateTrigger, d.ExecIsInsertTrigger, d.ExecIsInsteadOfTrigger, d.ExecIsLastDeleteTrigger, d.ExecIsLastInsertTrigger, d.ExecIsLastUpdateTrigger, d.ExecIsQuotedIdentOn, d.ExecIsStartup, d.ExecIsTriggerDisabled, d.ExecIsTriggerNotForRepl, d.ExecIsUpdateTrigger, d.ExecIsWithNativeCompilation, d.HasAfterTrigger, d.HasDeleteTrigger, d.HasInsertTrigger, d.HasInsteadOfTrigger, d.HasUpdateTrigger, d.IsAnsiNullsOn, d.IsCheckCnst, d.IsConstraint, d.IsDefault, d.IsDefaultCnst, d.IsDeterministic, d.IsEncrypted, d.IsExecuted, d.IsExtendedProc, d.IsForeignKey, d.IsIndexed, d.IsIndexable, d.IsInlineFunction, d.IsMSShipped, d.IsPrecise, d.IsPrimaryKey, d.IsProcedure, d.IsQuotedIdentOn, d.IsQueue, d.IsReplProc, d.IsRule, d.IsScalarFunction, d.IsSchemaBound, d.IsSystemTable, d.IsSystemVerified, d.IsTable, d.IsTableFunction, d.IsTrigger, d.IsUniqueCnst, d.IsUserTable, d.IsView, d.OwnerId, d.SchemaId, d.SystemDataAccess, d.TableDeleteTrigger, d.TableDeleteTriggerCount, d.TableFullTextMergeStatus, d.TableFullTextBackgroundUpdateIndexOn, d.TableFulltextCatalogId, d.TableFullTextChangeTrackingOn, d.TableFulltextKeyColumn, d.TableFulltextPopulateStatus, d.TableFullTextSemanticExtraction, d.TableHasActiveFulltextIndex, d.TableHasCheckCnst, d.TableHasClustIndex, d.TableHasDefaultCnst, d.TableHasDeleteTrigger, d.TableHasForeignKey, d.TableHasForeignRef, d.TableHasIdentity, d.TableHasIndex, d.TableHasInsertTrigger, d.TableHasNonclustIndex, d.TableHasPrimaryKey, d.TableHasRowGuidCol, d.TableHasTextImage, d.TableHasTimestamp, d.TableHasUniqueCnst, d.TableHasUpdateTrigger, d.TableHasVarDecimalStorageFormat, d.TableInsertTrigger, d.TableInsertTriggerCount, d.TableIsFake, d.TableIsLockedOnBulkLoad, d.TableIsMemoryOptimized, d.TableIsPinned, d.TableTextInRowLimit, d.TableUpdateTrigger, d.TableUpdateTriggerCount, d.UserDataAccess, d.TableHasColumnSet, d.Cardinality, d.TableTemporalType
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._OBJECTPROPERTYEX x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
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
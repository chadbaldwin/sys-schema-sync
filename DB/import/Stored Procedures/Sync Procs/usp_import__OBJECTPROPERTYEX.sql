CREATE PROCEDURE import.usp_import__OBJECTPROPERTYEX (
    @DatabaseID int,
    @Dataset    import.import__OBJECTPROPERTYEX READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

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
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose, @Verbose = @Verbose;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._OBJECTPROPERTYEX';

    IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._OBJECTPROPERTYEX x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID);
    IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                          = SYSUTCDATETIME()
        , x._RowHash                             = d._RowHash
        --
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
        JOIN @output y ON y._ObjectID = x._ObjectID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._OBJECTPROPERTYEX (_DatabaseID, _ObjectID, _RowHash
        , BaseType, CnstIsClustKey, CnstIsColumn, CnstIsDeleteCascade, CnstIsDisabled, CnstIsNonclustKey, CnstIsNotRepl, CnstIsNotTrusted, CnstIsUpdateCascade, ExecIsAfterTrigger, ExecIsAnsiNullsOn, ExecIsDeleteTrigger, ExecIsFirstDeleteTrigger, ExecIsFirstInsertTrigger, ExecIsFirstUpdateTrigger, ExecIsInsertTrigger, ExecIsInsteadOfTrigger, ExecIsLastDeleteTrigger, ExecIsLastInsertTrigger, ExecIsLastUpdateTrigger, ExecIsQuotedIdentOn, ExecIsStartup, ExecIsTriggerDisabled, ExecIsTriggerNotForRepl, ExecIsUpdateTrigger, ExecIsWithNativeCompilation, HasAfterTrigger, HasDeleteTrigger, HasInsertTrigger, HasInsteadOfTrigger, HasUpdateTrigger, IsAnsiNullsOn, IsCheckCnst, IsConstraint, IsDefault, IsDefaultCnst, IsDeterministic, IsEncrypted, IsExecuted, IsExtendedProc, IsForeignKey, IsIndexed, IsIndexable, IsInlineFunction, IsMSShipped, IsPrecise, IsPrimaryKey, IsProcedure, IsQuotedIdentOn, IsQueue, IsReplProc, IsRule, IsScalarFunction, IsSchemaBound, IsSystemTable, IsSystemVerified, IsTable, IsTableFunction, IsTrigger, IsUniqueCnst, IsUserTable, IsView, OwnerId, SchemaId, SystemDataAccess, TableDeleteTrigger, TableDeleteTriggerCount, TableFullTextMergeStatus, TableFullTextBackgroundUpdateIndexOn, TableFulltextCatalogId, TableFullTextChangeTrackingOn, TableFulltextKeyColumn, TableFulltextPopulateStatus, TableFullTextSemanticExtraction, TableHasActiveFulltextIndex, TableHasCheckCnst, TableHasClustIndex, TableHasDefaultCnst, TableHasDeleteTrigger, TableHasForeignKey, TableHasForeignRef, TableHasIdentity, TableHasIndex, TableHasInsertTrigger, TableHasNonclustIndex, TableHasPrimaryKey, TableHasRowGuidCol, TableHasTextImage, TableHasTimestamp, TableHasUniqueCnst, TableHasUpdateTrigger, TableHasVarDecimalStorageFormat, TableInsertTrigger, TableInsertTriggerCount, TableIsFake, TableIsLockedOnBulkLoad, TableIsMemoryOptimized, TableIsPinned, TableTextInRowLimit, TableUpdateTrigger, TableUpdateTriggerCount, UserDataAccess, TableHasColumnSet, Cardinality, TableTemporalType)
    SELECT @DatabaseID, y._ObjectID, d._RowHash
        , d.BaseType, d.CnstIsClustKey, d.CnstIsColumn, d.CnstIsDeleteCascade, d.CnstIsDisabled, d.CnstIsNonclustKey, d.CnstIsNotRepl, d.CnstIsNotTrusted, d.CnstIsUpdateCascade, d.ExecIsAfterTrigger, d.ExecIsAnsiNullsOn, d.ExecIsDeleteTrigger, d.ExecIsFirstDeleteTrigger, d.ExecIsFirstInsertTrigger, d.ExecIsFirstUpdateTrigger, d.ExecIsInsertTrigger, d.ExecIsInsteadOfTrigger, d.ExecIsLastDeleteTrigger, d.ExecIsLastInsertTrigger, d.ExecIsLastUpdateTrigger, d.ExecIsQuotedIdentOn, d.ExecIsStartup, d.ExecIsTriggerDisabled, d.ExecIsTriggerNotForRepl, d.ExecIsUpdateTrigger, d.ExecIsWithNativeCompilation, d.HasAfterTrigger, d.HasDeleteTrigger, d.HasInsertTrigger, d.HasInsteadOfTrigger, d.HasUpdateTrigger, d.IsAnsiNullsOn, d.IsCheckCnst, d.IsConstraint, d.IsDefault, d.IsDefaultCnst, d.IsDeterministic, d.IsEncrypted, d.IsExecuted, d.IsExtendedProc, d.IsForeignKey, d.IsIndexed, d.IsIndexable, d.IsInlineFunction, d.IsMSShipped, d.IsPrecise, d.IsPrimaryKey, d.IsProcedure, d.IsQuotedIdentOn, d.IsQueue, d.IsReplProc, d.IsRule, d.IsScalarFunction, d.IsSchemaBound, d.IsSystemTable, d.IsSystemVerified, d.IsTable, d.IsTableFunction, d.IsTrigger, d.IsUniqueCnst, d.IsUserTable, d.IsView, d.OwnerId, d.SchemaId, d.SystemDataAccess, d.TableDeleteTrigger, d.TableDeleteTriggerCount, d.TableFullTextMergeStatus, d.TableFullTextBackgroundUpdateIndexOn, d.TableFulltextCatalogId, d.TableFullTextChangeTrackingOn, d.TableFulltextKeyColumn, d.TableFulltextPopulateStatus, d.TableFullTextSemanticExtraction, d.TableHasActiveFulltextIndex, d.TableHasCheckCnst, d.TableHasClustIndex, d.TableHasDefaultCnst, d.TableHasDeleteTrigger, d.TableHasForeignKey, d.TableHasForeignRef, d.TableHasIdentity, d.TableHasIndex, d.TableHasInsertTrigger, d.TableHasNonclustIndex, d.TableHasPrimaryKey, d.TableHasRowGuidCol, d.TableHasTextImage, d.TableHasTimestamp, d.TableHasUniqueCnst, d.TableHasUpdateTrigger, d.TableHasVarDecimalStorageFormat, d.TableInsertTrigger, d.TableInsertTriggerCount, d.TableIsFake, d.TableIsLockedOnBulkLoad, d.TableIsMemoryOptimized, d.TableIsPinned, d.TableTextInRowLimit, d.TableUpdateTrigger, d.TableUpdateTriggerCount, d.UserDataAccess, d.TableHasColumnSet, d.Cardinality, d.TableTemporalType
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._OBJECTPROPERTYEX x
            WHERE x._ObjectID = y._ObjectID
        );
    IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
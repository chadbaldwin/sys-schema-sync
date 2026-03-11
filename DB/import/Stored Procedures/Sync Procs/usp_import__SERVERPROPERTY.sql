CREATE PROC import.usp_import__SERVERPROPERTY (
    @InstanceID int,
    @Dataset    import.import__SERVERPROPERTY READONLY,
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
            SELECT TOP (0) * INTO #Dataset FROM dbo._SERVERPROPERTY;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_InstanceID);

            INSERT #Dataset WITH(TABLOCK) (_InstanceID, _RowHash, BuildClrVersion, Collation, CollationID, ComparisonStyle, ComputerNamePhysicalNetBIOS, Edition, EditionID, EngineEdition, FilestreamConfiguredLevel, FilestreamEffectiveLevel, FilestreamShareName, HadrManagerStatus, InstanceDefaultBackupPath, InstanceDefaultDataPath, InstanceDefaultLogPath, InstanceName, IsAdvancedAnalyticsInstalled, IsBigDataCluster, IsClustered, IsExternalAuthenticationOnly, IsExternalGovernanceEnabled, IsFullTextInstalled, IsHadrEnabled, IsIntegratedSecurityOnly, IsLocalDB, IsPolyBaseInstalled, IsServerSuspendedForSnapshotBackup, IsSingleUser, IsTempDbMetadataMemoryOptimized, IsXTPSupported, LCID, LicenseType, MachineName, NumLicenses, PathSeparator, ProcessID, ProductBuild, ProductBuildType, ProductLevel, ProductMajorVersion, ProductMinorVersion, ProductUpdateLevel, ProductUpdateReference, ProductUpdateType, ProductVersion, ResourceLastUpdateDateTime, ResourceVersion, ServerName, SqlCharSet, SqlCharSetName, SqlSortOrder, SqlSortOrderName, SuspendedDatabaseCount)
            SELECT @InstanceID, d._RowHash, d.BuildClrVersion, d.Collation, d.CollationID, d.ComparisonStyle, d.ComputerNamePhysicalNetBIOS, d.Edition, d.EditionID, d.EngineEdition, d.FilestreamConfiguredLevel, d.FilestreamEffectiveLevel, d.FilestreamShareName, d.HadrManagerStatus, d.InstanceDefaultBackupPath, d.InstanceDefaultDataPath, d.InstanceDefaultLogPath, d.InstanceName, d.IsAdvancedAnalyticsInstalled, d.IsBigDataCluster, d.IsClustered, d.IsExternalAuthenticationOnly, d.IsExternalGovernanceEnabled, d.IsFullTextInstalled, d.IsHadrEnabled, d.IsIntegratedSecurityOnly, d.IsLocalDB, d.IsPolyBaseInstalled, d.IsServerSuspendedForSnapshotBackup, d.IsSingleUser, d.IsTempDbMetadataMemoryOptimized, d.IsXTPSupported, d.LCID, d.LicenseType, d.MachineName, d.NumLicenses, d.PathSeparator, d.ProcessID, d.ProductBuild, d.ProductBuildType, d.ProductLevel, d.ProductMajorVersion, d.ProductMinorVersion, d.ProductUpdateLevel, d.ProductUpdateReference, d.ProductUpdateType, d.ProductVersion, d.ResourceLastUpdateDateTime, d.ResourceVersion, d.ServerName, d.SqlCharSet, d.SqlCharSetName, d.SqlSortOrder, d.SqlSortOrderName, d.SuspendedDatabaseCount
            FROM @Dataset d;
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @InstanceID = @InstanceID, @TargetTable = 'dbo._SERVERPROPERTY';
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
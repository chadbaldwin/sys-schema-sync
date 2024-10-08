CREATE TABLE dbo._SERVERPROPERTY (
    _InstanceID                         int             NOT NULL CONSTRAINT FK__SERVERPROPERTY__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    _CollectionDate                     datetime2       NOT NULL,
    --
    BuildClrVersion                     nvarchar(128)       NULL,
    Collation                           nvarchar(128)       NULL,
    CollationID                         int                 NULL,
    ComparisonStyle                     int                 NULL,
    ComputerNamePhysicalNetBIOS         nvarchar(128)       NULL,
    Edition                             nvarchar(128)       NULL,
    EditionID                           int                 NULL,
    EngineEdition                       int                 NULL,
    FilestreamConfiguredLevel           int                 NULL,
    FilestreamEffectiveLevel            int                 NULL,
    FilestreamShareName                 nvarchar(128)       NULL,
    HadrManagerStatus                   int                 NULL,
    InstanceDefaultBackupPath           nvarchar(128)       NULL,
    InstanceDefaultDataPath             nvarchar(128)       NULL,
    InstanceDefaultLogPath              nvarchar(128)       NULL,
    InstanceName                        nvarchar(128)       NULL,
    IsAdvancedAnalyticsInstalled        int                 NULL,
    IsBigDataCluster                    int                 NULL,
    IsClustered                         int                 NULL,
    IsExternalAuthenticationOnly        int                 NULL,
    IsExternalGovernanceEnabled         int                 NULL,
    IsFullTextInstalled                 int                 NULL,
    IsHadrEnabled                       int                 NULL,
    IsIntegratedSecurityOnly            int                 NULL,
    IsLocalDB                           int                 NULL,
    IsPolyBaseInstalled                 int                 NULL,
    IsServerSuspendedForSnapshotBackup  int                 NULL,
    IsSingleUser                        int                 NULL,
    IsTempDbMetadataMemoryOptimized     int                 NULL,
    IsXTPSupported                      int                 NULL,
    LCID                                int                 NULL,
    LicenseType                         nvarchar(128)       NULL,
    MachineName                         nvarchar(128)       NULL,
    NumLicenses                         int                 NULL,
    PathSeparator                       nvarchar(128)       NULL,
    ProcessID                           int                 NULL,
    ProductBuild                        nvarchar(128)       NULL,
    ProductBuildType                    nvarchar(128)       NULL,
    ProductLevel                        nvarchar(128)       NULL,
    ProductMajorVersion                 nvarchar(128)       NULL,
    ProductMinorVersion                 nvarchar(128)       NULL,
    ProductUpdateLevel                  nvarchar(128)       NULL,
    ProductUpdateReference              nvarchar(128)       NULL,
    ProductVersion                      nvarchar(128)       NULL,
    ResourceLastUpdateDateTime          datetime            NULL,
    ResourceVersion                     nvarchar(128)       NULL,
    ServerName                          nvarchar(128)       NULL,
    SqlCharSet                          tinyint             NULL,
    SqlCharSetName                      nvarchar(128)       NULL,
    SqlSortOrder                        tinyint             NULL,
    SqlSortOrderName                    nvarchar(128)       NULL,
    SuspendedDatabaseCount              int                 NULL,

    INDEX CIX__SERVERPROPERTY__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

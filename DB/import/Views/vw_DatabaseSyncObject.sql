CREATE VIEW import.vw_DatabaseSyncObject
AS
-- Database level syncs
SELECT d._InstanceID, d._DatabaseID, d.InstanceName, d.DatabaseName
    , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID
    , dso.LastSyncChecksum, dso.LastSyncTime, dso.LastSyncCheck, dso.LastSyncError, dso.LastSyncErrorMessage
    , so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.ChecksumQueryText, so.SyncStaleAgeMinutes
FROM dbo.vw_Database d
    CROSS JOIN import.SyncObject so
    LEFT JOIN import.DatabaseSyncObjectStatus dso ON so.SyncObjectID = dso.SyncObjectID AND dso._DatabaseID = d._DatabaseID
WHERE so.SyncObjectLevelID = 2
    AND so.IsEnabled = 1
UNION
-- Instance level syncs
SELECT i._InstanceID, NULL, i.InstanceName, 'master'
    , so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID
    , dso.LastSyncChecksum, dso.LastSyncTime, dso.LastSyncCheck, dso.LastSyncError, dso.LastSyncErrorMessage
    , so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.ChecksumQueryText, so.SyncStaleAgeMinutes
FROM dbo.vw_Instance i
    CROSS JOIN import.SyncObject so
    LEFT JOIN import.DatabaseSyncObjectStatus dso ON so.SyncObjectID = dso.SyncObjectID AND dso._InstanceID = i._InstanceID AND dso._DatabaseID IS NULL
WHERE so.SyncObjectLevelID = 1
    AND so.IsEnabled = 1;
GO
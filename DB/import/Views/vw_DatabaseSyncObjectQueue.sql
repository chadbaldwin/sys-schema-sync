CREATE VIEW import.vw_DatabaseSyncObjectQueue
AS
SELECT so.InstanceID, so.DatabaseID, so.InstanceName, so.DatabaseName
	, so.SyncObjectID, so.SyncObjectName, so.SyncObjectLevelID
	, so.LastSyncChecksum, so.LastSyncTime, so.LastSyncCheck, so.LastSyncError, so.LastSyncErrorMessage
	, so.ImportTable, so.ImportProc, so.ImportType, so.ExportQueryPath, so.ChecksumQueryText
FROM import.vw_DatabaseSyncObject so
WHERE (so.SyncStaleAgeMinutes <= FLOOR(DATEDIFF_BIG(SECOND, so.LastSyncCheck, SYSUTCDATETIME()) / 60.0) OR so.LastSyncCheck IS NULL);
CREATE VIEW import.vw_DatabaseQueue
AS
SELECT InstanceName, DatabaseName, SyncTaskCount = COUNT(*)
FROM import.vw_DatabaseSyncObjectQueue
GROUP BY InstanceName, DatabaseName;
GO

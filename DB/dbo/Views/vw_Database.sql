CREATE VIEW dbo.vw_Database
AS
SELECT i.InstanceID, i.InstanceName
    , d.DatabaseID, d.DatabaseName
    , DatabaseNamespace = CONCAT_WS('\', i.InstanceName, d.DatabaseName)
    , IsPrimaryReplica = rs.is_primary_replica
FROM dbo.[Database] d
    JOIN dbo.vw_Instance i ON i.InstanceID = d.InstanceID
    LEFT JOIN dbo._dm_hadr_database_replica_states rs ON rs._DatabaseID = d.DatabaseID AND rs.is_local = 1
WHERE d.IsEnabled = 1;
GO

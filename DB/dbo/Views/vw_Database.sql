CREATE VIEW dbo.vw_Database
WITH SCHEMABINDING
AS
SELECT i._InstanceID, i.InstanceName
    , d._DatabaseID, d.DatabaseName
FROM dbo.Instance i
    JOIN dbo.[Database] d ON d._InstanceID = i._InstanceID
WHERE i.IsEnabled = 1 AND d.IsEnabled = 1;
GO
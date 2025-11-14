CREATE VIEW dbo.vw_Instance
WITH SCHEMABINDING
AS
SELECT i._InstanceID, i.InstanceName
FROM dbo.Instance i
WHERE i.IsEnabled = 1;
GO
CREATE UNIQUE CLUSTERED INDEX CIX_vw_Instance__InstanceID ON dbo.vw_Instance (_InstanceID);
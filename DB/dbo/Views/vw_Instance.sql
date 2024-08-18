CREATE VIEW dbo.vw_Instance
AS
SELECT i.InstanceID, i.InstanceName
FROM dbo.Instance i
WHERE i.IsEnabled = 1;
GO

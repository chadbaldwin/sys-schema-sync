CREATE VIEW dbo.vw_Object
AS
SELECT i._InstanceID, i.InstanceName
    , d._DatabaseID, d.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , o.FQON
FROM dbo.Instance i
    JOIN dbo.[Database] d ON d._InstanceID = i._InstanceID
    JOIN dbo.[Object] o ON o._DatabaseID = d._DatabaseID
WHERE i.IsEnabled = 1 AND d.IsEnabled = 1 AND o.IsDeleted = 0;
GO
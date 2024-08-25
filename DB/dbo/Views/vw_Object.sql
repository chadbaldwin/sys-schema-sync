CREATE VIEW dbo.vw_Object
AS
SELECT d._InstanceID, d.InstanceName
    , d._DatabaseID, d.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
FROM dbo.[Object] o
    JOIN dbo.vw_Database d ON d._DatabaseID = o._DatabaseID
WHERE o.IsDeleted = 0;
GO

CREATE VIEW dbo.vw_Column
WITH SCHEMABINDING
AS
SELECT i._InstanceID, i.InstanceName
    , d._DatabaseID, d.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , c._ColumnID, c.ColumnName
FROM dbo.Instance i
    JOIN dbo.[Database] d ON d._InstanceID = i._InstanceID
    JOIN dbo.[Object] o ON o._DatabaseID = d._DatabaseID
    JOIN dbo.[Column] c ON c._DatabaseID = o._DatabaseID AND c._ObjectID = o._ObjectID
WHERE i.IsEnabled = 1 AND d.IsEnabled = 1 AND o.IsDeleted = 0 AND c.IsDeleted = 0;
GO
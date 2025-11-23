CREATE VIEW dbo.vw_Index
WITH SCHEMABINDING
AS
SELECT i._InstanceID, i.InstanceName
    , d._DatabaseID, d.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , ix._IndexID, ix.IndexName
    , FQIN = CONCAT_WS('.', QUOTENAME(o.SchemaName), QUOTENAME(o.ObjectName), QUOTENAME(ix.IndexName))
FROM dbo.Instance i
    JOIN dbo.[Database] d ON d._InstanceID = i._InstanceID
    JOIN dbo.[Object] o ON o._DatabaseID = d._DatabaseID
    JOIN dbo.[Index] ix ON ix._DatabaseID = o._DatabaseID AND ix._ObjectID = o._ObjectID
WHERE i.IsEnabled = 1 AND d.IsEnabled = 1 AND o.IsDeleted = 0 AND ix.IsDeleted = 0;
GO
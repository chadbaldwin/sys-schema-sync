CREATE VIEW dbo.vw_Index
AS
SELECT o._InstanceID, o.InstanceName
    , o._DatabaseID, o.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , i._IndexID, i.IndexName, f.FQIN
FROM dbo.[Index] i
    JOIN dbo.vw_Object o ON o._DatabaseID = i._DatabaseID AND o._ObjectID = i._ObjectID
    CROSS APPLY (SELECT FQIN = CONCAT_WS('.', QUOTENAME(o.SchemaName), QUOTENAME(o.ObjectName), QUOTENAME(i.IndexName))) f
WHERE i.IsDeleted = 0;
GO

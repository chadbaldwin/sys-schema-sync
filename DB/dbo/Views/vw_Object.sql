CREATE VIEW dbo.vw_Object
AS
SELECT d.InstanceID, d.InstanceName
    , d.DatabaseID, d.DatabaseName
    , o.ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
FROM dbo.[Object] o
    JOIN dbo.vw_Database d ON d.DatabaseID = o.DatabaseID
WHERE o.IsDeleted = 0;
GO

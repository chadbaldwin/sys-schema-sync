CREATE VIEW dbo.vw_Index
AS
SELECT o.InstanceID, o.InstanceName
	, o.DatabaseID, o.DatabaseName
	, o.ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
	, i.IndexID, i.IndexName, f.FQIN
FROM dbo.[Index] i
	JOIN dbo.vw_Object o ON o.DatabaseID = i.DatabaseID AND o.ObjectID = i.ObjectID
	CROSS APPLY (SELECT FQIN = CONCAT_WS('.', QUOTENAME(o.SchemaName), QUOTENAME(o.ObjectName), QUOTENAME(i.IndexName))) f
WHERE i.IsDeleted = 0;
GO

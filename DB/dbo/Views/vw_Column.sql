CREATE VIEW dbo.vw_Column
AS
SELECT o.InstanceID, o.InstanceName
    , o.DatabaseID, o.DatabaseName
    , o.ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , c.ColumnID, c.ColumnName
FROM dbo.[Column] c
    JOIN dbo.vw_Object o ON o.DatabaseID = c.DatabaseID AND o.ObjectID = c.ObjectID
WHERE c.IsDeleted = 0;
GO

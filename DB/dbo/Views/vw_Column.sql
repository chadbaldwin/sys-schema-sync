CREATE VIEW dbo.vw_Column
AS
SELECT o._InstanceID, o.InstanceName
    , o._DatabaseID, o.DatabaseName
    , o._ObjectID, o.SchemaName, o.ObjectName, o.ObjectType
    , c._ColumnID, c.ColumnName
FROM dbo.[Column] c
    JOIN dbo.vw_Object o ON o._DatabaseID = c._DatabaseID AND o._ObjectID = c._ObjectID
WHERE c.IsDeleted = 0;
GO

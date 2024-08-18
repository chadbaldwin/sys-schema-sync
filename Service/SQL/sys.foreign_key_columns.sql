WITH cte_obj AS (
	SELECT o.[object_id], ObjectType = o.[type], SchemaName = s.[name], ObjectName = o.[name]
	FROM sys.objects o
		JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
	WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
	, _ObjectName = o.ObjectName
	, _ObjectType = o.ObjectType
	, _ParentSchemaName = po.SchemaName
	, _ParentObjectName = po.ObjectName
	, _ParentObjectType = po.ObjectType
	, _ParentColumnName = pc.[name]
	, _ReferencedSchemaName = ro.SchemaName
	, _ReferencedObjectName = ro.ObjectName
	, _ReferencedObjectType = ro.ObjectType
	, _ReferencedColumnName = rc.[name]
	, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
	--
	, x.*
FROM sys.foreign_key_columns x
	JOIN cte_obj o  ON  o.[object_id] = x.constraint_object_id
	JOIN cte_obj po ON po.[object_id] = x.parent_object_id
	JOIN sys.columns pc ON pc.[object_id] = x.parent_object_id AND pc.column_id = x.parent_column_id
	JOIN cte_obj ro ON ro.[object_id] = x.referenced_object_id
	JOIN sys.columns rc ON rc.[object_id] = x.referenced_object_id AND rc.column_id = x.referenced_column_id;
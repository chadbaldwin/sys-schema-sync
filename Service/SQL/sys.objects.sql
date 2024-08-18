SELECT _SchemaName = s.[name]
	, _ObjectName = x.[name]
	, _ObjectType = x.[type]
	, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
	--
	, x.*
FROM (
	SELECT x.[name], x.[object_id], x.principal_id, x.[schema_id], x.parent_object_id, x.[type], x.[type_desc], x.create_date/*, x.modify_date*/, x.is_ms_shipped, x.is_published, x.is_schema_published
	FROM sys.objects x
) x
	JOIN sys.schemas s ON s.[schema_id] = x.[schema_id]
WHERE x.is_ms_shipped = 0;
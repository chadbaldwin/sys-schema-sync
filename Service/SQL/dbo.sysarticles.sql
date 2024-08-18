IF (OBJECT_ID('dbo.sysarticles') IS NOT NULL)
BEGIN;
	SELECT _SchemaName = s.[name]
		, _ObjectName = o.[name]
		, _ObjectType = o.[type]
		, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
		--
		, x.*
	FROM dbo.sysarticles x
		JOIN sys.objects o ON o.[object_id] = x.[objid]
		JOIN sys.schemas s ON s.[schema_id] = o.[schema_id];
END;
DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
	SELECT _SchemaName = s.[name]
		, _ObjectName = o.[name]
		, _ObjectType = o.[type]
		, _IndexName = IIF(x.[type] = 0, '<<HEAP>>', x.[name])
		, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
		--
		, x.*
		--
		, optimize_for_sequential_key = CONVERT(bit, NULL) -- Added: SQL Server 2019
	FROM sys.indexes x
		JOIN sys.objects o ON o.[object_id] = x.[object_id]
		JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
	WHERE o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
	SELECT _SchemaName = s.[name]
		, _ObjectName = o.[name]
		, _ObjectType = o.[type]
		, _IndexName = IIF(x.[type] = 0, '<<HEAP>>', x.[name])
		, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
		--
		, x.*
	FROM sys.indexes x
		JOIN sys.objects o ON o.[object_id] = x.[object_id]
		JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
	WHERE o.is_ms_shipped = 0;
END;

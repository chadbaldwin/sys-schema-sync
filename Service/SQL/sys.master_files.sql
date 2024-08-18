SELECT _DatabaseName = DB_NAME(x.database_id)
	, _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
	, x.*
FROM sys.master_files x;
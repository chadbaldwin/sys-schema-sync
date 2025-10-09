SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
	--
	, x.*
FROM sys.database_automatic_tuning_options x;
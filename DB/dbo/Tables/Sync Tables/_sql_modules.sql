CREATE TABLE dbo._sql_modules (
	_DatabaseID				int				NOT	NULL CONSTRAINT FK__sql_modules__DatabaseID	REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID				int				NOT	NULL CONSTRAINT FK__sql_modules__ObjectID	REFERENCES dbo.[Object]		(ObjectID),
	_InsertDate				datetime2		NOT	NULL CONSTRAINT DF__sql_modules__InsertDate	DEFAULT (SYSUTCDATETIME()),
	_ModifyDate				datetime2		NOT	NULL CONSTRAINT DF__sql_modules__ModifyDate	DEFAULT (SYSUTCDATETIME()),
	_RowHash				binary(32)		NOT	NULL,
	_ValidFrom				datetime2		GENERATED ALWAYS AS ROW START	NOT	NULL,
	_ValidTo				datetime2		GENERATED ALWAYS AS ROW END		NOT	NULL,
	--
	[object_id]				int				NOT	NULL,
	_ObjectDefinitionID		int				NOT NULL CONSTRAINT FK__sql_modules__ObjectDefinitionID REFERENCES dbo.ObjectDefinition (ObjectDefinitionID),
	uses_ansi_nulls			bit					NULL,
	uses_quoted_identifier	bit					NULL,
	is_schema_bound			bit					NULL,
	uses_database_collation	bit					NULL,
	is_recompiled			bit					NULL,
	null_on_null_input		bit					NULL,
	execute_as_principal_id	int					NULL,
	uses_native_compilation	bit					NULL,
	inline_type				bit					NULL, -- Added: SQL Server 2019
	is_inlineable			bit					NULL, -- Added: SQL Server 2019

	PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
	CONSTRAINT CPK__sql_modules__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
	INDEX IX__sql_modules__DatabaseID NONCLUSTERED (_DatabaseID),
	INDEX IX__sql_modules__ObjectDefinitionID NONCLUSTERED (_ObjectDefinitionID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._sql_modules_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

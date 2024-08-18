CREATE TABLE dbo._sql_modules_history (
	_DatabaseID				int				NOT	NULL,
	_ObjectID				int				NOT	NULL,
	_InsertDate				datetime2		NOT	NULL,
	_ModifyDate				datetime2		NOT	NULL,
	_RowHash				binary(32)		NOT	NULL,
	_ValidFrom				datetime2		NOT	NULL,
	_ValidTo				datetime2		NOT	NULL,
	--
	[object_id]				int				NOT	NULL,
	_ObjectDefinitionID		int				NOT NULL,
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

	INDEX CIX__sql_modules_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);

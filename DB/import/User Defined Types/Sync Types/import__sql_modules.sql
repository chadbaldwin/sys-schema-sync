CREATE TYPE import.import__sql_modules AS TABLE (
	_SchemaName				nvarchar(128)	NOT	NULL,
	_ObjectName				nvarchar(128)	NOT	NULL,
	_ObjectType				char(2)			NOT	NULL,
	_ObjectDefinitionHash	binary(32)		NOT	NULL,
	_RowHash				binary(32)		NOT	NULL,
	--
	[object_id]				int				NOT	NULL,
	[definition]			nvarchar(MAX)		NULL,
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

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType)
);

CREATE TYPE import.import__stats AS TABLE (
	_SchemaName						nvarchar(128)	NOT	NULL,
	_ObjectName						nvarchar(128)	NOT	NULL,
	_ObjectType						char(2)			NOT	NULL,
	_IndexName						nvarchar(128)	NOT	NULL,
	_RowHash						binary(32)		NOT	NULL,
	--
	[object_id]						int				NOT	NULL,
	[name]							nvarchar(128)		NULL,
	stats_id						int				NOT	NULL,
	auto_created					bit					NULL,
	user_created					bit					NULL,
	no_recompute					bit					NULL,
	has_filter						bit					NULL,
	filter_definition				nvarchar(MAX)		NULL,
	is_temporary					bit					NULL,
	is_incremental					bit					NULL,
	has_persisted_sample			bit					NULL, -- Added: SQL Server 2019
	stats_generation_method			int					NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL
	stats_generation_method_desc	varchar(80)			NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL
	auto_drop						bit					NULL, -- Added: SQL Server 2022

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName)
);

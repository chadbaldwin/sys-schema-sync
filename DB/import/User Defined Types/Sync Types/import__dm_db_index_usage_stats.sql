CREATE TYPE import.import__dm_db_index_usage_stats AS TABLE (
	_SchemaName			nvarchar(128)	NOT	NULL,
	_ObjectName			nvarchar(128)	NOT	NULL,
	_ObjectType			char(2)			NOT	NULL,
	_IndexName			nvarchar(128)	NOT	NULL,
	_RowHash			binary(32)		NOT	NULL,
	--
	database_id			smallint		NOT	NULL,
	[object_id]			int				NOT	NULL,
	index_id			int				NOT	NULL,
	user_seeks			bigint			NOT	NULL,
	user_scans			bigint			NOT	NULL,
	user_lookups		bigint			NOT	NULL,
	user_updates		bigint			NOT	NULL,
	last_user_seek		datetime			NULL,
	last_user_scan		datetime			NULL,
	last_user_lookup	datetime			NULL,
	last_user_update	datetime			NULL,
	system_seeks		bigint			NOT	NULL,
	system_scans		bigint			NOT	NULL,
	system_lookups		bigint			NOT	NULL,
	system_updates		bigint			NOT	NULL,
	last_system_seek	datetime			NULL,
	last_system_scan	datetime			NULL,
	last_system_lookup	datetime			NULL,
	last_system_update	datetime			NULL,

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName)
);

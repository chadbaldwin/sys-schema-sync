CREATE TYPE import.import__dm_db_partition_stats AS TABLE (
	_SchemaName							nvarchar(128)	NOT	NULL,
	_ObjectName							nvarchar(128)	NOT	NULL,
	_ObjectType							char(2)			NOT	NULL,
	_IndexName							nvarchar(128)	NOT	NULL,
	_RowHash							binary(32)		NOT	NULL,
	--
	[partition_id]						bigint				NULL,
	[object_id]							int				NOT	NULL,
	index_id							int				NOT	NULL,
	partition_number					int				NOT	NULL,
	in_row_data_page_count				bigint				NULL,
	in_row_used_page_count				bigint				NULL,
	in_row_reserved_page_count			bigint				NULL,
	lob_used_page_count					bigint				NULL,
	lob_reserved_page_count				bigint				NULL,
	row_overflow_used_page_count		bigint				NULL,
	row_overflow_reserved_page_count	bigint				NULL,
	used_page_count						bigint				NULL,
	reserved_page_count					bigint				NULL,
	row_count							bigint				NULL,

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName, partition_number)
);

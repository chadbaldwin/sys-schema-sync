CREATE TYPE import.import__partitions AS TABLE (
	_SchemaName				nvarchar(128)	NOT	NULL,
	_ObjectName				nvarchar(128)	NOT	NULL,
	_ObjectType				char(2)			NOT	NULL,
	_IndexName				nvarchar(128)	NOT	NULL,
	_RowHash				binary(32)		NOT	NULL,
	--
	[partition_id]			bigint			NOT	NULL,
	[object_id]				int				NOT	NULL,
	index_id				int				NOT	NULL,
	partition_number		int				NOT	NULL,
	hobt_id					bigint			NOT	NULL,
	[rows]					bigint				NULL,
	filestream_filegroup_id	smallint		NOT	NULL,
	[data_compression]		tinyint			NOT	NULL,
	data_compression_desc	nvarchar(60)		NULL,
	xml_compression			bit					NULL, -- Added: SQL Server 2022
	xml_compression_desc	varchar(3)			NULL, -- Added: SQL Server 2022

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName, partition_number)
);

CREATE TYPE import.import__index_columns AS TABLE (
	_SchemaName					nvarchar(128)	NOT	NULL,
	_ObjectName					nvarchar(128)	NOT	NULL,
	_ObjectType					char(2)			NOT	NULL,
	_IndexName					nvarchar(128)	NOT	NULL,
	_ColumnName					nvarchar(128)	NOT	NULL,
	_RowHash					binary(32)		NOT	NULL,
	--
	[object_id]					int				NOT	NULL,
	index_id					int				NOT	NULL,
	index_column_id				int				NOT	NULL,
	column_id					int				NOT	NULL,
	key_ordinal					tinyint			NOT	NULL,
	partition_ordinal			tinyint			NOT	NULL,
	is_descending_key			bit					NULL,
	is_included_column			bit					NULL,
	column_store_order_ordinal	tinyint				NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL

	INDEX CIX UNIQUE CLUSTERED (_SchemaName, _ObjectName, _ObjectType, _IndexName, _ColumnName)
);

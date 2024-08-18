CREATE TABLE dbo._index_columns_history (
	_DatabaseID					int			NOT	NULL,
	_ObjectID					int			NOT	NULL,
	_IndexID					int			NOT	NULL,
	_ColumnID					int			NOT	NULL,
	_InsertDate					datetime2	NOT	NULL,
	_ModifyDate					datetime2	NOT	NULL,
	_RowHash					binary(32)	NOT	NULL,
	_ValidFrom					datetime2	NOT	NULL,
	_ValidTo					datetime2	NOT	NULL,
	--
	[object_id]					int			NOT	NULL,
	index_id					int			NOT	NULL,
	index_column_id				int			NOT	NULL,
	column_id					int			NOT	NULL,
	key_ordinal					tinyint		NOT	NULL,
	partition_ordinal			tinyint		NOT	NULL,
	is_descending_key			bit				NULL,
	is_included_column			bit				NULL,
	column_store_order_ordinal	tinyint			NULL, -- Added: SQL Server 2019 - Deviation: NOT NULL

	INDEX CIX__index_columns_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);

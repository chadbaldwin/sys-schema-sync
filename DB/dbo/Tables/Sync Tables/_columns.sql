CREATE TABLE dbo._columns (
	_DatabaseID							int				NOT	NULL CONSTRAINT FK__columns__DatabaseID	REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID							int				NOT	NULL CONSTRAINT FK__columns__ObjectID	REFERENCES dbo.[Object]		(ObjectID),
	_ColumnID							int				NOT	NULL CONSTRAINT FK__columns__ColumnID	REFERENCES dbo.[Column]		(ColumnID),
	_InsertDate							datetime2		NOT	NULL CONSTRAINT DF__columns__InsertDate	DEFAULT (SYSUTCDATETIME()),
	_ModifyDate							datetime2		NOT	NULL CONSTRAINT DF__columns__ModifyDate	DEFAULT (SYSUTCDATETIME()),
	_RowHash							binary(32)		NOT	NULL,
	_ValidFrom							datetime2		GENERATED ALWAYS AS ROW START	NOT	NULL,
	_ValidTo							datetime2		GENERATED ALWAYS AS ROW END		NOT	NULL,
	--
	[object_id]							int				NOT	NULL,
	[name]								nvarchar(128)		NULL,
	column_id							int				NOT	NULL,
	system_type_id						tinyint			NOT	NULL,
	user_type_id						int				NOT	NULL,
	max_length							smallint		NOT	NULL,
	[precision]							tinyint			NOT	NULL,
	scale								tinyint			NOT	NULL,
	collation_name						nvarchar(128)		NULL,
	is_nullable							bit					NULL,
	is_ansi_padded						bit				NOT	NULL,
	is_rowguidcol						bit				NOT	NULL,
	is_identity							bit				NOT	NULL,
	is_computed							bit					NULL,
	is_filestream						bit				NOT	NULL,
	is_replicated						bit					NULL,
	is_non_sql_subscribed				bit					NULL,
	is_merge_published					bit					NULL,
	is_dts_replicated					bit					NULL,
	is_xml_document						bit				NOT	NULL,
	xml_collection_id					int				NOT	NULL,
	default_object_id					int				NOT	NULL,
	rule_object_id						int				NOT	NULL,
	is_sparse							bit					NULL,
	is_column_set						bit					NULL,
	generated_always_type				tinyint				NULL,
	generated_always_type_desc			nvarchar(60)		NULL,
	[encryption_type]					int					NULL,
	encryption_type_desc				nvarchar(64)		NULL,
	encryption_algorithm_name			nvarchar(128)		NULL,
	column_encryption_key_id			int					NULL,
	column_encryption_key_database_name	nvarchar(128)		NULL,
	is_hidden							bit					NULL,
	is_masked							bit				NOT	NULL,
	graph_type							int					NULL,
	graph_type_desc						nvarchar(60)		NULL,
	is_data_deletion_filter_column		bit					NULL, -- Added: SQL Server 2022
	ledger_view_column_type				int					NULL, -- Added: SQL Server 2022
	ledger_view_column_type_desc		nvarchar(60)		NULL, -- Added: SQL Server 2022
	is_dropped_ledger_column			bit					NULL, -- Added: SQL Server 2022

	PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
	CONSTRAINT CPK__columns__ColumnID PRIMARY KEY CLUSTERED (_ColumnID) WITH (DATA_COMPRESSION = PAGE),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._columns_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO

CREATE NONCLUSTERED INDEX IX__columns__DatabaseID__ObjectID ON dbo._columns (_DatabaseID, _ObjectID);
GO

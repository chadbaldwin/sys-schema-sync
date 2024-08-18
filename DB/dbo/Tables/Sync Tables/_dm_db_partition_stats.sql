CREATE TABLE dbo._dm_db_partition_stats (
	_DatabaseID							int			NOT	NULL CONSTRAINT FK__dm_db_partition_stats__DatabaseID	REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID							int			NOT	NULL CONSTRAINT FK__dm_db_partition_stats__ObjectID		REFERENCES dbo.[Object]		(ObjectID),
	_IndexID							int			NOT	NULL CONSTRAINT FK__dm_db_partition_stats__IndexID		REFERENCES dbo.[Index]		(IndexID),
	_InsertDate							datetime2	NOT	NULL CONSTRAINT DF__dm_db_partition_stats__InsertDate	DEFAULT (SYSUTCDATETIME()),
	_ModifyDate							datetime2	NOT	NULL CONSTRAINT DF__dm_db_partition_stats__ModifyDate	DEFAULT (SYSUTCDATETIME()),
	_RowHash							binary(32)	NOT	NULL,
	--
	[partition_id]						bigint			NULL,
	[object_id]							int			NOT	NULL,
	index_id							int			NOT	NULL,
	partition_number					int			NOT	NULL,
	in_row_data_page_count				bigint			NULL,
	in_row_used_page_count				bigint			NULL,
	in_row_reserved_page_count			bigint			NULL,
	lob_used_page_count					bigint			NULL,
	lob_reserved_page_count				bigint			NULL,
	row_overflow_used_page_count		bigint			NULL,
	row_overflow_reserved_page_count	bigint			NULL,
	used_page_count						bigint			NULL,
	reserved_page_count					bigint			NULL,
	row_count							bigint			NULL,

	INDEX CIX__dm_db_partition_stats__IndexID_partition_number UNIQUE CLUSTERED (_IndexID, partition_number),
);
GO

CREATE NONCLUSTERED INDEX IX__dm_db_partition_stats__DatabaseID ON dbo._dm_db_partition_stats (_DatabaseID) INCLUDE (_ObjectID, partition_number);
GO

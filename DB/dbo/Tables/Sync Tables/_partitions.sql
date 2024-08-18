CREATE TABLE dbo._partitions (
	_DatabaseID				int			NOT	NULL CONSTRAINT FK__partitions__DatabaseID	REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID				int			NOT	NULL CONSTRAINT FK__partitions__ObjectID	REFERENCES dbo.[Object]		(ObjectID),
	_IndexID				int			NOT	NULL CONSTRAINT FK__partitions__IndexID		REFERENCES dbo.[Index]		(IndexID),
	_InsertDate				datetime2	NOT	NULL CONSTRAINT DF__partitions__InsertDate	DEFAULT (SYSUTCDATETIME()),
	_ModifyDate				datetime2	NOT	NULL CONSTRAINT DF__partitions__ModifyDate	DEFAULT (SYSUTCDATETIME()),
	_RowHash				binary(32)	NOT	NULL,
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

	INDEX CIX__partitions__IndexID_partition_number UNIQUE CLUSTERED (_IndexID, partition_number),
);
GO

CREATE NONCLUSTERED INDEX IX__partitions__DatabaseID ON dbo._partitions (_DatabaseID) INCLUDE (_ObjectID, partition_number);
GO

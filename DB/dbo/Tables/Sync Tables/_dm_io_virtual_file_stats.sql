CREATE TABLE dbo._dm_io_virtual_file_stats (
	_DatabaseID						int				NOT	NULL CONSTRAINT FK__dm_io_virtual_file_stats__DatabaseID REFERENCES dbo.[Database] (DatabaseID),
	_CollectionDate					datetime2		NOT	NULL,
	--
	database_id						smallint		NOT	NULL,
	[file_id]						smallint		NOT	NULL,
	sample_ms						bigint			NOT	NULL,
	num_of_reads					bigint			NOT	NULL,
	num_of_bytes_read				bigint			NOT	NULL,
	io_stall_read_ms				bigint			NOT	NULL,
	io_stall_queued_read_ms			bigint			NOT	NULL,
	num_of_writes					bigint			NOT	NULL,
	num_of_bytes_written			bigint			NOT	NULL,
	io_stall_write_ms				bigint			NOT	NULL,
	io_stall_queued_write_ms		bigint			NOT	NULL,
	io_stall						bigint			NOT	NULL,
	size_on_disk_bytes				bigint			NOT	NULL,
	file_handle						varbinary(8)	NOT	NULL,
	num_of_pushed_reads				bigint				NULL, -- Added: SQL Server 2022 - Deviation: NOT NULL
	num_of_pushed_bytes_returned	bigint				NULL, -- Added: SQL Server 2022 - Deviation: NOT NULL

	INDEX CIX__dm_io_virtual_file_stats__DatabaseID_file_id UNIQUE CLUSTERED (_DatabaseID, [file_id]),
);
GO

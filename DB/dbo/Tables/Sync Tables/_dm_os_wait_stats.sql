CREATE TABLE dbo._dm_os_wait_stats (
	_InstanceID			int				NOT	NULL CONSTRAINT FK__dm_os_wait_stats__InstanceID REFERENCES dbo.[Instance] (InstanceID),
	_InsertDate			datetime2		NOT	NULL CONSTRAINT DF__dm_os_wait_stats__InsertDate DEFAULT (SYSUTCDATETIME()),
	_ModifyDate			datetime2		NOT	NULL CONSTRAINT DF__dm_os_wait_stats__ModifyDate DEFAULT (SYSUTCDATETIME()),
	--
	wait_type			nvarchar(60)	NOT	NULL,
	waiting_tasks_count	bigint			NOT	NULL,
	wait_time_ms		bigint			NOT	NULL,
	max_wait_time_ms	bigint			NOT	NULL,
	signal_wait_time_ms	bigint			NOT	NULL,

	INDEX CIX__dm_os_wait_stats__InstanceID_wait_type CLUSTERED (_InstanceID, wait_type),
);
GO

CREATE TABLE dbo._database_query_store_options (
	_DatabaseID									int				NOT	NULL CONSTRAINT FK__database_query_store_options__DatabaseID REFERENCES dbo.[Database] (DatabaseID),
	_CollectionDate								datetime2		NOT	NULL,
	--
	[desired_state]								smallint		NOT	NULL,
	desired_state_desc							nvarchar(60)		NULL,
	actual_state								smallint		NOT	NULL,
	actual_state_desc							nvarchar(60)		NULL,
	readonly_reason								int					NULL,
	current_storage_size_mb						bigint				NULL,
	[flush_interval_seconds]					bigint				NULL,
	[interval_length_minutes]					bigint				NULL,
	[max_storage_size_mb]						bigint				NULL,
	stale_query_threshold_days					bigint				NULL,
	[max_plans_per_query]						bigint				NULL,
	[query_capture_mode]						smallint		NOT	NULL,
	query_capture_mode_desc						nvarchar(60)		NULL,
	capture_policy_execution_count				int					NULL, -- Added: SQL Server 2019
	capture_policy_total_compile_cpu_time_ms	bigint				NULL, -- Added: SQL Server 2019
	capture_policy_total_execution_cpu_time_ms	bigint				NULL, -- Added: SQL Server 2019
	capture_policy_stale_threshold_hours		int					NULL, -- Added: SQL Server 2019
	[size_based_cleanup_mode]					smallint		NOT	NULL,
	size_based_cleanup_mode_desc				nvarchar(60)		NULL,
	wait_stats_capture_mode						smallint		NOT	NULL,
	wait_stats_capture_mode_desc				nvarchar(60)		NULL,
	actual_state_additional_info				nvarchar(4000)		NULL,

	INDEX CIX__database_query_store_options__DatabaseID UNIQUE CLUSTERED (_DatabaseID),
);
GO

﻿CREATE TABLE dbo._dm_os_sys_info (
	_InstanceID						int				NOT	NULL CONSTRAINT FK__dm_os_sys_info__InstanceID REFERENCES dbo.[Instance] (InstanceID),
	_CollectionDate					datetime2		NOT	NULL,
	--
	cpu_ticks						bigint			NOT	NULL,
	ms_ticks						bigint			NOT	NULL,
	cpu_count						int				NOT	NULL,
	hyperthread_ratio				int				NOT	NULL,
	physical_memory_kb				bigint			NOT	NULL,
	virtual_memory_kb				bigint			NOT	NULL,
	committed_kb					bigint			NOT	NULL,
	committed_target_kb				bigint			NOT	NULL,
	visible_target_kb				bigint			NOT	NULL,
	stack_size_in_bytes				int				NOT	NULL,
	os_quantum						bigint			NOT	NULL,
	os_error_mode					int				NOT	NULL,
	os_priority_class				int					NULL,
	max_workers_count				int				NOT	NULL,
	scheduler_count					int				NOT	NULL,
	scheduler_total_count			int				NOT	NULL,
	deadlock_monitor_serial_number	int				NOT	NULL,
	sqlserver_start_time_ms_ticks	bigint			NOT	NULL,
	sqlserver_start_time			datetime		NOT	NULL,
	affinity_type					int				NOT	NULL,
	affinity_type_desc				nvarchar(60)	NOT	NULL,
	process_kernel_time_ms			bigint			NOT	NULL,
	process_user_time_ms			bigint			NOT	NULL,
	time_source						int				NOT	NULL,
	time_source_desc				nvarchar(60)	NOT	NULL,
	virtual_machine_type			int				NOT	NULL,
	virtual_machine_type_desc		nvarchar(60)	NOT	NULL,
	softnuma_configuration			int				NOT	NULL,
	softnuma_configuration_desc		nvarchar(60)	NOT	NULL,
	process_physical_affinity		nvarchar(3072)	NOT	NULL,
	sql_memory_model				int				NOT	NULL,
	sql_memory_model_desc			nvarchar(60)	NOT	NULL,
	socket_count					int				NOT	NULL,
	cores_per_socket				int				NOT	NULL,
	numa_node_count					int				NOT	NULL,
	container_type					int				NOT	NULL,
	container_type_desc				nvarchar(60)	NOT	NULL,

	INDEX CIX__dm_os_sys_info__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

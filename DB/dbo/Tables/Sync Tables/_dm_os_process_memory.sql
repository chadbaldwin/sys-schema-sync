CREATE TABLE dbo._dm_os_process_memory (
	_InstanceID							int			NOT	NULL CONSTRAINT FK__dm_os_process_memory__InstanceID REFERENCES dbo.[Instance] (InstanceID),
	_CollectionDate						datetime2	NOT	NULL,
	--
	physical_memory_in_use_kb			bigint		NOT	NULL,
	large_page_allocations_kb			bigint		NOT	NULL,
	locked_page_allocations_kb			bigint		NOT	NULL,
	total_virtual_address_space_kb		bigint		NOT	NULL,
	virtual_address_space_reserved_kb	bigint		NOT	NULL,
	virtual_address_space_committed_kb	bigint		NOT	NULL,
	virtual_address_space_available_kb	bigint		NOT	NULL,
	page_fault_count					bigint		NOT	NULL,
	memory_utilization_percentage		int			NOT	NULL,
	available_commit_limit_kb			bigint		NOT	NULL,
	process_physical_memory_low			bit			NOT	NULL,
	process_virtual_memory_low			bit			NOT	NULL,

	INDEX CIX__dm_os_process_memory__InstanceID UNIQUE CLUSTERED (_InstanceID),
);
GO

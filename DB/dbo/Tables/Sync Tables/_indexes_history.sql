﻿CREATE TABLE dbo._indexes_history (
	_DatabaseID						int				NOT	NULL,
	_ObjectID						int				NOT	NULL,
	_IndexID						int				NOT	NULL,
	_InsertDate						datetime2		NOT	NULL,
	_ModifyDate						datetime2		NOT	NULL,
	_RowHash						binary(32)		NOT	NULL,
	_ValidFrom						datetime2		NOT	NULL,
	_ValidTo						datetime2		NOT	NULL,
	--
	[object_id]						int				NOT	NULL,
	[name]							nvarchar(128)		NULL,
	index_id						int				NOT	NULL,
	[type]							tinyint			NOT	NULL,
	[type_desc]						nvarchar(60)		NULL,
	is_unique						bit					NULL,
	data_space_id					int					NULL,
	[ignore_dup_key]				bit					NULL,
	is_primary_key					bit					NULL,
	is_unique_constraint			bit					NULL,
	fill_factor						tinyint			NOT	NULL,
	is_padded						bit					NULL,
	is_disabled						bit					NULL,
	is_hypothetical					bit					NULL,
	is_ignored_in_optimization		bit					NULL,
	[allow_row_locks]				bit					NULL,
	[allow_page_locks]				bit					NULL,
	has_filter						bit					NULL,
	filter_definition				nvarchar(MAX)		NULL,
	[compression_delay]				int					NULL,
	suppress_dup_key_messages		bit					NULL,
	auto_created					bit					NULL,
	[optimize_for_sequential_key]	bit					NULL, -- Added: SQL Server 2019

	INDEX CIX__indexes_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);

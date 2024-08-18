﻿CREATE TYPE import.import__master_files AS TABLE (
	_DatabaseName				nvarchar(128)		NOT	NULL,
	_RowHash					binary(32)			NOT	NULL,
	--
	database_id					int					NOT	NULL,
	[file_id]					int					NOT	NULL,
	file_guid					uniqueidentifier		NULL,
	[type]						tinyint				NOT	NULL,
	[type_desc]					nvarchar(60)			NULL,
	data_space_id				int					NOT	NULL,
	[name]						nvarchar(128)			NULL,
	physical_name				nvarchar(260)		NOT	NULL,
	[state]						tinyint					NULL,
	state_desc					nvarchar(60)			NULL,
	size						int					NOT	NULL,
	max_size					int					NOT	NULL,
	growth						int					NOT	NULL,
	is_media_read_only			bit					NOT	NULL,
	is_read_only				bit					NOT	NULL,
	is_sparse					bit					NOT	NULL,
	is_percent_growth			bit					NOT	NULL,
	is_name_reserved			bit					NOT	NULL,
	is_persistent_log_buffer	bit					NOT	NULL,
	create_lsn					numeric(25,0)			NULL,
	drop_lsn					numeric(25,0)			NULL,
	read_only_lsn				numeric(25,0)			NULL,
	read_write_lsn				numeric(25,0)			NULL,
	differential_base_lsn		numeric(25,0)			NULL,
	differential_base_guid		uniqueidentifier		NULL,
	differential_base_time		datetime				NULL,
	redo_start_lsn				numeric(25,0)			NULL,
	redo_start_fork_guid		uniqueidentifier		NULL,
	redo_target_lsn				numeric(25,0)			NULL,
	redo_target_fork_guid		uniqueidentifier		NULL,
	backup_lsn					numeric(25,0)			NULL,
	credential_id				int						NULL,

	INDEX CIX UNIQUE CLUSTERED (database_id, [file_id])
);

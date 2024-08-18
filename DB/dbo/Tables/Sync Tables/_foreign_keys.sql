﻿CREATE TABLE dbo._foreign_keys (
	_DatabaseID						int				NOT	NULL CONSTRAINT FK__foreign_keys__DatabaseID			REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID						int				NOT	NULL CONSTRAINT FK__foreign_keys__ObjectID				REFERENCES dbo.[Object]		(ObjectID),
	_ParentObjectID					int				NOT	NULL CONSTRAINT FK__foreign_keys__ParentObjectID		REFERENCES dbo.[Object]		(ObjectID),
	_ReferencedObjectID				int				NOT	NULL CONSTRAINT FK__foreign_keys__ReferencedObjectID	REFERENCES dbo.[Object]		(ObjectID),
	_ReferencedIndexID				int				NOT	NULL CONSTRAINT FK__foreign_keys__ReferencedIndexID		REFERENCES dbo.[Index]		(IndexID),
	_InsertDate						datetime2		NOT	NULL CONSTRAINT DF__foreign_keys__InsertDate			DEFAULT (SYSUTCDATETIME()),
	_ModifyDate						datetime2		NOT	NULL CONSTRAINT DF__foreign_keys__ModifyDate			DEFAULT (SYSUTCDATETIME()),
	_RowHash						binary(32)		NOT	NULL,
	_ValidFrom						datetime2		GENERATED ALWAYS AS ROW START	NOT	NULL,
	_ValidTo						datetime2		GENERATED ALWAYS AS ROW END		NOT	NULL,
	--
	[name]							nvarchar(128)	NOT	NULL,
	[object_id]						int				NOT	NULL,
	principal_id					int					NULL,
	[schema_id]						int				NOT	NULL,
	parent_object_id				int				NOT	NULL,
	[type]							char(2)				NULL,
	[type_desc]						nvarchar(60)		NULL,
	create_date						datetime		NOT	NULL,
	modify_date						datetime		NOT	NULL,
	is_ms_shipped					bit				NOT	NULL,
	is_published					bit				NOT	NULL,
	is_schema_published				bit				NOT	NULL,
	referenced_object_id			int					NULL,
	key_index_id					int					NULL,
	is_disabled						bit				NOT	NULL,
	is_not_for_replication			bit				NOT	NULL,
	is_not_trusted					bit				NOT	NULL,
	delete_referential_action		tinyint				NULL,
	delete_referential_action_desc	nvarchar(60)		NULL,
	update_referential_action		tinyint				NULL,
	update_referential_action_desc	nvarchar(60)		NULL,
	is_system_named					bit				NOT	NULL,

	PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
	CONSTRAINT CPK__foreign_keys__ObjectID PRIMARY KEY CLUSTERED (_ObjectID),
	INDEX IX__foreign_keys__DatabaseID NONCLUSTERED (_DatabaseID),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._foreign_keys_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
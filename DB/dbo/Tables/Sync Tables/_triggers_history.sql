CREATE TABLE dbo._triggers_history (
	_DatabaseID				int				NOT	NULL,
	_ObjectID				int				NOT	NULL,
	_ParentObjectID			int					NULL,
	_InsertDate				datetime2		NOT	NULL,
	_ModifyDate				datetime2		NOT	NULL,
	_RowHash				binary(32)		NOT	NULL,
	_ValidFrom				datetime2		NOT	NULL,
	_ValidTo				datetime2		NOT	NULL,
	--
	[name]					nvarchar(128)	NOT	NULL,
	[object_id]				int				NOT	NULL,
	parent_class			tinyint			NOT	NULL,
	parent_class_desc		nvarchar(60)		NULL,
	parent_id				int				NOT	NULL,
	[type]					char(2)			NOT	NULL,
	[type_desc]				nvarchar(60)		NULL,
	create_date				datetime		NOT	NULL,
	modify_date				datetime		NOT	NULL,
	is_ms_shipped			bit				NOT	NULL,
	is_disabled				bit				NOT	NULL,
	is_not_for_replication	bit				NOT	NULL,
	is_instead_of_trigger	bit				NOT	NULL,

	INDEX CIX__triggers_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

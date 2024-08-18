CREATE TABLE dbo._foreign_key_columns (
	_DatabaseID				int			NOT	NULL CONSTRAINT FK__foreign_key_columns__DatabaseID			REFERENCES dbo.[Database]	(DatabaseID),
	_ObjectID				int			NOT	NULL CONSTRAINT FK__foreign_key_columns__ObjectID			REFERENCES dbo.[Object]		(ObjectID),
	_ParentObjectID			int			NOT	NULL CONSTRAINT FK__foreign_key_columns__ParentObjectID		REFERENCES dbo.[Object]		(ObjectID),
	_ParentColumnID			int			NOT	NULL CONSTRAINT FK__foreign_key_columns__ParentColumnID		REFERENCES dbo.[Column]		(ColumnID),
	_ReferencedObjectID		int			NOT	NULL CONSTRAINT FK__foreign_key_columns__ReferencedObjectID	REFERENCES dbo.[Object]		(ObjectID),
	_ReferencedColumnID		int			NOT	NULL CONSTRAINT FK__foreign_key_columns__ReferencedColumnID	REFERENCES dbo.[Column]		(ColumnID),
	_InsertDate				datetime2	NOT	NULL CONSTRAINT DF__foreign_key_columns__InsertDate			DEFAULT (SYSUTCDATETIME()),
	_ModifyDate				datetime2	NOT	NULL CONSTRAINT DF__foreign_key_columns__ModifyDate			DEFAULT (SYSUTCDATETIME()),
	_RowHash				binary(32)	NOT	NULL,
	--
	constraint_object_id	int	NOT	NULL,
	constraint_column_id	int	NOT	NULL,
	parent_object_id		int	NOT	NULL,
	parent_column_id		int	NOT	NULL,
	referenced_object_id	int	NOT	NULL,
	referenced_column_id	int	NOT	NULL,

	INDEX CIX__foreign_key_columns__ObjectID__ParentObjectID__ReferencedObjectID CLUSTERED (_ObjectID, _ParentObjectID, _ReferencedObjectID),
	INDEX IX__foreign_key_columns__DatabaseID NONCLUSTERED (_DatabaseID),
);
GO

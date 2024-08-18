CREATE TABLE dbo.[Column] (
	DatabaseID		int				NOT	NULL CONSTRAINT FK_Column_DatabaseID	REFERENCES dbo.[Database] (DatabaseID),
	ObjectID		int				NOT	NULL CONSTRAINT FK_Column_ObjectID		REFERENCES dbo.[Object]   (ObjectID),
	ColumnID		int				NOT	NULL IDENTITY,
	ColumnName		nvarchar(128)	NOT	NULL,
	IsDeleted		bit				NOT	NULL CONSTRAINT DF_Column_IsDeleted		DEFAULT (0),
	InsertDate		datetime2		NOT	NULL CONSTRAINT DF_Column_InsertDate	DEFAULT (SYSUTCDATETIME()),
	DeleteDate		datetime2			NULL,

	INDEX CIX_Column_DatabaseID_ColumnID UNIQUE CLUSTERED (DatabaseID, ColumnID),
	CONSTRAINT PK_Column_ColumnID PRIMARY KEY NONCLUSTERED (ColumnID),
);
GO

CREATE NONCLUSTERED INDEX IX_Column_DatabaseID_ObjectID_ColumnName
	ON dbo.[Column] (DatabaseID, ObjectID, ColumnName)
GO

CREATE NONCLUSTERED INDEX IX_Column_DatabaseID_IsDeleted
	ON dbo.[Column] (DatabaseID, IsDeleted)
GO

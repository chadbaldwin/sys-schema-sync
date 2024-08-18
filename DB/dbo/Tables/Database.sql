CREATE TABLE dbo.[Database] (
	DatabaseID		int				NOT	NULL IDENTITY
											 CONSTRAINT CPK_Database_DatabaseID	PRIMARY KEY CLUSTERED,
	InstanceID		int				NOT	NULL CONSTRAINT FK_Database_InstanceID	REFERENCES dbo.Instance (InstanceID),
	DatabaseName	nvarchar(128)	NOT	NULL,
	InsertDate		datetime2		NOT	NULL CONSTRAINT DF_Database_InsertDate	DEFAULT (SYSUTCDATETIME()),
	IsEnabled		bit				NOT	NULL CONSTRAINT DF_Database_IsEnabled	DEFAULT (1),
);

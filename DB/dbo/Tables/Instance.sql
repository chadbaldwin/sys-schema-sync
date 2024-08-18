CREATE TABLE dbo.[Instance] (
	InstanceID		int				NOT NULL IDENTITY
											 CONSTRAINT CPK_Instance_InstanceID PRIMARY KEY CLUSTERED,
	InstanceName	nvarchar(257)	NOT NULL,
	InsertDate      datetime2		NOT NULL CONSTRAINT DF_Instance_InsertDate  DEFAULT (SYSUTCDATETIME()),
	IsEnabled		bit				NOT NULL CONSTRAINT DF_Instance_IsEnabled   DEFAULT (1),
);
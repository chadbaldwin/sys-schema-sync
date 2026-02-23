CREATE TABLE dbo._dm_server_services_history (
    _InstanceID                         int               NOT NULL,
    --
    _InsertDate                         datetime2         NOT NULL,
    _ModifyDate                         datetime2         NOT NULL,
    _RowHash                            binary(32)        NOT NULL,
    _ValidFrom                          datetime2         NOT NULL,
    _ValidTo                            datetime2         NOT NULL,
    --
    servicename                         nvarchar(256)     NOT NULL,
    startup_type                        int                   NULL,
    startup_type_desc                   nvarchar(256)     NOT NULL,
    [status]                            int                   NULL,
    status_desc                         nvarchar(256)     NOT NULL,
    process_id                          int                   NULL,
    last_startup_time                   datetimeoffset(7)     NULL,
    service_account                     nvarchar(256)     NOT NULL,
    [filename]                          nvarchar(256)     NOT NULL,
    is_clustered                        nvarchar(1)       NOT NULL,
    cluster_nodename                    nvarchar(256)         NULL,
    instant_file_initialization_enabled nvarchar(1)       NOT NULL,

    INDEX CIX__dm_server_services_history__ValidTo__ValidFrom CLUSTERED (_ValidTo, _ValidFrom) WITH (DATA_COMPRESSION = PAGE),
);
GO

CREATE TABLE dbo._dm_server_services (
    _InstanceID                         int               NOT NULL CONSTRAINT FK__dm_server_services__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    --
    _InsertDate                         datetime2         NOT NULL CONSTRAINT DF__dm_server_services__InsertDate DEFAULT (SYSUTCDATETIME()),
    _ModifyDate                         datetime2         NOT NULL CONSTRAINT DF__dm_server_services__ModifyDate DEFAULT (SYSUTCDATETIME()),
    _RowHash                            binary(32)        NOT NULL,
    _ValidFrom                          datetime2         GENERATED ALWAYS AS ROW START NOT NULL,
    _ValidTo                            datetime2         GENERATED ALWAYS AS ROW END   NOT NULL,
    --
    servicename                         nvarchar(256)     NOT NULL,
    startup_type                        int                   NULL,
    startup_type_desc                   nvarchar(256)     NOT NULL,
    [status]                            int                   NULL,
    status_desc                         nvarchar(256)     NOT NULL,
    process_id                          int                   NULL,
    last_startup_time                   datetimeoffset(7)     NULL,
    service_account                     nvarchar(256)     NOT NULL,
    [filename]                          nvarchar(256)     NOT NULL,
    is_clustered                        nvarchar(1)       NOT NULL,
    cluster_nodename                    nvarchar(256)         NULL,
    instant_file_initialization_enabled nvarchar(1)       NOT NULL,

    PERIOD FOR SYSTEM_TIME (_ValidFrom, _ValidTo),
    CONSTRAINT CPK__dm_server_services__InstanceID_servicename PRIMARY KEY CLUSTERED (_InstanceID, servicename),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo._dm_server_services_history, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 6 MONTH));
GO
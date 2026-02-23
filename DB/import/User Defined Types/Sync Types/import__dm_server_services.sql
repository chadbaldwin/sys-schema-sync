CREATE TYPE import.import__dm_server_services AS TABLE (
    _RowHash                            binary(32)        NOT NULL,
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

    INDEX CIX UNIQUE CLUSTERED (servicename)
);
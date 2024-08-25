CREATE TABLE dbo._dm_os_volume_stats (
    _DatabaseID                 int             NOT NULL CONSTRAINT FK__dm_os_volume_stats__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate             datetime2       NOT NULL,
    --
    database_id                 int             NOT NULL,
    [file_id]                   int             NOT NULL,
    volume_mount_point          nvarchar(256)       NULL,
    volume_id                   nvarchar(256)       NULL,
    logical_volume_name         nvarchar(256)       NULL,
    file_system_type            nvarchar(256)       NULL,
    total_bytes                 bigint          NOT NULL,
    available_bytes             bigint          NOT NULL,
    supports_compression        tinyint             NULL,
    supports_alternate_streams  tinyint             NULL,
    supports_sparse_files       tinyint             NULL,
    is_read_only                tinyint             NULL,
    is_compressed               tinyint             NULL,
    incurs_seek_penalty         tinyint             NULL, -- Added: SQL Server 2019

    INDEX CIX__dm_os_volume_stats__DatabaseID_file_id UNIQUE CLUSTERED (_DatabaseID, [file_id]),
);
GO

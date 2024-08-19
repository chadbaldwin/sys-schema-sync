CREATE TABLE dbo._filegroups (
    _DatabaseID             int                 NOT NULL CONSTRAINT FK__filegroups__DatabaseID REFERENCES dbo.[Database] (DatabaseID),
    _CollectionDate         datetime2           NOT NULL,
    --
    [name]                  nvarchar(128)       NOT NULL,
    data_space_id           int                 NOT NULL,
    [type]                  char(2)             NOT NULL,
    [type_desc]             nvarchar(60)            NULL,
    is_default              bit                     NULL,
    is_system               bit                     NULL,
    filegroup_guid          uniqueidentifier        NULL,
    log_filegroup_id        int                     NULL,
    is_read_only            bit                     NULL,
    is_autogrow_all_files   bit                     NULL,

    INDEX CIX__filegroups__DatabaseID_data_space_id UNIQUE CLUSTERED (_DatabaseID, data_space_id),
);
GO

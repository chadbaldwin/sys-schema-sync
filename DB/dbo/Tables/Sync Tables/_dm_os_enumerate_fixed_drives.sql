CREATE TABLE dbo._dm_os_enumerate_fixed_drives (
    _InstanceID         int           NOT NULL CONSTRAINT FK__dm_os_enumerate_fixed_drives__InstanceID REFERENCES dbo.[Instance] (_InstanceID), -- Covered by CIX
    _CollectionDate     datetime2     NOT NULL,
    --
    fixed_drive_path    nvarchar(256)     NULL,
    drive_type          int           NOT NULL,
    drive_type_desc     nvarchar(256)     NULL,
    free_space_in_bytes bigint        NOT NULL,

    INDEX CIX__dm_os_enumerate_fixed_drives__InstanceID_fixed_drive_path UNIQUE CLUSTERED (_InstanceID, fixed_drive_path),
);
GO
CREATE TABLE dbo._restorehistory (
    _InstanceID                 int             NOT NULL CONSTRAINT FK__restorehistory__InstanceID REFERENCES dbo.[Instance] (_InstanceID),
    _CollectionDate             datetime2       NOT NULL,
    --
    restore_history_id          int             NOT NULL,
    restore_date                datetime            NULL,
    destination_database_name   nvarchar(128)       NULL,
    [user_name]                 nvarchar(128)       NULL,
    backup_set_id               int             NOT NULL,
    restore_type                char(1)             NULL,
    [replace]                   bit                 NULL,
    [recovery]                  bit                 NULL,
    [restart]                   bit                 NULL,
    stop_at                     datetime            NULL,
    device_count                tinyint             NULL,
    stop_at_mark_name           nvarchar(128)       NULL,
    stop_before                 bit                 NULL,

    INDEX CIX__restorehistory__InstanceID_restore_history_id UNIQUE CLUSTERED (_InstanceID, restore_history_id),
);
GO

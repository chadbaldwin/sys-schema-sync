CREATE TABLE dbo._database_automatic_tuning_options (
    _DatabaseID         int             NOT NULL CONSTRAINT FK__database_automatic_tuning_options__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate     datetime2       NOT NULL,
    --
    [name]              nvarchar(128)       NULL,
    [desired_state]     smallint            NULL,
    desired_state_desc  nvarchar(60)        NULL,
    actual_state        smallint            NULL,
    actual_state_desc   nvarchar(60)        NULL,
    reason              smallint            NULL,
    reason_desc         nvarchar(60)        NULL,

    INDEX CIX__database_automatic_tuning_options__DatabaseID CLUSTERED (_DatabaseID),
);
GO

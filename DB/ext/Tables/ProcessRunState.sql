CREATE TABLE ext.ProcessRunState (
    ID                        int           NOT NULL,
    ProcessName               nvarchar(200) NOT NULL,
    ModifyDateUTC             datetime2     NOT NULL,
    LastChangeTrackingVersion bigint            NULL,
);
GO
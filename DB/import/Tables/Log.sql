CREATE TABLE import.[Log] (
    LogID       bigint          NOT NULL IDENTITY,
    InsertDate  datetime2       NOT NULL CONSTRAINT DF_Log_InsertDate DEFAULT SYSUTCDATETIME(),
    _InstanceID int                 NULL,
    _DatabaseID int                 NULL,
    [Message]   nvarchar(2047)  NOT NULL,
    TimeStart   datetime2           NULL,
    [RowCount]  bigint              NULL,
    String1     nvarchar(1000)      NULL,
    String2     nvarchar(1000)      NULL,
    String3     nvarchar(1000)      NULL,
);
GO
-- Cluster by InsertDate first since that will be the most common query
-- Then cluster by LogID to make ordering determinisitc
CREATE UNIQUE CLUSTERED INDEX CIX_Log_InsertDate_LogID
    ON import.[Log] (InsertDate, LogID)
    WITH (DATA_COMPRESSION = PAGE);
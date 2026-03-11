CREATE TABLE import.[Log] (
    LogID         bigint              NOT NULL IDENTITY,
    InsertDate    datetime2           NOT NULL CONSTRAINT DF_Log_InsertDate DEFAULT SYSUTCDATETIME(),
    ExecutionID   uniqueidentifier    NOT NULL,
    EventType     varchar(5)          NOT NULL,
    ActionName    nvarchar(100)       NOT NULL,
    Scope1        nvarchar(2047)      NULL,
    Scope2        nvarchar(2047)      NULL,
    DetailMessage nvarchar(2047)      NULL,
    StartTime     datetime2           NULL,
    AffectedRowCount bigint           NULL,
    NestLevel     int                 NOT NULL,
    _InstanceID   int                 NULL,
    _DatabaseID   int                 NULL,
    CONSTRAINT CHK_Log_EventType CHECK (EventType IN ('Start', 'Done', 'Error')),
);
GO
-- Cluster by InsertDate first since that will be the most common query
-- Then cluster by LogID to make ordering determinisitc
CREATE UNIQUE CLUSTERED INDEX CIX_Log_InsertDate_LogID
    ON import.[Log] (InsertDate, LogID)
    WITH (DATA_COMPRESSION = PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON);
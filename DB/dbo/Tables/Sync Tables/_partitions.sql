CREATE TABLE dbo._partitions (
    _DatabaseID             int          NOT NULL CONSTRAINT FK__partitions__DatabaseID  REFERENCES dbo.[Database] (_DatabaseID) INDEX IX__partitions__DatabaseID,
    _ObjectID               bigint       NOT NULL CONSTRAINT FK__partitions__ObjectID    REFERENCES dbo.[Object]   (_ObjectID)   INDEX IX__partitions__ObjectID,
    _IndexID                bigint       NOT NULL CONSTRAINT FK__partitions__IndexID     REFERENCES dbo.[Index]    (_IndexID)    INDEX IX__partitions__IndexID,
    --
    _InsertDate             datetime2    NOT NULL CONSTRAINT DF__partitions__InsertDate  DEFAULT (SYSUTCDATETIME()),
    _ModifyDate             datetime2    NOT NULL CONSTRAINT DF__partitions__ModifyDate  DEFAULT (SYSUTCDATETIME()),
    _RowHash                binary(32)   NOT NULL,
    --
    [partition_id]          bigint       NOT NULL,
    [object_id]             int          NOT NULL,
    index_id                int          NOT NULL,
    partition_number        int          NOT NULL,
    hobt_id                 bigint       NOT NULL,
    [rows]                  bigint           NULL,
    filestream_filegroup_id smallint     NOT NULL,
    [data_compression]      tinyint      NOT NULL,
    data_compression_desc   nvarchar(60)     NULL,
    xml_compression         bit              NULL, -- Added: SQL Server 2022
    xml_compression_desc    varchar(3)       NULL, -- Added: SQL Server 2022

    CONSTRAINT CUQ__partitions__DatabaseID__IndexID_partition_number UNIQUE CLUSTERED (_DatabaseID, _IndexID, partition_number),
    CONSTRAINT UQ__partitions__DatabaseID_partition_id UNIQUE (_DatabaseID, [partition_id]),
);
GO
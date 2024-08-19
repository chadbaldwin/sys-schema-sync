CREATE PROCEDURE import.usp_import__partitions (
    @DatabaseID int,
    @Dataset    import.import__partitions READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
    SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, ObjectID, IndexID, ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._partitions';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._partitions x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (
            SELECT *
            FROM #Dataset d
                JOIN @output o ON o.ID = d.ID
            WHERE o.IndexID = x._IndexID
                AND x.partition_number = d.partition_number
        );
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate             = SYSUTCDATETIME()
        , x._RowHash                = d._RowHash
        --
        , x.[partition_id]          = d.[partition_id]
        , x.[object_id]             = d.[object_id]
        , x.index_id                = d.index_id
        , x.partition_number        = d.partition_number
        , x.hobt_id                 = d.hobt_id
        , x.[rows]                  = d.[rows]
        , x.filestream_filegroup_id = d.filestream_filegroup_id
        , x.[data_compression]      = d.[data_compression]
        , x.data_compression_desc   = d.data_compression_desc
        , x.xml_compression         = d.xml_compression
        , x.xml_compression_desc    = d.xml_compression_desc
    FROM dbo._partitions x
        JOIN @output y ON y.IndexID = x._IndexID
        JOIN #Dataset d ON d.ID = y.ID AND d.partition_number = x.partition_number
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._partitions (_DatabaseID, _ObjectID, _IndexID, _RowHash
        , [partition_id], [object_id], index_id, partition_number, hobt_id, [rows], filestream_filegroup_id, [data_compression], data_compression_desc, xml_compression, xml_compression_desc)
    SELECT @DatabaseID, y.ObjectID, y.IndexID, d._RowHash
        , d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.[rows], d.filestream_filegroup_id, d.[data_compression], d.data_compression_desc, d.xml_compression, d.xml_compression_desc
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._partitions x
            WHERE x._IndexID  = y.IndexID
                AND x.partition_number = d.partition_number
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

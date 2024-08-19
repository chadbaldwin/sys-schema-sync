CREATE PROCEDURE import.usp_import__dm_db_partition_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_partition_stats READONLY
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
    DECLARE @tableName nvarchar(128) = N'dbo._dm_db_partition_stats';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._dm_db_partition_stats x
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
    SET   x._ModifyDate                         = SYSUTCDATETIME()
        , x._RowHash                            = d._RowHash
        --
        , x.[partition_id]                      = d.[partition_id]
        , x.[object_id]                         = d.[object_id]
        , x.index_id                            = d.index_id
        , x.partition_number                    = d.partition_number
        , x.in_row_data_page_count              = d.in_row_data_page_count
        , x.in_row_used_page_count              = d.in_row_used_page_count
        , x.in_row_reserved_page_count          = d.in_row_reserved_page_count
        , x.lob_used_page_count                 = d.lob_used_page_count
        , x.lob_reserved_page_count             = d.lob_reserved_page_count
        , x.row_overflow_used_page_count        = d.row_overflow_used_page_count
        , x.row_overflow_reserved_page_count    = d.row_overflow_reserved_page_count
        , x.used_page_count                     = d.used_page_count
        , x.reserved_page_count                 = d.reserved_page_count
        , x.row_count                           = d.row_count
    FROM dbo._dm_db_partition_stats x
        JOIN @output y ON y.IndexID = x._IndexID
        JOIN #Dataset d ON d.ID = y.ID AND d.partition_number = x.partition_number
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._dm_db_partition_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash
        , [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
    SELECT @DatabaseID, y.ObjectID, y.IndexID, d._RowHash
        , d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._dm_db_partition_stats x
            WHERE x._IndexID  = y.IndexID
                AND x.partition_number = d.partition_number
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

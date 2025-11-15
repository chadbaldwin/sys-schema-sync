CREATE PROCEDURE import.usp_import__dm_db_partition_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_partition_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_partition_stats;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
    CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, partition_number);

    INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
    SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_partition_stats';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._dm_db_partition_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET x._ObjectID                        = d._ObjectID
          , x._ModifyDate                      = SYSUTCDATETIME()
          , x._RowHash                         = d._RowHash
          , x.[partition_id]                   = d.[partition_id]
          , x.[object_id]                      = d.[object_id]
          , x.index_id                         = d.index_id
          , x.in_row_data_page_count           = d.in_row_data_page_count
          , x.in_row_used_page_count           = d.in_row_used_page_count
          , x.in_row_reserved_page_count       = d.in_row_reserved_page_count
          , x.lob_used_page_count              = d.lob_used_page_count
          , x.lob_reserved_page_count          = d.lob_reserved_page_count
          , x.row_overflow_used_page_count     = d.row_overflow_used_page_count
          , x.row_overflow_reserved_page_count = d.row_overflow_reserved_page_count
          , x.used_page_count                  = d.used_page_count
          , x.reserved_page_count              = d.reserved_page_count
          , x.row_count                        = d.row_count
        FROM dbo._dm_db_partition_stats x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number
        WHERE x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._dm_db_partition_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_partition_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
CREATE PROCEDURE import.usp_import__dm_db_stats_properties (
    @DatabaseID int,
    @Dataset    import.import__dm_db_stats_properties READONLY
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

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._dm_db_stats_properties';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._dm_db_stats_properties x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._IndexID = x._IndexID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate              = SYSUTCDATETIME()
        , x._RowHash                 = d._RowHash
        --
        , x.[object_id]              = d.[object_id]
        , x.stats_id                 = d.stats_id
        , x.last_updated             = d.last_updated
        , x.[rows]                   = d.[rows]
        , x.rows_sampled             = d.rows_sampled
        , x.steps                    = d.steps
        , x.unfiltered_rows          = d.unfiltered_rows
        , x.modification_counter     = d.modification_counter
        , x.persisted_sample_percent = d.persisted_sample_percent
    FROM dbo._dm_db_stats_properties x
        JOIN @output y ON y._IndexID = x._IndexID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._dm_db_stats_properties (_DatabaseID, _ObjectID, _IndexID, _RowHash
        , [object_id], stats_id, last_updated, [rows], rows_sampled, steps, unfiltered_rows, modification_counter, persisted_sample_percent)
    SELECT @DatabaseID, y._ObjectID, y._IndexID, d._RowHash
        , d.[object_id], d.stats_id, d.last_updated, d.[rows], d.rows_sampled, d.steps, d.unfiltered_rows, d.modification_counter, d.persisted_sample_percent
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._dm_db_stats_properties x
            WHERE x._IndexID  = y._IndexID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO
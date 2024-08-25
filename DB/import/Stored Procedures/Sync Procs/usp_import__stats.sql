CREATE PROCEDURE import.usp_import__stats (
    @DatabaseID int,
    @Dataset    import.import__stats READONLY
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
    DECLARE @tableName nvarchar(128) = N'dbo._stats';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._stats x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._IndexID = x._IndexID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                     = SYSUTCDATETIME()
        , x._RowHash                        = d._RowHash
        --
        , x.[object_id]                     = d.[object_id]
        , x.[name]                          = d.[name]
        , x.stats_id                        = d.stats_id
        , x.auto_created                    = d.auto_created
        , x.user_created                    = d.user_created
        , x.no_recompute                    = d.no_recompute
        , x.has_filter                      = d.has_filter
        , x.filter_definition               = d.filter_definition
        , x.is_temporary                    = d.is_temporary
        , x.is_incremental                  = d.is_incremental
        , x.has_persisted_sample            = d.has_persisted_sample
        , x.stats_generation_method         = d.stats_generation_method
        , x.stats_generation_method_desc    = d.stats_generation_method_desc
        , x.auto_drop                       = d.auto_drop
    FROM dbo._stats x
        JOIN @output y ON y._IndexID = x._IndexID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._stats (_DatabaseID, _ObjectID, _IndexID, _RowHash
        , [object_id], [name], stats_id, auto_created, user_created, no_recompute, has_filter, filter_definition, is_temporary, is_incremental, has_persisted_sample, stats_generation_method, stats_generation_method_desc, auto_drop)
    SELECT @DatabaseID, y._ObjectID, y._IndexID, d._RowHash
        , d.[object_id], d.[name], d.stats_id, d.auto_created, d.user_created, d.no_recompute, d.has_filter, d.filter_definition, d.is_temporary, d.is_incremental, d.has_persisted_sample, d.stats_generation_method, d.stats_generation_method_desc, d.auto_drop
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._stats x
            WHERE x._IndexID  = y._IndexID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

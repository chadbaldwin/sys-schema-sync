CREATE PROCEDURE import.usp_import__stats (
    @DatabaseID int,
    @Dataset    import.import__stats READONLY,
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

    SELECT _DatabaseID = @DatabaseID
        , _ObjectID    = o._ObjectID
        , _IndexID     = o._IndexID
        , d._RowHash, d.[object_id], d.[name], d.stats_id, d.auto_created, d.user_created, d.no_recompute, d.has_filter, d.filter_definition, d.is_temporary, d.is_incremental, d.has_persisted_sample, d.stats_generation_method, d.stats_generation_method_desc, d.auto_drop, d.replica_role_id, d.replica_role_desc, d.replica_name
    INTO #tmp_Dataset
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID;

    CREATE INDEX IX ON #tmp_Dataset (_DatabaseID, _ObjectID);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._stats';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #tmp_Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET x._ObjectID                    = d._ObjectID
          , x._ModifyDate                  = SYSUTCDATETIME()
          , x._RowHash                     = d._RowHash
          , x.[object_id]                  = d.[object_id]
          , x.[name]                       = d.[name]
          , x.stats_id                     = d.stats_id
          , x.auto_created                 = d.auto_created
          , x.user_created                 = d.user_created
          , x.no_recompute                 = d.no_recompute
          , x.has_filter                   = d.has_filter
          , x.filter_definition            = d.filter_definition
          , x.is_temporary                 = d.is_temporary
          , x.is_incremental               = d.is_incremental
          , x.has_persisted_sample         = d.has_persisted_sample
          , x.stats_generation_method      = d.stats_generation_method
          , x.stats_generation_method_desc = d.stats_generation_method_desc
          , x.auto_drop                    = d.auto_drop
          , x.replica_role_id              = d.replica_role_id
          , x.replica_role_desc            = d.replica_role_desc
          , x.replica_name                 = d.replica_name
        FROM dbo._stats x
            JOIN #tmp_Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID
        WHERE x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._stats (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], stats_id, auto_created, user_created, no_recompute, has_filter, filter_definition, is_temporary, is_incremental, has_persisted_sample, stats_generation_method, stats_generation_method_desc, auto_drop, replica_role_id, replica_role_desc, replica_name)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[object_id], d.[name], d.stats_id, d.auto_created, d.user_created, d.no_recompute, d.has_filter, d.filter_definition, d.is_temporary, d.is_incremental, d.has_persisted_sample, d.stats_generation_method, d.stats_generation_method_desc, d.auto_drop, d.replica_role_id, d.replica_role_desc, d.replica_name
        FROM #tmp_Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
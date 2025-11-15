CREATE PROCEDURE import.usp_import__dm_db_index_usage_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_usage_stats READONLY,
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

    SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_index_usage_stats;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
    CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

    INSERT #Dataset WITH(TABLOCK) (
          _DatabaseID, _ObjectID, _IndexID, EstimatedStatsBeginTime, StatsEndTime
        , database_id, [object_id], index_id
        , user_seeks, user_scans, user_lookups, user_updates
        , last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc
        , system_seeks, system_scans, system_lookups, system_updates
        , last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc
    )
    SELECT @DatabaseID, o._ObjectID, o._IndexID, d.EstimatedStatsBeginTime, d.StatsEndTime
        , d.__database_id, d.__object_id, d.__index_id
        , COALESCE(d.user_seeks, 0), COALESCE(d.user_scans, 0), COALESCE(d.user_lookups, 0), COALESCE(d.user_updates, 0)
        , d.last_user_seek     AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_user_scan     AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_user_lookup   AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_user_update   AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , COALESCE(d.system_seeks, 0), COALESCE(d.system_scans, 0), COALESCE(d.system_lookups, 0), COALESCE(d.system_updates, 0)
        , d.last_system_seek   AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_system_scan   AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_system_lookup AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
        , d.last_system_update AT TIME ZONE d.InstanceTimeZone AT TIME ZONE 'UTC'
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs

        -- Record delta history before updating table
        EXEC dw.usp_import__dm_db_index_usage_stats_delta_history @DatabaseID = @DatabaseID, @Verbose = @Verbose;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_usage_stats';

        /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
            so it will always return every index. The only time indexes will be deleted is when
            they have been completely dropped from the database and never re-created. */
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._dm_db_index_usage_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET x._ObjectID               = d._ObjectID
          , x.EstimatedStatsBeginTime = d.EstimatedStatsBeginTime
          , x.StatsEndTime            = d.StatsEndTime
          , x.database_id             = d.database_id
          , x.[object_id]             = d.[object_id]
          , x.index_id                = d.index_id
          , x.user_seeks              = d.user_seeks
          , x.user_scans              = d.user_scans
          , x.user_lookups            = d.user_lookups
          , x.user_updates            = d.user_updates
          , x.last_user_seek_utc      = COALESCE(d.last_user_seek_utc, x.last_user_seek_utc)
          , x.last_user_scan_utc      = COALESCE(d.last_user_scan_utc, x.last_user_scan_utc)
          , x.last_user_lookup_utc    = COALESCE(d.last_user_lookup_utc, x.last_user_lookup_utc)
          , x.last_user_update_utc    = COALESCE(d.last_user_update_utc, x.last_user_update_utc)
          , x.system_seeks            = d.system_seeks
          , x.system_scans            = d.system_scans
          , x.system_lookups          = d.system_lookups
          , x.system_updates          = d.system_updates
          , x.last_system_seek_utc    = COALESCE(d.last_system_seek_utc, x.last_system_seek_utc)
          , x.last_system_scan_utc    = COALESCE(d.last_system_scan_utc, x.last_system_scan_utc)
          , x.last_system_lookup_utc  = COALESCE(d.last_system_lookup_utc, x.last_system_lookup_utc)
          , x.last_system_update_utc  = COALESCE(d.last_system_update_utc, x.last_system_update_utc)
        FROM dbo._dm_db_index_usage_stats x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._dm_db_index_usage_stats (_DatabaseID, _ObjectID, _IndexID, EstimatedStatsBeginTime, StatsEndTime, database_id, [object_id], index_id, user_seeks, user_scans, user_lookups, user_updates, last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc, system_seeks, system_scans, system_lookups, system_updates, last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d.EstimatedStatsBeginTime, d.StatsEndTime, d.database_id, d.[object_id], d.index_id, d.user_seeks, d.user_scans, d.user_lookups, d.user_updates, d.last_user_seek_utc, d.last_user_scan_utc, d.last_user_lookup_utc, d.last_user_update_utc, d.system_seeks, d.system_scans, d.system_lookups, d.system_updates, d.last_system_seek_utc, d.last_system_scan_utc, d.last_system_lookup_utc, d.last_system_update_utc
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_index_usage_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
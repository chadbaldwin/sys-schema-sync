CREATE PROC import.usp_import__dm_db_index_usage_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_usage_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;
    EXEC sp_set_session_context N'_DatabaseID', @DatabaseID;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_index_usage_stats;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

            INSERT #Dataset WITH(TABLOCK) (
                  _DatabaseID, _IndexID, EstimatedStatsBeginTime, StatsEndTime
                , database_id, [object_id], index_id
                , user_seeks, user_scans, user_lookups, user_updates
                , last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc
                , system_seeks, system_scans, system_lookups, system_updates
                , last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc
            )
            SELECT @DatabaseID, o._IndexID, d.EstimatedStatsBeginTime, d.StatsEndTime
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
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            EXEC import.usp_DeleteItemNameProcessByProcessKey @ProcessKey1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            -- Kick off pre-merge tasks - tasks that need to be able to compare the old data with the new data before the merge occurs

            -- Record delta history before updating table
            EXEC dw.usp_import__dm_db_index_usage_stats_delta @DatabaseID = @DatabaseID;
            ------------------------------------------------------------------------------

            ------------------------------------------------------------------------------
            SET @TableName = N'dbo._dm_db_index_usage_stats';

            /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
                so it will always return every index. The only time indexes will be deleted is when
                they have been completely dropped from the database and never re-created. */
            -- Common delete only
            EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @CallingProcName = @ProcName, @TargetTable = @TableName, @DeletesEnabled = 1, @UpdatesEnabled = 0, @InsertsEnabled = 0;

            /*  Special case for not using import.usp_RunCommonDUI
                This update deviates from the common pattern since we want last_* columns to bubble up to the top rather than getting set to null. */
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x.EstimatedStatsBeginTime = d.EstimatedStatsBeginTime
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
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            -- Common insert only
            EXEC import.usp_RunCommonDUI @DatabaseID = @DatabaseID, @CallingProcName = @ProcName, @TargetTable = @TableName, @DeletesEnabled = 0, @UpdatesEnabled = 0, @InsertsEnabled = 1;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @proc_sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @proc_sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
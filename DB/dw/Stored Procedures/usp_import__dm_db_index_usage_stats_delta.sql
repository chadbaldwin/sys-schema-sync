CREATE PROCEDURE dw.usp_import__dm_db_index_usage_stats_delta (
    @DatabaseID int
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;

    -- This is just for SSDT to stop complaining about the missing temp table
    IF (OBJECT_ID('tempdb..#Dataset') IS NULL) BEGIN; CREATE TABLE #Dataset (x int NOT NULL) END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dw._dm_db_index_usage_stats_delta';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE s FROM dw._dm_db_index_usage_stats_delta s
        WHERE s._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = s._DatabaseID AND d._IndexID = s._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
        -- Calcualted fields are being handled here because the destination table is a clustered columnstore index, which currently do not support computed columns
        UPDATE t
        SET t.EstimatedStatsBeginTime = y.EstimatedStatsBeginTime
          , t.StatsEndTime            = n.StatsEndTime
          , t.StatsAgeMS              = DATEDIFF_BIG(MILLISECOND, y.EstimatedStatsBeginTime, n.StatsEndTime)
          , t.WereStatsReset          = x.WereStatsReset
          , t.user_seeks              = z.user_seeks
          , t.user_scans              = z.user_scans
          , t.user_lookups            = z.user_lookups
          , t.user_updates            = z.user_updates
          , t.user_reads              = z.user_seeks + z.user_scans + z.user_lookups
          , t.last_user_seek_utc      = z.last_user_seek_utc
          , t.last_user_scan_utc      = z.last_user_scan_utc
          , t.last_user_lookup_utc    = z.last_user_lookup_utc
          , t.last_user_update_utc    = z.last_user_update_utc
          , t.last_user_read_utc      = GREATEST(z.last_user_seek_utc, z.last_user_scan_utc, z.last_user_lookup_utc)
          , t.system_seeks            = z.system_seeks
          , t.system_scans            = z.system_scans
          , t.system_lookups          = z.system_lookups
          , t.system_updates          = z.system_updates
          , t.system_reads            = z.system_seeks + z.system_scans + z.system_lookups
          , t.last_system_seek_utc    = z.last_system_seek_utc
          , t.last_system_scan_utc    = z.last_system_scan_utc
          , t.last_system_lookup_utc  = z.last_system_lookup_utc
          , t.last_system_update_utc  = z.last_system_update_utc
          , t.last_system_read_utc    = GREATEST(z.last_system_seek_utc, z.last_system_scan_utc, z.last_system_lookup_utc)
        FROM dw._dm_db_index_usage_stats_delta t -- Delta table
            JOIN dbo._dm_db_index_usage_stats p ON p._DatabaseID = t._DatabaseID AND p._IndexID = t._IndexID -- Previous snapshot
            JOIN #Dataset n ON n._DatabaseID = t._DatabaseID AND n._IndexID = t._IndexID -- New snapshot
            CROSS APPLY (
                SELECT WereStatsReset = CASE
                                            /*  If the new EstimatedStatsBeginTime is higher than the last snapshot time (StatsEndTime), then we know something was reset.
                                                e.g. SQL Server was restarted, database restored, table dropped and recreated, index dropped and recreated, etc.
                                                Unfortunately, this isn't a perfect solution. There may be other reasons for a stats record to be reset that we are not detecting. */
                                            WHEN n.EstimatedStatsBeginTime > p.StatsEndTime
                                            THEN 1
                                            /*  If the new value is lower than the previous value for counter based stats, then we know it has been reset.
                                                This is a safety measure to prevent negative values from being produced due to undetected counter resets. 

                                                Just like the other reset detection logic, this is just a best attempt. It's still possible for values to be higher and still
                                                be a reset especially when the values are typically on the low end. By using multiple fields that tend to be the most active,
                                                this can potentially help reduce any false positives on reset detection. */
                                            WHEN   n.user_seeks     < p.user_seeks
                                                OR n.user_scans     < p.user_scans
                                                OR n.user_lookups   < p.user_lookups
                                                OR n.user_updates   < p.user_updates
                                                OR n.system_seeks   < p.system_seeks
                                                OR n.system_scans   < p.system_scans
                                                OR n.system_lookups < p.system_lookups
                                                OR n.system_updates < p.system_updates
                                            THEN 1
                                            ELSE 0
                                        END
            ) x
            /* If it appears that the stats were not reset, then we want to use the StatsEndTime value from the previous snapshot */
            CROSS APPLY (SELECT EstimatedStatsBeginTime = IIF(x.WereStatsReset = 1, n.EstimatedStatsBeginTime, p.StatsEndTime)) y
            CROSS APPLY (
                SELECT
                    /* If the index's stats have been reset since the last time we took a snapshot, then the delta
                        needs to be based on our best guess of when the stats we're reset, rather than the end of the
                        previous stats snapshot. If it was reset, then we just want to take the whole stats value rather
                        than getting the difference since the last snapshot. */
                      user_seeks             = n.user_seeks     - IIF(x.WereStatsReset = 1, 0, p.user_seeks)
                    , user_scans             = n.user_scans     - IIF(x.WereStatsReset = 1, 0, p.user_scans)
                    , user_lookups           = n.user_lookups   - IIF(x.WereStatsReset = 1, 0, p.user_lookups)
                    , user_updates           = n.user_updates   - IIF(x.WereStatsReset = 1, 0, p.user_updates)
                    , system_seeks           = n.system_seeks   - IIF(x.WereStatsReset = 1, 0, p.system_seeks)
                    , system_scans           = n.system_scans   - IIF(x.WereStatsReset = 1, 0, p.system_scans)
                    , system_lookups         = n.system_lookups - IIF(x.WereStatsReset = 1, 0, p.system_lookups)
                    , system_updates         = n.system_updates - IIF(x.WereStatsReset = 1, 0, p.system_updates)
                    /* Bubble up the Last* fields
                        Since these fields reset back to NULL, we want the last populated value to always bubble up
                        to the top. This way we only need to look at the most recent record (in the temporal table)
                        in order to know the Last* dates. */
                    , last_user_seek_utc     = COALESCE(n.last_user_seek_utc, p.last_user_seek_utc)
                    , last_user_scan_utc     = COALESCE(n.last_user_scan_utc, p.last_user_scan_utc)
                    , last_user_lookup_utc   = COALESCE(n.last_user_lookup_utc, p.last_user_lookup_utc)
                    , last_user_update_utc   = COALESCE(n.last_user_update_utc, p.last_user_update_utc)
                    , last_system_seek_utc   = COALESCE(n.last_system_seek_utc, p.last_system_seek_utc)
                    , last_system_scan_utc   = COALESCE(n.last_system_scan_utc, p.last_system_scan_utc)
                    , last_system_lookup_utc = COALESCE(n.last_system_lookup_utc, p.last_system_lookup_utc)
                    , last_system_update_utc = COALESCE(n.last_system_update_utc, p.last_system_update_utc)
            ) z
        WHERE n.StatsEndTime > p.StatsEndTime;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dw._dm_db_index_usage_stats_delta (_DatabaseID, _IndexID, EstimatedStatsBeginTime, StatsEndTime, StatsAgeMS, WereStatsReset, user_seeks, user_scans, user_lookups, user_updates, user_reads, last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc, last_user_read_utc, system_seeks, system_scans, system_lookups, system_updates, system_reads, last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc, last_system_read_utc)
        SELECT s._DatabaseID, s._IndexID, s.EstimatedStatsBeginTime, s.StatsEndTime, DATEDIFF_BIG(MILLISECOND, s.EstimatedStatsBeginTime, s.StatsEndTime), 0, s.user_seeks, s.user_scans, s.user_lookups, s.user_updates, s.user_reads, s.last_user_seek_utc, s.last_user_scan_utc, s.last_user_lookup_utc, s.last_user_update_utc, s.last_user_read_utc, s.system_seeks, s.system_scans, s.system_lookups, s.system_updates, s.system_reads, s.last_system_seek_utc, s.last_system_scan_utc, s.last_system_lookup_utc, s.last_system_update_utc, s.last_system_read_utc   
        FROM #Dataset s
        WHERE NOT EXISTS (SELECT * FROM dw._dm_db_index_usage_stats_delta t WHERE t._DatabaseID = s._DatabaseID AND t._IndexID = s._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
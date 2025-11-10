CREATE PROCEDURE dw.usp_import__dm_db_index_usage_stats_delta_history (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_usage_stats READONLY,
    @ItemName   import.ItemName READONLY,
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
    -- Insert stats deltas
    ------------------------------------------------------------------------------
        INSERT dw._dm_db_index_usage_stats_delta_history (
              _DatabaseID, _ObjectID, _IndexID
            , EstimatedStatsBeginTime, StatsEndTime
            , StatsAgeMS
            , WereStatsReset
            , user_seeks, user_scans, user_lookups, user_updates, user_reads
            , system_seeks, system_scans, system_lookups, system_updates, system_reads
            , last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc, last_user_read_utc
            , last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc, last_system_read_utc
        )
        -- Calcualted fields are being handled here because the destination table is a clustered columnstore index, which currently do not support computed columns
        SELECT @DatabaseID, x._ObjectID, x._IndexID
            , x.EstimatedStatsBeginTime, x.StatsEndTime
            , StatsAgeMS = DATEDIFF(MILLISECOND, x.EstimatedStatsBeginTime, x.StatsEndTime)
            , x.WereStatsReset
            , x.user_seeks, x.user_scans, x.user_lookups, x.user_updates
            , user_reads = x.user_seeks + x.user_scans + x.user_lookups
            , x.system_seeks, x.system_scans, x.system_lookups, x.system_updates
            , system_reads = x.system_seeks + x.system_scans + x.system_lookups
            , x.last_user_seek_utc, x.last_user_scan_utc, x.last_user_lookup_utc, x.last_user_update_utc
            , last_user_read_utc = GREATEST(x.last_user_seek_utc, x.last_user_scan_utc, x.last_user_lookup_utc)
            , x.last_system_seek_utc, x.last_system_scan_utc, x.last_system_lookup_utc, x.last_system_update_utc
            , last_system_read_utc = GREATEST(x.last_system_seek_utc, x.last_system_scan_utc, x.last_system_lookup_utc)
        FROM (
            SELECT i._ObjectID, i._IndexID
                , EstimatedStatsBeginTime = y.EstimatedStatsBeginTime
                , StatsEndTime            = s.StatsEndTime
                , WereStatsReset          = x.WereStatsReset

                /* If the index's stats have been reset since the last time we took a snapshot, then the delta
                    needs to be based on our best guess of when the stats we're reset, rather than the end of the
                    previous stats snapshot. If it was reset, then we just want to take the whole stats value rather
                    than getting the difference since the last snapshot. */
                , user_seeks              = s.user_seeks     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.user_seeks)
                , user_scans              = s.user_scans     - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.user_scans)
                , user_lookups            = s.user_lookups   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.user_lookups)
                , user_updates            = s.user_updates   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.user_updates)
                , system_seeks            = s.system_seeks   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.system_seeks)
                , system_scans            = s.system_scans   - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.system_scans)
                , system_lookups          = s.system_lookups - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.system_lookups)
                , system_updates          = s.system_updates - IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, 0, t.system_updates)

                /* Bubble up the Last* fields
                    Since these fields reset back to NULL, we want the last populated value to always bubble up
                    to the top. This way we only need to look at the most recent record (in the temporal table)
                    in order to know the Last* dates. */
                , last_user_seek_utc      = COALESCE(s.last_user_seek_utc, t.last_user_seek_utc)
                , last_user_scan_utc      = COALESCE(s.last_user_scan_utc, t.last_user_scan_utc)
                , last_user_lookup_utc    = COALESCE(s.last_user_lookup_utc, t.last_user_lookup_utc)
                , last_user_update_utc    = COALESCE(s.last_user_update_utc, t.last_user_update_utc)
                , last_system_seek_utc    = COALESCE(s.last_system_seek_utc, t.last_system_seek_utc)
                , last_system_scan_utc    = COALESCE(s.last_system_scan_utc, t.last_system_scan_utc)
                , last_system_lookup_utc  = COALESCE(s.last_system_lookup_utc, t.last_system_lookup_utc)
                , last_system_update_utc  = COALESCE(s.last_system_update_utc, t.last_system_update_utc)
            FROM dbo._dm_db_index_usage_stats t -- Previous snapshot
                JOIN @ItemName i ON i._IndexID = t._IndexID
                JOIN @Dataset s ON s.__ID = i.ID -- New snapshot
                CROSS APPLY (
                    SELECT
                        /*  If the new EstimatedStatsBeginTime is higher than the last snapshot time (StatsEndTime), then we know something was reset.
                            e.g. SQL Server was restarted, database restored, table dropped and recreated, index dropped and recreated, etc.
                            Unfortunately, this isn't a perfect solution. There may be other reasons for a stats record to be reset that we are not detecting. */
                           WereStatsReset    = CONVERT(bit, IIF(s.EstStatsBeginTime > t.StatsEndTime, 1, 0))
                        /*  If the new value is lower than the previous value for counter based stats, then we know it has been reset.
                            This is a safety measure to prevent negative values from being produced due to undetected counter resets. */
                        ,  WereIdxStatsReset = CONVERT(bit, CASE
                                                                WHEN s.user_seeks     < t.user_seeks
                                                                  OR s.user_scans     < t.user_scans
                                                                  OR s.user_lookups   < t.user_lookups
                                                                  OR s.user_updates   < t.user_updates
                                                                  OR s.system_seeks   < t.system_seeks
                                                                  OR s.system_scans   < t.system_scans
                                                                  OR s.system_lookups < t.system_lookups
                                                                  OR s.system_updates < t.system_updates
                                                                THEN 1
                                                                ELSE 0
                                                            END)
                ) x
                /* If it appears that the stats were not reset, then we want to use the StatsEndTime value from the previous snapshot */
                CROSS APPLY (SELECT EstimatedStatsBeginTime = IIF(x.WereStatsReset = 1 OR x.WereIdxStatsReset = 1, s.EstStatsBeginTime, t.StatsEndTime)) y
            WHERE t._DatabaseID = @DatabaseID
                AND s.StatsEndTime > t.StatsEndTime
        ) x;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
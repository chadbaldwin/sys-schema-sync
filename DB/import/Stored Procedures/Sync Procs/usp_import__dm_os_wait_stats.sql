CREATE PROCEDURE import.usp_import__dm_os_wait_stats (
    @InstanceID int,
    @Dataset    import.import__dm_os_wait_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    -- TODO: Convert to similar setup as sys.dm_db_index_usage_stats using delta table with temporal history.

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_os_wait_stats';

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET   x._ModifyDate         = SYSUTCDATETIME()
            --
            , x.waiting_tasks_count = COALESCE(d.waiting_tasks_count, 0)
            , x.wait_time_ms        = COALESCE(d.wait_time_ms, 0)
            , x.max_wait_time_ms    = COALESCE(d.max_wait_time_ms, 0)
            , x.signal_wait_time_ms = COALESCE(d.signal_wait_time_ms, 0)
        FROM dbo._dm_os_wait_stats x
            LEFT JOIN @Dataset d ON d.wait_type = x.wait_type
        WHERE x._InstanceID = @InstanceID;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._dm_os_wait_stats (_InstanceID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
        SELECT @InstanceID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
        FROM @Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._dm_os_wait_stats x
                WHERE x._InstanceID = @InstanceID
                    AND x.wait_type = d.wait_type
            );
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
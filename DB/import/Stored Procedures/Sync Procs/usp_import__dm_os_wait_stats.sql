CREATE PROCEDURE import.usp_import__dm_os_wait_stats (
    @InstanceID int,
    @Dataset    import.import__dm_os_wait_stats READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._dm_os_wait_stats';

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
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
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._dm_os_wait_stats (_InstanceID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
    SELECT @InstanceID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
    FROM @Dataset d
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._dm_os_wait_stats x
            WHERE x._InstanceID = @InstanceID
                AND x.wait_type = d.wait_type
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

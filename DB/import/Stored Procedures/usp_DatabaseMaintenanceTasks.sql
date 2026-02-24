CREATE PROC import.usp_DatabaseMaintenanceTasks (
    @Verbose bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    SET @Verbose = COALESCE(CONVERT(bit, SESSION_CONTEXT(N'Verbose')), @Verbose); EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME(), @ts datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup orphaned records from ItemNameProcess table
    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Cleanup orphaned records from ItemNameProcess table', NULL, NULL, @ProcName; SET @ts = SYSUTCDATETIME();
    DECLARE @ts2 datetime2 = SYSUTCDATETIME(), @rc2 bigint;
    WHILE (1=1)
    BEGIN;
        DELETE TOP(3000) import.ItemNameProcess WHERE InsertDateUTC < DATEADD(MINUTE, -15, SYSUTCDATETIME());
        SET @rc2 = @@ROWCOUNT;
        IF (@rc2 = 0) BEGIN; BREAK; END;
        EXEC dbo.usp_Raiserror '[%s] Deleted batch', @ts2, @rc2, @ProcName; SET @ts2 = SYSUTCDATETIME();
        WAITFOR DELAY '00:00:01';
    END;
    EXEC dbo.usp_Raiserror '[%s] Done:  Cleanup orphaned records from ItemNameProcess table', @ts, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Force reset old sync object statuses to trigger a full re-sync
    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Force reset old sync object statuses to trigger a full re-sync', NULL, NULL, @ProcName; SET @ts = SYSUTCDATETIME();
    /* Clear out old checksums to force a full re-sync on any syncs that haven't run in a while.
       Cannot set to NULL because that would be seen as an error for any syncs which have a
       CHecksumQueryText configured. Setting to -1 instead, whcih is a valid checksum value
       but it's a harmless risk and low chances of a collision anyway */
    UPDATE import.DatabaseSyncObjectStatus
        SET LastSyncChecksum = -1
    WHERE LastSyncTime < DATEADD(DAY, -7, SYSUTCDATETIME())
        AND LastSyncChecksum <> -1; -- Implicitly excluding NULLs
    EXEC dbo.usp_Raiserror '[%s] Done:  Force reset old sync object statuses to trigger a full re-sync', @ts, @@ROWCOUNT, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup orphaned ObjectDefinition records
    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Cleanup orphaned ObjectDefinition records', NULL, NULL, @ProcName; SET @ts = SYSUTCDATETIME();
    DELETE od
    FROM dbo.ObjectDefinition od
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._sql_modules FOR SYSTEM_TIME ALL sm
            WHERE sm._ObjectDefinitionID = od._ObjectDefinitionID
        );
    EXEC dbo.usp_Raiserror '[%s] Done:  Cleanup orphaned ObjectDefinition records', @ts, @@ROWCOUNT, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup old logs
    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Cleanup old database logs', NULL, NULL, @ProcName; SET @ts = SYSUTCDATETIME();
    DELETE x
    FROM import.[Log] X
    WHERE InsertDate < DATEADD(DAY, -30, SYSUTCDATETIME());
    EXEC dbo.usp_Raiserror '[%s] Done:  Cleanup old database logs', @ts, @@ROWCOUNT, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- TODO
    ------------------------------------------------------------------------------
    /*
        * Soft delete cleanup (Object, Index, Column)
        * Old database cleanup
    */
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @proc_sw, NULL, @ProcName;
END;
GO
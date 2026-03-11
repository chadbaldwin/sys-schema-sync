CREATE PROC import.usp_DatabaseMaintenanceTasks (
    @UpdateStats bit = 1,
    @Verbose bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    SET @Verbose = COALESCE(CONVERT(bit, SESSION_CONTEXT(N'Verbose')), @Verbose); EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    DECLARE @TableName nvarchar(300), @ts datetime2;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup orphaned records from ItemNameProcess table
    ------------------------------------------------------------------------------
    SET @TableName = 'import.ItemNameProcess';
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete loop', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup orphaned records from ItemNameProcess table', @ts = @ts OUTPUT;
    DECLARE @ts2 datetime2, @rc2 bigint;
    WHILE (@rc2 > 0 OR @rc2 IS NULL)
    BEGIN;
        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @ts2 OUTPUT;
        DELETE TOP(3000) import.ItemNameProcess WHERE InsertDateUTC < DATEADD(MINUTE, -15, SYSUTCDATETIME());
        SET @rc2 = @@ROWCOUNT;
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete batch', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @ts2, @rc = @rc2;
    END;
    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete loop', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup orphaned records from ItemNameProcess table', @ts = @ts;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Force reset old sync object statuses to trigger a full re-sync
    ------------------------------------------------------------------------------
    SET @TableName = 'import.DatabaseSyncObjectStatus';
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Update LastSyncChecksum', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Force reset old sync object statuses to trigger a full re-sync', @ts = @ts OUTPUT;
    /* Clear out old checksums to force a full re-sync on any syncs that haven't run in a while.
       Cannot set to NULL because that would be seen as an error for any syncs which have a
       CHecksumQueryText configured. Setting to -1 instead, whcih is a valid checksum value
       but it's a harmless risk and low chances of a collision anyway */
    UPDATE import.DatabaseSyncObjectStatus
        SET LastSyncChecksum = -1
    WHERE LastSyncTime < DATEADD(DAY, -7, SYSUTCDATETIME())
        AND LastSyncChecksum <> -1; -- Implicitly excluding NULLs
    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Update LastSyncChecksum', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Force reset old sync object statuses to trigger a full re-sync', @ts = @ts, @rc = @@ROWCOUNT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup orphaned ObjectDefinition records
    ------------------------------------------------------------------------------
    SET @TableName = 'dbo.ObjectDefinition';
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup orphaned ObjectDefinition records', @ts = @ts OUTPUT;
    DELETE od
    FROM dbo.ObjectDefinition od
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._sql_modules FOR SYSTEM_TIME ALL sm
            WHERE sm._ObjectDefinitionID = od._ObjectDefinitionID
        );
    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup orphaned ObjectDefinition records', @ts = @ts, @rc = @@ROWCOUNT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Cleanup old logs
    ------------------------------------------------------------------------------
    SET @TableName = 'import.Log';
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Delete', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup old database logs', @ts = @ts OUTPUT;
    DELETE x
    FROM import.[Log] X
    WHERE InsertDate < DATEADD(DAY, -30, SYSUTCDATETIME());
    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Delete', @Scope1 = @ProcName, @Scope2 = @TableName, @DetailMessage = 'Cleanup old database logs', @ts = @ts, @rc = @@ROWCOUNT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Update stats for entire database
    ------------------------------------------------------------------------------
    IF (@UpdateStats = 1)
    BEGIN;
        EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @Scope2 = 'sys.sp_updatestats', @DetailMessage = 'Update stats for entire database', @ts = @ts OUTPUT;
        EXECUTE sys.sp_updatestats;
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @Scope2 = 'sys.sp_updatestats', @DetailMessage = 'Update stats for entire database', @ts = @ts;
    END;
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
    EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw;
END;
GO
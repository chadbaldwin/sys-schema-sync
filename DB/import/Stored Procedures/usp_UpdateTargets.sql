CREATE PROCEDURE import.usp_UpdateTargets (
    @ServiceConfigJSON nvarchar(MAX),
    @Verbose           bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#tmp_db','U') IS NOT NULL DROP TABLE #tmp_db; --SELECT * FROM #tmp_db
    CREATE TABLE #tmp_db (
        InstanceName nvarchar(128) NOT NULL,
        DatabaseName nvarchar(128) NOT NULL,
    );

    INSERT #tmp_db (InstanceName, DatabaseName)
    SELECT d.InstanceName, d.DatabaseName
    FROM OPENJSON(@ServiceConfigJSON)
        WITH (
            InstanceName nvarchar(128) '$.InstanceName',
            DatabaseName nvarchar(128) '$.DatabaseName'
        ) d;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Merge Instance: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();
    MERGE INTO dbo.Instance WITH(HOLDLOCK) o
    USING (
        SELECT DISTINCT InstanceName
        FROM #tmp_db
    ) AS n ON n.InstanceName = o.InstanceName
    WHEN MATCHED AND o.IsEnabled = 0
    THEN UPDATE
        SET o.IsEnabled = 1,
            o.DisableDate = NULL
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (InstanceName)
         VALUES (n.InstanceName)
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1
    THEN UPDATE
        SET o.IsEnabled = 0,
            o.DisableDate = SYSUTCDATETIME()
    OUTPUT $action AS MergeAction
        , DELETED._InstanceID AS d__InstanceID, DELETED.InstanceName AS d_InstanceName, DELETED.InsertDate AS d_InsertDate, DELETED.IsEnabled AS d_IsEnabled
        , INSERTED._InstanceID AS i__InstanceID, INSERTED.InstanceName AS i_InstanceName, INSERTED.InsertDate AS i_InsertDate, INSERTED.IsEnabled AS i_IsEnabled;
    EXEC dbo.usp_Raiserror '[%s] Merge Instance: Done', @sw2, NULL, @ProcName;

    EXEC dbo.usp_Raiserror '[%s] Merge Database: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();
    MERGE INTO dbo.[Database] WITH(HOLDLOCK) o
    USING (
        SELECT DISTINCT t.DatabaseName, i._InstanceID
        FROM #tmp_db t
            JOIN dbo.Instance i ON i.InstanceName = t.InstanceName
    ) AS n ON n._InstanceID = o._InstanceID AND n.DatabaseName = o.DatabaseName
    WHEN MATCHED AND o.IsEnabled = 0
    THEN UPDATE
        SET o.IsEnabled = 1,
            o.DisableDate = NULL
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (_InstanceID, DatabaseName)
         VALUES (n._InstanceID, n.DatabaseName)
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1
    THEN UPDATE
        SET o.IsEnabled = 0,
            o.DisableDate = SYSUTCDATETIME()
    OUTPUT $action AS MergeAction
        , DELETED._DatabaseID AS d__DatabaseID, DELETED._InstanceID AS d__InstanceID, DELETED.DatabaseName AS d_DatabaseName, DELETED.InsertDate AS d_InsertDate, DELETED.IsEnabled AS d_IsEnabled
        , INSERTED._DatabaseID AS i__DatabaseID, INSERTED._InstanceID AS i__InstanceID, INSERTED.DatabaseName AS i_DatabaseName, INSERTED.InsertDate AS i_InsertDate, INSERTED.IsEnabled AS i_IsEnabled;
    EXEC dbo.usp_Raiserror '[%s] Merge Database: Done', @sw2, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
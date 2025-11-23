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
    --DROP TABLE IF EXISTS #tmp_db;
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
    /* Lets get one thing out of the way here...Yes, I know merge is bad, don't use it.
       But, since this is simple utility script for maintaining a simple schema table,
       I'm just letting it slide for now to make the logic a little easier. Otherwise
       I'd need to write like 6 individual statements */
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Merge Instance', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();
    MERGE INTO dbo.Instance o
    USING (SELECT DISTINCT InstanceName FROM #tmp_db) AS n ON n.InstanceName = o.InstanceName
    WHEN MATCHED AND o.IsEnabled = 0               THEN UPDATE SET o.IsEnabled = 1, o.DisableDate = NULL -- Re-enable
    WHEN NOT MATCHED BY TARGET                     THEN INSERT (InstanceName) VALUES (n.InstanceName) -- Insert new
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1 THEN UPDATE SET o.IsEnabled = 0, o.DisableDate = SYSUTCDATETIME() -- Disable missing
    OUTPUT $action AS MergeAction
        , COALESCE(DELETED._InstanceID, INSERTED._InstanceID) AS _InstanceID
        , COALESCE(DELETED.InstanceName, INSERTED.InstanceName) AS InstanceName
        , DELETED.InsertDate  AS d_InsertDate, DELETED.IsEnabled  AS d_IsEnabled
        , INSERTED.InsertDate AS i_InsertDate, INSERTED.IsEnabled AS i_IsEnabled;
    EXEC dbo.usp_Raiserror '[%s] Done: Merge Instance', @sw2, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Start: Merge Database', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();
    MERGE INTO dbo.[Database] o
    USING (
        SELECT DISTINCT i._InstanceID, t.DatabaseName
        FROM #tmp_db t
            JOIN dbo.Instance i ON i.InstanceName = t.InstanceName
    ) AS n ON n._InstanceID = o._InstanceID AND n.DatabaseName = o.DatabaseName
    WHEN MATCHED AND o.IsEnabled = 0               THEN UPDATE SET o.IsEnabled = 1, o.DisableDate = NULL -- Re-enable
    WHEN NOT MATCHED BY TARGET                     THEN INSERT (_InstanceID, DatabaseName) VALUES (n._InstanceID, n.DatabaseName) -- Insert new
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1 THEN UPDATE SET o.IsEnabled = 0, o.DisableDate = SYSUTCDATETIME() -- Disable missing
    -- Output
    OUTPUT $action AS MergeAction
        , COALESCE(DELETED._InstanceID, INSERTED._InstanceID) AS _InstanceID
        , COALESCE(DELETED._DatabaseID, INSERTED._DatabaseID) AS _DatabaseID
        , COALESCE(DELETED.DatabaseName, INSERTED.DatabaseName) AS DatabaseName
        , DELETED.InsertDate  AS d_InsertDate, DELETED.IsEnabled  AS d_IsEnabled
        , INSERTED.InsertDate AS i_InsertDate, INSERTED.IsEnabled AS i_IsEnabled;
    EXEC dbo.usp_Raiserror '[%s] Done: Merge Database', @sw2, NULL, @ProcName;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
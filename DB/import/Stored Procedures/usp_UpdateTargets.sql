CREATE PROCEDURE import.usp_UpdateTargets (
    @ServiceConfigJSON nvarchar(MAX)
)
AS
BEGIN;
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#tmp_db','U') IS NOT NULL DROP TABLE #tmp_db; --SELECT * FROM #tmp_db
    CREATE TABLE #tmp_db (
        InstanceName nvarchar(128) NOT NULL,
        DatabaseName nvarchar(128) NOT NULL,
    );
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    INSERT INTO #tmp_db (InstanceName, DatabaseName)
    SELECT d.Instance, d.[Database]
    FROM OPENJSON(@ServiceConfigJSON)
        WITH (
            Instance nvarchar(128) '$.InstanceName',
            [Database] nvarchar(128) '$.DatabaseName'
        ) d;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
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
END;
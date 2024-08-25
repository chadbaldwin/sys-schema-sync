CREATE PROCEDURE import.usp_UpdateTargets
AS
BEGIN;
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#tmp_db','U') IS NOT NULL DROP TABLE #tmp_db; --SELECT * FROM #tmp_db
    CREATE TABLE #tmp_db (
        InstanceName nvarchar(128) NOT NULL,
        DatabaseName nvarchar(128) NOT NULL,
    )
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Temporary data until I figure out how I want to handle this in the future
    -- More than likely will abandon this proc entirely and go with a JSON configuration file along with a PowerShell script to sync configuration
    INSERT INTO #tmp_db (InstanceName, DatabaseName)
    VALUES ('Instance1', 'DBFoo')
        ,  ('Instance1', 'DBBar')
        ,  ('Instance2', 'DBFoo')
        ,  ('Instance3', 'DBQux');
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    MERGE INTO dbo.Instance WITH(HOLDLOCK) o
    USING (
        SELECT DISTINCT InstanceName
        FROM #tmp_db
    ) AS n ON n.InstanceName = o.InstanceName
    WHEN MATCHED AND o.IsEnabled = 0
        THEN UPDATE SET o.IsEnabled = 1
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (InstanceName) VALUES (n.InstanceName)
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1
        THEN UPDATE SET o.IsEnabled = 0
    OUTPUT $action, 'Deleted', Deleted.*, 'Inserted', Inserted.*;

    MERGE INTO dbo.[Database] WITH(HOLDLOCK) o
    USING (
        SELECT DISTINCT t.DatabaseName, i._InstanceID
        FROM #tmp_db t
            JOIN dbo.Instance i ON i.InstanceName = t.InstanceName
    ) AS n ON n._InstanceID = o._InstanceID AND n.DatabaseName = o.DatabaseName
    WHEN MATCHED AND o.IsEnabled = 0
        THEN UPDATE SET o.IsEnabled = 1
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (_InstanceID, DatabaseName) VALUES (n._InstanceID, n.DatabaseName)
    WHEN NOT MATCHED BY SOURCE AND o.IsEnabled = 1
        THEN UPDATE SET o.IsEnabled = 0
    OUTPUT $action, 'Deleted', Deleted.*, 'Inserted', Inserted.*;
END;
GO

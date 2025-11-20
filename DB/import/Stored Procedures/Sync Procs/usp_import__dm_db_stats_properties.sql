CREATE PROCEDURE import.usp_import__dm_db_stats_properties (
    @DatabaseID int,
    @Dataset    import.import__dm_db_stats_properties READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    -- TODO: Add _BoundaryValue and supporting logic since partition_number is not sticky, but boundary values are.

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', NULL, NULL, @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
         EXEC dbo.usp_Raiserror '[%s] Start: Get IDs', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_stats_properties;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], stats_id, last_updated, [rows], rows_sampled, steps, unfiltered_rows, modification_counter, persisted_sample_percent)
        SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[object_id], d.stats_id, d.last_updated, d.[rows], d.rows_sampled, d.steps, d.unfiltered_rows, d.modification_counter, d.persisted_sample_percent
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_stats_properties';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._dm_db_stats_properties x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ObjectID                = d._ObjectID
          , x._ModifyDate              = SYSUTCDATETIME()
          , x._RowHash                 = d._RowHash
          , x.[object_id]              = d.[object_id]
          , x.stats_id                 = d.stats_id
          , x.last_updated             = d.last_updated
          , x.[rows]                   = d.[rows]
          , x.rows_sampled             = d.rows_sampled
          , x.steps                    = d.steps
          , x.unfiltered_rows          = d.unfiltered_rows
          , x.modification_counter     = d.modification_counter
          , x.persisted_sample_percent = d.persisted_sample_percent
        FROM dbo._dm_db_stats_properties x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._dm_db_stats_properties (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], stats_id, last_updated, [rows], rows_sampled, steps, unfiltered_rows, modification_counter, persisted_sample_percent)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[object_id], d.stats_id, d.last_updated, d.[rows], d.rows_sampled, d.steps, d.unfiltered_rows, d.modification_counter, d.persisted_sample_percent
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_stats_properties x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
CREATE PROCEDURE import.usp_import__dm_db_stats_properties (
    @DatabaseID int,
    @Dataset    import.import__dm_db_stats_properties READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @rc bigint;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_stats_properties;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], stats_id, last_updated, [rows], rows_sampled, steps, unfiltered_rows, modification_counter, persisted_sample_percent)
        SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[object_id], d.stats_id, d.last_updated, d.[rows], d.rows_sampled, d.steps, d.unfiltered_rows, d.modification_counter, d.persisted_sample_percent
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_stats_properties';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE x FROM dbo._dm_db_stats_properties x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dbo._dm_db_stats_properties (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], stats_id, last_updated, [rows], rows_sampled, steps, unfiltered_rows, modification_counter, persisted_sample_percent)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[object_id], d.stats_id, d.last_updated, d.[rows], d.rows_sampled, d.steps, d.unfiltered_rows, d.modification_counter, d.persisted_sample_percent
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_stats_properties x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
CREATE PROCEDURE import.usp_import__missing_indexes (
    @DatabaseID int,
    @Dataset    import.import__missing_indexes READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
         EXEC dbo.usp_Raiserror '[%s] Get IDs: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._missing_indexes;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, missing_index_hash, unique_compiles, user_seeks, user_scans, last_user_seek_utc, last_user_scan_utc, avg_total_user_cost, avg_user_impact, equality_columns, inequality_columns, included_columns, column_data)
        SELECT @DatabaseID, o._ObjectID, d._RowHash, d.missing_index_hash, d.unique_compiles, d.user_seeks, d.user_scans, d.last_user_seek_utc, d.last_user_scan_utc, d.avg_total_user_cost, d.avg_user_impact, d.equality_columns, d.inequality_columns, d.included_columns, d.column_data
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Get IDs: Done', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._missing_indexes';

        /* -- Not doing standard delete for now
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._missing_indexes x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE x._DatabaseID = d._DatabaseID AND x._ObjectID = d._ObjectID AND x.missing_index_hash = d.missing_index_hash);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
        */

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET   x._ModifyDate         = SYSUTCDATETIME()
            , x._RowHash            = d._RowHash
            , x.unique_compiles     = d.unique_compiles
            , x.user_seeks          = d.user_seeks
            , x.user_scans          = d.user_scans
            , x.last_user_seek_utc  = d.last_user_seek_utc
            , x.last_user_scan_utc  = d.last_user_scan_utc
            , x.avg_total_user_cost = d.avg_total_user_cost
            , x.avg_user_impact     = d.avg_user_impact
            , x.equality_columns    = d.equality_columns
            , x.inequality_columns  = d.inequality_columns
            , x.included_columns    = d.included_columns
        FROM dbo._missing_indexes x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.missing_index_hash = x.missing_index_hash
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._missing_indexes (_DatabaseID, _ObjectID, _RowHash, missing_index_hash, unique_compiles, user_seeks, user_scans, last_user_seek_utc, last_user_scan_utc, avg_total_user_cost, avg_user_impact, equality_columns, inequality_columns, included_columns, column_data)
        SELECT @DatabaseID, d._ObjectID, d._RowHash, d.missing_index_hash, d.unique_compiles, d.user_seeks, d.user_scans, d.last_user_seek_utc, d.last_user_scan_utc, d.avg_total_user_cost, d.avg_user_impact, d.equality_columns, d.inequality_columns, d.included_columns, d.column_data
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._missing_indexes x WHERE x._DatabaseID = d._DatabaseID AND x._ObjectID = d._ObjectID AND x.missing_index_hash = d.missing_index_hash);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Instead of standard deletes, just do simple time based pruning
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._missing_indexes x
        WHERE x._DatabaseID = @DatabaseID
            AND x._ModifyDate < DATEADD(DAY, -30, SYSUTCDATETIME());
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
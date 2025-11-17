CREATE PROCEDURE import.usp_import__dm_db_partition_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_partition_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
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
         EXEC dbo.usp_Raiserror '[%s] Get IDs: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_partition_stats;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, partition_number);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
        SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Get IDs: Done', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_partition_stats';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._dm_db_partition_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ObjectID                        = d._ObjectID
          , x._ModifyDate                      = SYSUTCDATETIME()
          , x._RowHash                         = d._RowHash
          , x.[partition_id]                   = d.[partition_id]
          , x.[object_id]                      = d.[object_id]
          , x.index_id                         = d.index_id
          , x.in_row_data_page_count           = d.in_row_data_page_count
          , x.in_row_used_page_count           = d.in_row_used_page_count
          , x.in_row_reserved_page_count       = d.in_row_reserved_page_count
          , x.lob_used_page_count              = d.lob_used_page_count
          , x.lob_reserved_page_count          = d.lob_reserved_page_count
          , x.row_overflow_used_page_count     = d.row_overflow_used_page_count
          , x.row_overflow_reserved_page_count = d.row_overflow_reserved_page_count
          , x.used_page_count                  = d.used_page_count
          , x.reserved_page_count              = d.reserved_page_count
          , x.row_count                        = d.row_count
        FROM dbo._dm_db_partition_stats x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._dm_db_partition_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_partition_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
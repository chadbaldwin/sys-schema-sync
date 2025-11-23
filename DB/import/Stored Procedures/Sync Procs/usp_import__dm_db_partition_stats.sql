CREATE PROCEDURE import.usp_import__dm_db_partition_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_partition_stats READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._dm_db_partition_stats;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, partition_number);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
            SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._dm_db_partition_stats';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._dm_db_partition_stats x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
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
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._dm_db_partition_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, in_row_data_page_count, in_row_used_page_count, in_row_reserved_page_count, lob_used_page_count, lob_reserved_page_count, row_overflow_used_page_count, row_overflow_reserved_page_count, used_page_count, reserved_page_count, row_count)
            SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.in_row_data_page_count, d.in_row_used_page_count, d.in_row_reserved_page_count, d.lob_used_page_count, d.lob_reserved_page_count, d.row_overflow_used_page_count, d.row_overflow_reserved_page_count, d.used_page_count, d.reserved_page_count, d.row_count
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._dm_db_partition_stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
-- TODO: Add _BoundaryValue and supporting logic since partition_number is not sticky, but boundary values are.
GO
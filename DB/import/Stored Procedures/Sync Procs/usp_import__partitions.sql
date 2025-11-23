CREATE PROCEDURE import.usp_import__partitions (
    @DatabaseID int,
    @Dataset    import.import__partitions READONLY,
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
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, 'import.ItemNameProcess'; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, 'import.ItemNameProcess';

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, '#Dataset'; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._partitions;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, partition_number);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, hobt_id, [rows], filestream_filegroup_id, [data_compression], data_compression_desc, xml_compression, xml_compression_desc)
            SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.[rows], d.filestream_filegroup_id, d.[data_compression], d.data_compression_desc, d.xml_compression, d.xml_compression_desc
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s]  [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, '#Dataset';
            ----------------------------------------

            ----------------------------------------
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, 'import.ItemNameProcess'; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, 'import.ItemNameProcess';
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._partitions';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._partitions x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ObjectID               = d._ObjectID
              , x._ModifyDate             = SYSUTCDATETIME()
              , x._RowHash                = d._RowHash
              , x.[partition_id]          = d.[partition_id]
              , x.[object_id]             = d.[object_id]
              , x.index_id                = d.index_id
              , x.hobt_id                 = d.hobt_id
              , x.[rows]                  = d.[rows]
              , x.filestream_filegroup_id = d.filestream_filegroup_id
              , x.[data_compression]      = d.[data_compression]
              , x.data_compression_desc   = d.data_compression_desc
              , x.xml_compression         = d.xml_compression
              , x.xml_compression_desc    = d.xml_compression_desc
            FROM dbo._partitions x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._partitions (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, hobt_id, [rows], filestream_filegroup_id, [data_compression], data_compression_desc, xml_compression, xml_compression_desc)
            SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.[rows], d.filestream_filegroup_id, d.[data_compression], d.data_compression_desc, d.xml_compression, d.xml_compression_desc
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._partitions x WHERE x._DatabaseID = d._DatabaseID AND x._IndexID  = d._IndexID AND x.partition_number = d.partition_number);
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
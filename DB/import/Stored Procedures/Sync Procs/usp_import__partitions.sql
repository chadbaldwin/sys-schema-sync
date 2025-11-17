CREATE PROCEDURE import.usp_import__partitions (
    @DatabaseID int,
    @Dataset    import.import__partitions READONLY,
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
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._partitions;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, partition_number);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, hobt_id, [rows], filestream_filegroup_id, [data_compression], data_compression_desc, xml_compression, xml_compression_desc)
        SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.[rows], d.filestream_filegroup_id, d.[data_compression], d.data_compression_desc, d.xml_compression, d.xml_compression_desc
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._partitions';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._partitions x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d.partition_number = x.partition_number);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._partitions (_DatabaseID, _ObjectID, _IndexID, _RowHash, [partition_id], [object_id], index_id, partition_number, hobt_id, [rows], filestream_filegroup_id, [data_compression], data_compression_desc, xml_compression, xml_compression_desc)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[partition_id], d.[object_id], d.index_id, d.partition_number, d.hobt_id, d.[rows], d.filestream_filegroup_id, d.[data_compression], d.data_compression_desc, d.xml_compression, d.xml_compression_desc
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._partitions x WHERE x._DatabaseID = d._DatabaseID AND x._IndexID  = d._IndexID AND x.partition_number = d.partition_number);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
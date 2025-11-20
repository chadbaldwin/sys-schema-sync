CREATE PROCEDURE import.usp_import__index_columns (
    @DatabaseID int,
    @Dataset    import.import__index_columns READONLY,
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
         EXEC dbo.usp_Raiserror '[%s] Start: Get IDs', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName, _ColumnName FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._index_columns;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID, _ColumnID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _ColumnID, _RowHash, [object_id], index_id, index_column_id, column_id, key_ordinal, partition_ordinal, is_descending_key, is_included_column, column_store_order_ordinal, data_clustering_ordinal)
        SELECT @DatabaseID, o._ObjectID, o._IndexID, o._ColumnID, d._RowHash, d.[object_id], d.index_id, d.index_column_id, d.column_id, d.key_ordinal, d.partition_ordinal, d.is_descending_key, d.is_included_column, d.column_store_order_ordinal, d.data_clustering_ordinal
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._index_columns';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._index_columns x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ObjectID                  = d._ObjectID
          , x._ModifyDate                = SYSUTCDATETIME()
          , x._RowHash                   = d._RowHash
          , x.[object_id]                = d.[object_id]
          , x.index_id                   = d.index_id
          , x.index_column_id            = d.index_column_id
          , x.column_id                  = d.column_id
          , x.key_ordinal                = d.key_ordinal
          , x.partition_ordinal          = d.partition_ordinal
          , x.is_descending_key          = d.is_descending_key
          , x.is_included_column         = d.is_included_column
          , x.column_store_order_ordinal = d.column_store_order_ordinal
          , x.data_clustering_ordinal    = d.data_clustering_ordinal
        FROM dbo._index_columns x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._index_columns (_DatabaseID, _ObjectID, _IndexID, _ColumnID, _RowHash, [object_id], index_id, index_column_id, column_id, key_ordinal, partition_ordinal, is_descending_key, is_included_column, column_store_order_ordinal, data_clustering_ordinal)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._ColumnID, d._RowHash, d.[object_id], d.index_id, d.index_column_id, d.column_id, d.key_ordinal, d.partition_ordinal, d.is_descending_key, d.is_included_column, d.column_store_order_ordinal, d.data_clustering_ordinal
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._index_columns x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
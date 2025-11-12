CREATE PROCEDURE import.usp_import__index_columns (
    @DatabaseID int,
    @Dataset    import.import__index_columns READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName, _ColumnName FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    SELECT _DatabaseID = @DatabaseID
        , _ObjectID    = o._ObjectID
        , _IndexID     = o._IndexID
        , _ColumnID    = o._ColumnID
        , d._RowHash, d.[object_id], d.index_id, d.index_column_id, d.column_id, d.key_ordinal, d.partition_ordinal, d.is_descending_key, d.is_included_column, d.column_store_order_ordinal, d.data_clustering_ordinal
    INTO #tmp_Dataset
    FROM @Dataset d
        JOIN @output o ON o.ID = d.__ID;

    CREATE INDEX IX ON #tmp_Dataset (_DatabaseID, _ObjectID);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._index_columns';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._index_columns x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #tmp_Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
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
            JOIN #tmp_Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID
        WHERE x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._index_columns (_DatabaseID, _ObjectID, _IndexID, _ColumnID, _RowHash, [object_id], index_id, index_column_id, column_id, key_ordinal, partition_ordinal, is_descending_key, is_included_column, column_store_order_ordinal, data_clustering_ordinal)
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._ColumnID, d._RowHash, d.[object_id], d.index_id, d.index_column_id, d.column_id, d.key_ordinal, d.partition_ordinal, d.is_descending_key, d.is_included_column, d.column_store_order_ordinal, d.data_clustering_ordinal
        FROM #tmp_Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._index_columns x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID AND d._ColumnID = x._ColumnID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
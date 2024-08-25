CREATE PROCEDURE import.usp_import__index_columns (
    @DatabaseID int,
    @Dataset    import.import__index_columns READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Dataset','U') IS NOT NULL DROP TABLE #Dataset; --SELECT * FROM #Dataset
    SELECT ID = IDENTITY(int), * INTO #Dataset FROM @Dataset;

    DECLARE @input  import.ItemName,
            @output import.ItemName;

    -- object
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType, _IndexName, _ColumnName FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._index_columns';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._index_columns x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._IndexID = x._IndexID AND o._ColumnID = x._ColumnID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                 = SYSUTCDATETIME()
        , x._RowHash                    = d._RowHash
        --
        , x.[object_id]                 = d.[object_id]
        , x.index_id                    = d.index_id
        , x.index_column_id             = d.index_column_id
        , x.column_id                   = d.column_id
        , x.key_ordinal                 = d.key_ordinal
        , x.partition_ordinal           = d.partition_ordinal
        , x.is_descending_key           = d.is_descending_key
        , x.is_included_column          = d.is_included_column
        , x.column_store_order_ordinal  = d.column_store_order_ordinal
    FROM dbo._index_columns x
        JOIN @output y ON y._IndexID = x._IndexID AND y._ColumnID = x._ColumnID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._index_columns (_DatabaseID, _ObjectID, _IndexID, _ColumnID, _RowHash
        , [object_id], index_id, index_column_id, column_id, key_ordinal, partition_ordinal, is_descending_key, is_included_column, column_store_order_ordinal)
    SELECT @DatabaseID, y._ObjectID, y._IndexID, y._ColumnID, d._RowHash
        , d.[object_id], d.index_id, d.index_column_id, d.column_id, d.key_ordinal, d.partition_ordinal, d.is_descending_key, d.is_included_column, d.column_store_order_ordinal
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._index_columns x
            WHERE x._IndexID = y._IndexID AND x._ColumnID  = y._ColumnID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

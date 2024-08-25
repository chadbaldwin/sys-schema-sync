CREATE PROCEDURE import.usp_import__indexes (
    @DatabaseID int,
    @Dataset    import.import__indexes READONLY
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
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @FullImport_Index = 1;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._indexes';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._indexes x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._IndexID = x._IndexID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                     = SYSUTCDATETIME()
        , x._RowHash                        = d._RowHash
        --
        , x.[object_id]                     = d.[object_id]
        , x.index_id                        = d.index_id
        , x.[type]                          = d.[type]
        , x.[type_desc]                     = d.[type_desc]
        , x.is_unique                       = d.is_unique
        , x.data_space_id                   = d.data_space_id
        , x.[ignore_dup_key]                = d.[ignore_dup_key]
        , x.is_primary_key                  = d.is_primary_key
        , x.is_unique_constraint            = d.is_unique_constraint
        , x.fill_factor                     = d.fill_factor
        , x.is_padded                       = d.is_padded
        , x.is_disabled                     = d.is_disabled
        , x.is_hypothetical                 = d.is_hypothetical
        , x.is_ignored_in_optimization      = d.is_ignored_in_optimization
        , x.[allow_row_locks]               = d.[allow_row_locks]
        , x.[allow_page_locks]              = d.[allow_page_locks]
        , x.has_filter                      = d.has_filter
        , x.filter_definition               = d.filter_definition
        , x.[compression_delay]             = d.[compression_delay]
        , x.suppress_dup_key_messages       = d.suppress_dup_key_messages
        , x.auto_created                    = d.auto_created
        , x.[optimize_for_sequential_key]   = d.[optimize_for_sequential_key]
    FROM dbo._indexes x
        JOIN @output y ON y._IndexID = x._IndexID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._indexes (_DatabaseID, _ObjectID, _IndexID, _RowHash
        , [object_id], [name], index_id, [type], [type_desc], is_unique, data_space_id, [ignore_dup_key], is_primary_key, is_unique_constraint, fill_factor, is_padded, is_disabled, is_hypothetical, is_ignored_in_optimization, [allow_row_locks], [allow_page_locks], has_filter, filter_definition, [compression_delay], suppress_dup_key_messages, auto_created, [optimize_for_sequential_key])
    SELECT @DatabaseID, y._ObjectID, y._IndexID, d._RowHash
        , d.[object_id], d.[name], d.index_id, d.[type], d.[type_desc], d.is_unique, d.data_space_id, d.[ignore_dup_key], d.is_primary_key, d.is_unique_constraint, d.fill_factor, d.is_padded, d.is_disabled, d.is_hypothetical, d.is_ignored_in_optimization, d.[allow_row_locks], d.[allow_page_locks], d.has_filter, d.filter_definition, d.[compression_delay], d.suppress_dup_key_messages, d.auto_created, d.[optimize_for_sequential_key]
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._indexes x
            WHERE x._IndexID  = y._IndexID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

CREATE PROCEDURE import.usp_import__identity_columns (
    @DatabaseID int,
    @Dataset    import.import__identity_columns READONLY
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
    INSERT INTO @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
    SELECT ID, _SchemaName, _ObjectName, _ObjectType, _ColumnName FROM #Dataset;

    INSERT INTO @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._identity_columns';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x FROM dbo._identity_columns x
    WHERE x._DatabaseID = @DatabaseID
        AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID AND o._ColumnID = x._ColumnID);
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._ModifyDate                         = SYSUTCDATETIME()
        , x._RowHash                            = d._RowHash
        --
        , x.[object_id]                         = d.[object_id]
        , x.[name]                              = d.[name]
        , x.column_id                           = d.column_id
        , x.system_type_id                      = d.system_type_id
        , x.user_type_id                        = d.user_type_id
        , x.max_length                          = d.max_length
        , x.[precision]                         = d.[precision]
        , x.scale                               = d.scale
        , x.collation_name                      = d.collation_name
        , x.is_nullable                         = d.is_nullable
        , x.is_ansi_padded                      = d.is_ansi_padded
        , x.is_rowguidcol                       = d.is_rowguidcol
        , x.is_identity                         = d.is_identity
        , x.is_filestream                       = d.is_filestream
        , x.is_replicated                       = d.is_replicated
        , x.is_non_sql_subscribed               = d.is_non_sql_subscribed
        , x.is_merge_published                  = d.is_merge_published
        , x.is_dts_replicated                   = d.is_dts_replicated
        , x.is_xml_document                     = d.is_xml_document
        , x.xml_collection_id                   = d.xml_collection_id
        , x.default_object_id                   = d.default_object_id
        , x.rule_object_id                      = d.rule_object_id
        , x.seed_value                          = d.seed_value
        , x.increment_value                     = d.increment_value
        , x.last_value                          = d.last_value
        , x.is_not_for_replication              = d.is_not_for_replication
        , x.is_computed                         = d.is_computed
        , x.is_sparse                           = d.is_sparse
        , x.is_column_set                       = d.is_column_set
        , x.generated_always_type               = d.generated_always_type
        , x.generated_always_type_desc          = d.generated_always_type_desc
        , x.[encryption_type]                   = d.[encryption_type]
        , x.encryption_type_desc                = d.encryption_type_desc
        , x.encryption_algorithm_name           = d.encryption_algorithm_name
        , x.column_encryption_key_id            = d.column_encryption_key_id
        , x.column_encryption_key_database_name = d.column_encryption_key_database_name
        , x.is_hidden                           = d.is_hidden
        , x.is_masked                           = d.is_masked
        , x.graph_type                          = d.graph_type
        , x.graph_type_desc                     = d.graph_type_desc
        , x.is_data_deletion_filter_column      = d.is_data_deletion_filter_column
        , x.ledger_view_column_type             = d.ledger_view_column_type
        , x.ledger_view_column_type_desc        = d.ledger_view_column_type_desc
        , x.is_dropped_ledger_column            = d.is_dropped_ledger_column
    FROM dbo._identity_columns x
        JOIN @output y ON y._ColumnID = x._ColumnID
        JOIN #Dataset d ON d.ID = y.ID
    WHERE x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._identity_columns (_DatabaseID, _ObjectID, _ColumnID, _RowHash
        , [object_id], [name], column_id, system_type_id, user_type_id, max_length, [precision], scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, seed_value, increment_value, last_value, is_not_for_replication, is_computed, is_sparse, is_column_set, generated_always_type, generated_always_type_desc, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, is_hidden, is_masked, graph_type, graph_type_desc, is_data_deletion_filter_column, ledger_view_column_type, ledger_view_column_type_desc, is_dropped_ledger_column)
    SELECT @DatabaseID, y._ObjectID, y._ColumnID, d._RowHash
        , d.[object_id], d.[name], d.column_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.collation_name, d.is_nullable, d.is_ansi_padded, d.is_rowguidcol, d.is_identity, d.is_filestream, d.is_replicated, d.is_non_sql_subscribed, d.is_merge_published, d.is_dts_replicated, d.is_xml_document, d.xml_collection_id, d.default_object_id, d.rule_object_id, d.seed_value, d.increment_value, d.last_value, d.is_not_for_replication, d.is_computed, d.is_sparse, d.is_column_set, d.generated_always_type, d.generated_always_type_desc, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.is_hidden, d.is_masked, d.graph_type, d.graph_type_desc, d.is_data_deletion_filter_column, d.ledger_view_column_type, d.ledger_view_column_type_desc, d.is_dropped_ledger_column
    FROM #Dataset d
        JOIN @output y ON y.ID = d.ID
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._identity_columns x
            WHERE x._ColumnID = y._ColumnID
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

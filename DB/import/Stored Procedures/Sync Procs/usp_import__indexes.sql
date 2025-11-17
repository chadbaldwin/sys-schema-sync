CREATE PROCEDURE import.usp_import__indexes (
    @DatabaseID int,
    @Dataset    import.import__indexes READONLY,
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
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @FullImport_Index = 1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._indexes;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], index_id, [type], [type_desc], is_unique, data_space_id, [ignore_dup_key], is_primary_key, is_unique_constraint, fill_factor, is_padded, is_disabled, is_hypothetical, is_ignored_in_optimization, [allow_row_locks], [allow_page_locks], has_filter, filter_definition, [compression_delay], suppress_dup_key_messages, auto_created, [optimize_for_sequential_key])
        SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[object_id], d.[name], d.index_id, d.[type], d.[type_desc], d.is_unique, d.data_space_id, d.[ignore_dup_key], d.is_primary_key, d.is_unique_constraint, d.fill_factor, d.is_padded, d.is_disabled, d.is_hypothetical, d.is_ignored_in_optimization, d.[allow_row_locks], d.[allow_page_locks], d.has_filter, d.filter_definition, d.[compression_delay], d.suppress_dup_key_messages, d.auto_created, d.[optimize_for_sequential_key]
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._indexes';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._indexes x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ObjectID                     = d._ObjectID
          , x._ModifyDate                   = SYSUTCDATETIME()
          , x._RowHash                      = d._RowHash
          , x.[object_id]                   = d.[object_id]
          , x.[name]                        = d.[name]
          , x.index_id                      = d.index_id
          , x.[type]                        = d.[type]
          , x.[type_desc]                   = d.[type_desc]
          , x.is_unique                     = d.is_unique
          , x.data_space_id                 = d.data_space_id
          , x.[ignore_dup_key]              = d.[ignore_dup_key]
          , x.is_primary_key                = d.is_primary_key
          , x.is_unique_constraint          = d.is_unique_constraint
          , x.fill_factor                   = d.fill_factor
          , x.is_padded                     = d.is_padded
          , x.is_disabled                   = d.is_disabled
          , x.is_hypothetical               = d.is_hypothetical
          , x.is_ignored_in_optimization    = d.is_ignored_in_optimization
          , x.[allow_row_locks]             = d.[allow_row_locks]
          , x.[allow_page_locks]            = d.[allow_page_locks]
          , x.has_filter                    = d.has_filter
          , x.filter_definition             = d.filter_definition
          , x.[compression_delay]           = d.[compression_delay]
          , x.suppress_dup_key_messages     = d.suppress_dup_key_messages
          , x.auto_created                  = d.auto_created
          , x.[optimize_for_sequential_key] = d.[optimize_for_sequential_key]
        FROM dbo._indexes x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._indexes (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], index_id, [type], [type_desc], is_unique, data_space_id, [ignore_dup_key], is_primary_key, is_unique_constraint, fill_factor, is_padded, is_disabled, is_hypothetical, is_ignored_in_optimization, [allow_row_locks], [allow_page_locks], has_filter, filter_definition, [compression_delay], suppress_dup_key_messages, auto_created, [optimize_for_sequential_key])
        SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[object_id], d.[name], d.index_id, d.[type], d.[type_desc], d.is_unique, d.data_space_id, d.[ignore_dup_key], d.is_primary_key, d.is_unique_constraint, d.fill_factor, d.is_padded, d.is_disabled, d.is_hypothetical, d.is_ignored_in_optimization, d.[allow_row_locks], d.[allow_page_locks], d.has_filter, d.filter_definition, d.[compression_delay], d.suppress_dup_key_messages, d.auto_created, d.[optimize_for_sequential_key]
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._indexes x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
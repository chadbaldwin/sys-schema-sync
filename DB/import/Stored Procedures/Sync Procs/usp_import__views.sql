CREATE PROCEDURE import.usp_import__views (
    @DatabaseID int,
    @Dataset    import.import__views READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @rc bigint;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._views;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_replicated, has_replication_filter, has_opaque_metadata, has_unchecked_assembly_data, with_check_option, is_date_correlation_view, is_tracked_by_cdc, has_snapshot, ledger_view_type, ledger_view_type_desc, is_dropped_ledger_view)
        SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_replicated, d.has_replication_filter, d.has_opaque_metadata, d.has_unchecked_assembly_data, d.with_check_option, d.is_date_correlation_view, d.is_tracked_by_cdc, d.has_snapshot, d.ledger_view_type, d.ledger_view_type_desc, d.is_dropped_ledger_view
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._views';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE x FROM dbo._views x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
        UPDATE x
        SET x._ModifyDate                 = SYSUTCDATETIME()
          , x._RowHash                    = d._RowHash
          , x.[name]                      = d.[name]
          , x.[object_id]                 = d.[object_id]
          , x.principal_id                = d.principal_id
          , x.[schema_id]                 = d.[schema_id]
          , x.parent_object_id            = d.parent_object_id
          , x.[type]                      = d.[type]
          , x.[type_desc]                 = d.[type_desc]
          , x.create_date                 = d.create_date
          , x.modify_date                 = d.modify_date
          , x.is_ms_shipped               = d.is_ms_shipped
          , x.is_published                = d.is_published
          , x.is_schema_published         = d.is_schema_published
          , x.is_replicated               = d.is_replicated
          , x.has_replication_filter      = d.has_replication_filter
          , x.has_opaque_metadata         = d.has_opaque_metadata
          , x.has_unchecked_assembly_data = d.has_unchecked_assembly_data
          , x.with_check_option           = d.with_check_option
          , x.is_date_correlation_view    = d.is_date_correlation_view
          , x.is_tracked_by_cdc           = d.is_tracked_by_cdc
          , x.has_snapshot                = d.has_snapshot
          , x.ledger_view_type            = d.ledger_view_type
          , x.ledger_view_type_desc       = d.ledger_view_type_desc
          , x.is_dropped_ledger_view      = d.is_dropped_ledger_view
        FROM dbo._views x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dbo._views (_DatabaseID, _ObjectID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_replicated, has_replication_filter, has_opaque_metadata, has_unchecked_assembly_data, with_check_option, is_date_correlation_view, is_tracked_by_cdc, has_snapshot, ledger_view_type, ledger_view_type_desc, is_dropped_ledger_view)
        SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_replicated, d.has_replication_filter, d.has_opaque_metadata, d.has_unchecked_assembly_data, d.with_check_option, d.is_date_correlation_view, d.is_tracked_by_cdc, d.has_snapshot, d.ledger_view_type, d.ledger_view_type_desc, d.is_dropped_ledger_view
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._views x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
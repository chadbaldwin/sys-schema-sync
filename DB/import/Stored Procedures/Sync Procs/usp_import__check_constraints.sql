CREATE PROCEDURE import.usp_import__check_constraints (
    @DatabaseID int,
    @Dataset    import.import__check_constraints READONLY,
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
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        -- parent object
        DECLARE @ProcessKey2 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, ColumnName)
        SELECT @ProcessKey2, __ID, @DatabaseID, _SchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey2;

        SELECT TOP (0) * INTO #Dataset FROM dbo._check_constraints;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_disabled, is_not_for_replication, is_not_trusted, parent_column_id, [definition], uses_database_collation, is_system_named)
        SELECT @DatabaseID, o._ObjectID, p._ObjectID, p._ColumnID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_disabled, d.is_not_for_replication, d.is_not_trusted, d.parent_column_id, d.[definition], d.uses_database_collation, d.is_system_named
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID
            JOIN import.ItemNameProcess p ON p.ProcessKey = @ProcessKey2 AND p.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1, @ProcessKey2);

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._check_constraints';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._check_constraints x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ParentObjectID         = d._ParentObjectID
          , x._ParentColumnID         = d._ParentColumnID
          , x._ModifyDate             = SYSUTCDATETIME()
          , x._RowHash                = d._RowHash
          , x.[name]                  = d.[name]
          , x.[object_id]             = d.[object_id]
          , x.principal_id            = d.principal_id
          , x.[schema_id]             = d.[schema_id]
          , x.parent_object_id        = d.parent_object_id
          , x.[type]                  = d.[type]
          , x.[type_desc]             = d.[type_desc]
          , x.create_date             = d.create_date
          , x.modify_date             = d.modify_date
          , x.is_ms_shipped           = d.is_ms_shipped
          , x.is_published            = d.is_published
          , x.is_schema_published     = d.is_schema_published
          , x.is_disabled             = d.is_disabled
          , x.is_not_for_replication  = d.is_not_for_replication
          , x.is_not_trusted          = d.is_not_trusted
          , x.parent_column_id        = d.parent_column_id
          , x.[definition]            = d.[definition]
          , x.uses_database_collation = d.uses_database_collation
          , x.is_system_named         = d.is_system_named
        FROM dbo._check_constraints x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._check_constraints (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, is_disabled, is_not_for_replication, is_not_trusted, parent_column_id, [definition], uses_database_collation, is_system_named)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._ParentColumnID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.is_disabled, d.is_not_for_replication, d.is_not_trusted, d.parent_column_id, d.[definition], d.uses_database_collation, d.is_system_named
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._check_constraints x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
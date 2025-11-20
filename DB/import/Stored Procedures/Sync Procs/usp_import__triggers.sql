CREATE PROCEDURE import.usp_import__triggers (
    @DatabaseID int,
    @Dataset    import.import__triggers READONLY,
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
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
        SELECT @ProcessKey2, __ID, @DatabaseID, _SchemaName, _ParentObjectName, _ParentObjectType FROM @Dataset WHERE _ParentObjectName IS NOT NULL;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey2;

        SELECT TOP (0) * INTO #Dataset FROM dbo._triggers;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _RowHash, [name], [object_id], parent_class, parent_class_desc, parent_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_disabled, is_not_for_replication, is_instead_of_trigger)
        SELECT @DatabaseID, o._ObjectID, p._ObjectID, d._RowHash, d.[name], d.[object_id], d.parent_class, d.parent_class_desc, d.parent_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_disabled, d.is_not_for_replication, d.is_instead_of_trigger
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID
            LEFT JOIN import.ItemNameProcess p ON p.ProcessKey = @ProcessKey2 AND p.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1, @ProcessKey2);

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._triggers';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._triggers x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ParentObjectID        = d._ParentObjectID
          , x._ModifyDate            = SYSUTCDATETIME()
          , x._RowHash               = d._RowHash
          , x.[name]                 = d.[name]
          , x.[object_id]            = d.[object_id]
          , x.parent_class           = d.parent_class
          , x.parent_class_desc      = d.parent_class_desc
          , x.parent_id              = d.parent_id
          , x.[type]                 = d.[type]
          , x.[type_desc]            = d.[type_desc]
          , x.create_date            = d.create_date
          , x.modify_date            = d.modify_date
          , x.is_ms_shipped          = d.is_ms_shipped
          , x.is_disabled            = d.is_disabled
          , x.is_not_for_replication = d.is_not_for_replication
          , x.is_instead_of_trigger  = d.is_instead_of_trigger
        FROM dbo._triggers x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._triggers (_DatabaseID, _ObjectID, _ParentObjectID, _RowHash, [name], [object_id], parent_class, parent_class_desc, parent_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_disabled, is_not_for_replication, is_instead_of_trigger)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._RowHash, d.[name], d.[object_id], d.parent_class, d.parent_class_desc, d.parent_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_disabled, d.is_not_for_replication, d.is_instead_of_trigger
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._triggers x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
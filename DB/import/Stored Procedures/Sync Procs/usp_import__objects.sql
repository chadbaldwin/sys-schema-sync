CREATE PROCEDURE import.usp_import__objects (
    @DatabaseID int,
    @Dataset    import.import__objects READONLY,
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

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1, @FullImport_Object = 1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._objects;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _SchemaName, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published)
        SELECT @DatabaseID, o._ObjectID, d._SchemaName, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Done: Get IDs', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._objects';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._objects x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        UPDATE x
        SET x._ModifyDate         = SYSUTCDATETIME()
          , x._RowHash            = d._RowHash
          , x._SchemaName         = d._SchemaName
          , x.[name]              = d.[name]
          , x.[object_id]         = d.[object_id]
          , x.principal_id        = d.principal_id
          , x.[schema_id]         = d.[schema_id]
          , x.parent_object_id    = d.parent_object_id
          , x.[type]              = d.[type]
          , x.[type_desc]         = d.[type_desc]
          , x.create_date         = d.create_date
          , x.is_ms_shipped       = d.is_ms_shipped
          , x.is_published        = d.is_published
          , x.is_schema_published = d.is_schema_published
        FROM dbo._objects x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._objects (_DatabaseID, _ObjectID, _SchemaName, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published)
        SELECT d._DatabaseID, d._ObjectID, d._SchemaName, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._objects x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
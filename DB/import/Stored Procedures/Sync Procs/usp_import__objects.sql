CREATE PROCEDURE import.usp_import__objects (
    @DatabaseID int,
    @Dataset    import.import__objects READONLY,
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
    -- object
    DECLARE @ProcessKey uniqueidentifier = NEWID();

    INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
    SELECT @ProcessKey, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

    EXEC import.usp_CreateItems_Test @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey, @FullImport_Object = 1, @Verbose = @Verbose;

    SELECT TOP (0) * INTO #Dataset FROM dbo._objects;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
    ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
    CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

    INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _SchemaName, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published)
    SELECT @DatabaseID, o._ObjectID, d._SchemaName, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published
    FROM @Dataset d
        JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey AND o.ID = d.__ID;

    DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._objects';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._objects x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
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
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._objects (_DatabaseID, _ObjectID, _SchemaName, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, is_ms_shipped, is_published, is_schema_published)
        SELECT d._DatabaseID, d._ObjectID, d._SchemaName, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.is_ms_shipped, d.is_published, d.is_schema_published
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._objects x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
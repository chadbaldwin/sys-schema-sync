CREATE PROCEDURE import.usp_import__default_constraints (
    @DatabaseID int,
    @Dataset    import.import__default_constraints READONLY,
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
            @output import.ItemName,
            @parent import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;

    DELETE @input;

    -- parent object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, ColumnName)
    SELECT __ID, _SchemaName, _ParentObjectName, _ParentObjectType, _ParentColumnName FROM @Dataset;

    INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._default_constraints';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._default_constraints x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM @output o WHERE o._ObjectID = x._ObjectID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x._ParentObjectID     = p._ObjectID
            , x._ParentColumnID     = p._ColumnID
            , x._ModifyDate         = SYSUTCDATETIME()
            , x._RowHash            = d._RowHash
            --
            , x.[name]              = d.[name]
            , x.[object_id]         = d.[object_id]
            , x.principal_id        = d.principal_id
            , x.[schema_id]         = d.[schema_id]
            , x.parent_object_id    = d.parent_object_id
            , x.[type]              = d.[type]
            , x.[type_desc]         = d.[type_desc]
            , x.create_date         = d.create_date
            , x.modify_date         = d.modify_date
            , x.is_ms_shipped       = d.is_ms_shipped
            , x.is_published        = d.is_published
            , x.is_schema_published = d.is_schema_published
            , x.parent_column_id    = d.parent_column_id
            , x.[definition]        = d.[definition]
            , x.is_system_named     = d.is_system_named
        FROM dbo._default_constraints x
            JOIN @output y ON y._ObjectID = x._ObjectID
            JOIN @Dataset d ON d.__ID = y.ID
            JOIN @parent p ON p.ID = y.ID
        WHERE x._DatabaseID = @DatabaseID
            AND x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._default_constraints (_DatabaseID, _ObjectID, _ParentObjectID, _ParentColumnID, _RowHash
            , [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published
            , parent_column_id, [definition], is_system_named)
        SELECT @DatabaseID, y._ObjectID, p._ObjectID, p._ColumnID, d._RowHash
            , d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published
            , d.parent_column_id, d.[definition], d.is_system_named
        FROM @Dataset d
            JOIN @output y ON y.ID = d.__ID
            JOIN @parent p ON p.ID = d.__ID
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._default_constraints x
                WHERE x._DatabaseID = @DatabaseID
                    AND x._ObjectID  = y._ObjectID
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
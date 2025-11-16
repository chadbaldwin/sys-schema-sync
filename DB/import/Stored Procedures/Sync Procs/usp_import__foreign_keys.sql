CREATE PROCEDURE import.usp_import__foreign_keys (
    @DatabaseID int,
    @Dataset    import.import__foreign_keys READONLY,
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
        DECLARE @input     import.ItemName,
                @output    import.ItemName,
                @parent    import.ItemName,
                @reference import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        DELETE @input;

        -- parent object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _ParentSchemaName, _ParentObjectName, _ParentObjectType FROM @Dataset;

        INSERT @parent (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        DELETE @input;

        -- reference object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
        SELECT __ID, _ReferencedSchemaName, _ReferencedObjectName, _ReferencedObjectType, _ReferencedIndexName FROM @Dataset;

        INSERT @reference (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._foreign_keys;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _ParentObjectID, _ReferencedObjectID, _ReferencedIndexID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, referenced_object_id, key_index_id, is_disabled, is_not_for_replication, is_not_trusted, delete_referential_action, delete_referential_action_desc, update_referential_action, update_referential_action_desc, is_system_named)
        SELECT @DatabaseID, o._ObjectID, p._ObjectID, r._ObjectID, r._IndexID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.referenced_object_id, d.key_index_id, d.is_disabled, d.is_not_for_replication, d.is_not_trusted, d.delete_referential_action, d.delete_referential_action_desc, d.update_referential_action, d.update_referential_action_desc, d.is_system_named
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID
            JOIN @parent p ON p.ID = d.__ID
            JOIN @reference r ON r.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._foreign_keys';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE x FROM dbo._foreign_keys x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
        UPDATE x
        SET x._ParentObjectID                = d._ParentObjectID
          , x._ReferencedObjectID            = d._ReferencedObjectID
          , x._ReferencedIndexID             = d._ReferencedIndexID
          , x._ModifyDate                    = SYSUTCDATETIME()
          , x._RowHash                       = d._RowHash
          , x.[name]                         = d.[name]
          , x.[object_id]                    = d.[object_id]
          , x.principal_id                   = d.principal_id
          , x.[schema_id]                    = d.[schema_id]
          , x.parent_object_id               = d.parent_object_id
          , x.[type]                         = d.[type]
          , x.[type_desc]                    = d.[type_desc]
          , x.create_date                    = d.create_date
          , x.modify_date                    = d.modify_date
          , x.is_ms_shipped                  = d.is_ms_shipped
          , x.is_published                   = d.is_published
          , x.is_schema_published            = d.is_schema_published
          , x.referenced_object_id           = d.referenced_object_id
          , x.key_index_id                   = d.key_index_id
          , x.is_disabled                    = d.is_disabled
          , x.is_not_for_replication         = d.is_not_for_replication
          , x.is_not_trusted                 = d.is_not_trusted
          , x.delete_referential_action      = d.delete_referential_action
          , x.delete_referential_action_desc = d.delete_referential_action_desc
          , x.update_referential_action      = d.update_referential_action
          , x.update_referential_action_desc = d.update_referential_action_desc
          , x.is_system_named                = d.is_system_named
        FROM dbo._foreign_keys x
            JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID
        WHERE x._RowHash <> d._RowHash;
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dbo._foreign_keys (_DatabaseID, _ObjectID, _ParentObjectID, _ReferencedObjectID, _ReferencedIndexID, _RowHash, [name], [object_id], principal_id, [schema_id], parent_object_id, [type], [type_desc], create_date, modify_date, is_ms_shipped, is_published, is_schema_published, referenced_object_id, key_index_id, is_disabled, is_not_for_replication, is_not_trusted, delete_referential_action, delete_referential_action_desc, update_referential_action, update_referential_action_desc, is_system_named)
        SELECT d._DatabaseID, d._ObjectID, d._ParentObjectID, d._ReferencedObjectID, d._ReferencedIndexID, d._RowHash, d.[name], d.[object_id], d.principal_id, d.[schema_id], d.parent_object_id, d.[type], d.[type_desc], d.create_date, d.modify_date, d.is_ms_shipped, d.is_published, d.is_schema_published, d.referenced_object_id, d.key_index_id, d.is_disabled, d.is_not_for_replication, d.is_not_trusted, d.delete_referential_action, d.delete_referential_action_desc, d.update_referential_action, d.update_referential_action_desc, d.is_system_named
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._foreign_keys x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
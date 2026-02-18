CREATE PROCEDURE import.usp_import__parameters (
    @DatabaseID int,
    @Dataset    import.import__parameters READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@DatabaseID IS NULL) BEGIN; THROW 51000, 'Required parameter @DatabaseID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            -- base object
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DECLARE @ProcessKey1 uniqueidentifier = NEWID();
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._parameters;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, parameter_id);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, [object_id], [name], parameter_id, system_type_id, user_type_id, max_length, [precision], scale, is_output, is_cursor_ref, has_default_value, is_xml_document, default_value, xml_collection_id, is_readonly, is_nullable, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, vector_dimensions, vector_base_type, vector_base_type_desc)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.[object_id], d.[name], d.parameter_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.is_output, d.is_cursor_ref, d.has_default_value, d.is_xml_document, d.default_value, d.xml_collection_id, d.is_readonly, d.is_nullable, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.vector_dimensions, d.vector_base_type, d.vector_base_type_desc
            FROM @Dataset d
                JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = 'import.ItemNameProcess';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE import.ItemNameProcess WHERE ProcessKey IN (@ProcessKey1);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._parameters';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._parameters x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.parameter_id = x.parameter_id);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ModifyDate                         = SYSUTCDATETIME()
              , x._RowHash                            = d._RowHash
              , x.[object_id]                         = d.[object_id]
              , x.[name]                              = d.[name]
              , x.system_type_id                      = d.system_type_id
              , x.user_type_id                        = d.user_type_id
              , x.max_length                          = d.max_length
              , x.[precision]                         = d.[precision]
              , x.scale                               = d.scale
              , x.is_output                           = d.is_output
              , x.is_cursor_ref                       = d.is_cursor_ref
              , x.has_default_value                   = d.has_default_value
              , x.is_xml_document                     = d.is_xml_document
              , x.default_value                       = d.default_value
              , x.xml_collection_id                   = d.xml_collection_id
              , x.is_readonly                         = d.is_readonly
              , x.is_nullable                         = d.is_nullable
              , x.[encryption_type]                   = d.[encryption_type]
              , x.encryption_type_desc                = d.encryption_type_desc
              , x.encryption_algorithm_name           = d.encryption_algorithm_name
              , x.column_encryption_key_id            = d.column_encryption_key_id
              , x.column_encryption_key_database_name = d.column_encryption_key_database_name
              , x.vector_dimensions                   = d.vector_dimensions
              , x.vector_base_type                    = d.vector_base_type
              , x.vector_base_type_desc               = d.vector_base_type_desc
            FROM dbo._parameters x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.parameter_id = x.parameter_id
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._parameters (_DatabaseID, _ObjectID, _RowHash, [object_id], [name], parameter_id, system_type_id, user_type_id, max_length, [precision], scale, is_output, is_cursor_ref, has_default_value, is_xml_document, default_value, xml_collection_id, is_readonly, is_nullable, [encryption_type], encryption_type_desc, encryption_algorithm_name, column_encryption_key_id, column_encryption_key_database_name, vector_dimensions, vector_base_type, vector_base_type_desc)
            SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.[object_id], d.[name], d.parameter_id, d.system_type_id, d.user_type_id, d.max_length, d.[precision], d.scale, d.is_output, d.is_cursor_ref, d.has_default_value, d.is_xml_document, d.default_value, d.xml_collection_id, d.is_readonly, d.is_nullable, d.[encryption_type], d.encryption_type_desc, d.encryption_algorithm_name, d.column_encryption_key_id, d.column_encryption_key_database_name, d.vector_dimensions, d.vector_base_type, d.vector_base_type_desc
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._parameters x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.parameter_id = x.parameter_id);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
GO
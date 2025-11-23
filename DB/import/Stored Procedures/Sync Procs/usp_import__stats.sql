CREATE PROCEDURE import.usp_import__stats (
    @DatabaseID int,
    @Dataset    import.import__stats READONLY,
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
            INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType, IndexName)
            SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;
            ----------------------------------------

            ----------------------------------------
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            SELECT TOP (0) * INTO #Dataset FROM dbo._stats;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _IndexID);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], stats_id, auto_created, user_created, no_recompute, has_filter, filter_definition, is_temporary, is_incremental, has_persisted_sample, stats_generation_method, stats_generation_method_desc, auto_drop, replica_role_id, replica_role_desc, replica_name)
            SELECT @DatabaseID, o._ObjectID, o._IndexID, d._RowHash, d.[object_id], d.[name], d.stats_id, d.auto_created, d.user_created, d.no_recompute, d.has_filter, d.filter_definition, d.is_temporary, d.is_incremental, d.has_persisted_sample, d.stats_generation_method, d.stats_generation_method_desc, d.auto_drop, d.replica_role_id, d.replica_role_desc, d.replica_name
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
            SET @TableName = N'dbo._stats';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._stats x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ObjectID                    = d._ObjectID
              , x._ModifyDate                  = SYSUTCDATETIME()
              , x._RowHash                     = d._RowHash
              , x.[object_id]                  = d.[object_id]
              , x.[name]                       = d.[name]
              , x.stats_id                     = d.stats_id
              , x.auto_created                 = d.auto_created
              , x.user_created                 = d.user_created
              , x.no_recompute                 = d.no_recompute
              , x.has_filter                   = d.has_filter
              , x.filter_definition            = d.filter_definition
              , x.is_temporary                 = d.is_temporary
              , x.is_incremental               = d.is_incremental
              , x.has_persisted_sample         = d.has_persisted_sample
              , x.stats_generation_method      = d.stats_generation_method
              , x.stats_generation_method_desc = d.stats_generation_method_desc
              , x.auto_drop                    = d.auto_drop
              , x.replica_role_id              = d.replica_role_id
              , x.replica_role_desc            = d.replica_role_desc
              , x.replica_name                 = d.replica_name
            FROM dbo._stats x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._stats (_DatabaseID, _ObjectID, _IndexID, _RowHash, [object_id], [name], stats_id, auto_created, user_created, no_recompute, has_filter, filter_definition, is_temporary, is_incremental, has_persisted_sample, stats_generation_method, stats_generation_method_desc, auto_drop, replica_role_id, replica_role_desc, replica_name)
            SELECT d._DatabaseID, d._ObjectID, d._IndexID, d._RowHash, d.[object_id], d.[name], d.stats_id, d.auto_created, d.user_created, d.no_recompute, d.has_filter, d.filter_definition, d.is_temporary, d.is_incremental, d.has_persisted_sample, d.stats_generation_method, d.stats_generation_method_desc, d.auto_drop, d.replica_role_id, d.replica_role_desc, d.replica_name
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._stats x WHERE d._DatabaseID = x._DatabaseID AND d._IndexID = x._IndexID);
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
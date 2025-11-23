CREATE PROCEDURE import.usp_import__sysarticles (
    @DatabaseID int,
    @Dataset    import.import__sysarticles READONLY,
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
            SELECT TOP (0) * INTO #Dataset FROM dbo._sysarticles;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, artid);

            INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
            SELECT @DatabaseID, o._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
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
            SET @TableName = N'dbo._sysarticles';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._sysarticles x
            WHERE x._DatabaseID = @DatabaseID
                AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            UPDATE x
            SET x._ModifyDate               = SYSUTCDATETIME()
              , x._RowHash                  = d._RowHash
              , x.creation_script           = d.creation_script
              , x.del_cmd                   = d.del_cmd
              , x.[description]             = d.[description]
              , x.dest_table                = d.dest_table
              , x.[filter]                  = d.[filter]
              , x.filter_clause             = d.filter_clause
              , x.ins_cmd                   = d.ins_cmd
              , x.[name]                    = d.[name]
              , x.[objid]                   = d.[objid]
              , x.pubid                     = d.pubid
              , x.pre_creation_cmd          = d.pre_creation_cmd
              , x.[status]                  = d.[status]
              , x.sync_objid                = d.sync_objid
              , x.[type]                    = d.[type]
              , x.upd_cmd                   = d.upd_cmd
              , x.schema_option             = d.schema_option
              , x.dest_owner                = d.dest_owner
              , x.ins_scripting_proc        = d.ins_scripting_proc
              , x.del_scripting_proc        = d.del_scripting_proc
              , x.upd_scripting_proc        = d.upd_scripting_proc
              , x.custom_script             = d.custom_script
              , x.fire_triggers_on_snapshot = d.fire_triggers_on_snapshot
            FROM dbo._sysarticles x
                JOIN #Dataset d ON d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid
            WHERE x._RowHash <> d._RowHash;
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._sysarticles (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
            SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM dbo._sysarticles x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
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
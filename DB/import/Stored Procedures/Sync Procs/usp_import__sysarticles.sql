CREATE PROCEDURE import.usp_import__sysarticles (
    @DatabaseID int,
    @Dataset    import.import__sysarticles READONLY,
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
         EXEC dbo.usp_Raiserror '[%s] Get IDs: Start', NULL, NULL, @ProcName; SET @sw2 = SYSUTCDATETIME();

        -- object
        DECLARE @ProcessKey1 uniqueidentifier = NEWID();
        INSERT import.ItemNameProcess (ProcessKey, ID, _DatabaseID, SchemaName, ObjectName, ObjectType)
        SELECT @ProcessKey1, __ID, @DatabaseID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @ProcessKey = @ProcessKey1;

        SELECT TOP (0) * INTO #Dataset FROM dbo._sysarticles;
        EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo';
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, artid);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
        SELECT @DatabaseID, o._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
        FROM @Dataset d
            JOIN import.ItemNameProcess o ON o.ProcessKey = @ProcessKey1 AND o.ID = d.__ID;

        DELETE import.ItemNameProcess WHERE ProcessKey = @ProcessKey1;

        EXEC dbo.usp_Raiserror '[%s] Get IDs: Done', @sw2, @@ROWCOUNT, @ProcName;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._sysarticles';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._sysarticles x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._sysarticles (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
        SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._sysarticles x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
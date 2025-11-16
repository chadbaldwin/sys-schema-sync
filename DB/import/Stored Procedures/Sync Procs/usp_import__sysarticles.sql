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

    DECLARE @sw datetime2 = SYSUTCDATETIME(), @rc bigint;
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    EXEC dbo.usp_Raiserror '[%s] Start', @s1 = @ProcName;

    IF (@DatabaseID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @DatabaseID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN;
        DECLARE @input  import.ItemName,
                @output import.ItemName;

        -- object
        INSERT @input (ID, SchemaName, ObjectName, ObjectType)
        SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

        INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
        EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input;

        SELECT TOP (0) * INTO #Dataset FROM dbo._sysarticles;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ModifyDate;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidFrom;
        ALTER TABLE #Dataset DROP COLUMN IF EXISTS _ValidTo;
        CREATE CLUSTERED INDEX CIX ON #Dataset (_DatabaseID, _ObjectID, artid);

        INSERT #Dataset WITH(TABLOCK) (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
        SELECT @DatabaseID, o._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
        FROM @Dataset d
            JOIN @output o ON o.ID = d.__ID;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._sysarticles';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE x FROM dbo._sysarticles x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM #Dataset d WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dbo._sysarticles (_DatabaseID, _ObjectID, _RowHash, artid, creation_script, del_cmd, [description], dest_table, [filter], filter_clause, ins_cmd, [name], [objid], pubid, pre_creation_cmd, [status], sync_objid, [type], upd_cmd, schema_option, dest_owner, ins_scripting_proc, del_scripting_proc, upd_scripting_proc, custom_script, fire_triggers_on_snapshot)
        SELECT d._DatabaseID, d._ObjectID, d._RowHash, d.artid, d.creation_script, d.del_cmd, d.[description], d.dest_table, d.[filter], d.filter_clause, d.ins_cmd, d.[name], d.[objid], d.pubid, d.pre_creation_cmd, d.[status], d.sync_objid, d.[type], d.upd_cmd, d.schema_option, d.dest_owner, d.ins_scripting_proc, d.del_scripting_proc, d.upd_scripting_proc, d.custom_script, d.fire_triggers_on_snapshot
        FROM #Dataset d
        WHERE NOT EXISTS (SELECT * FROM dbo._sysarticles x WHERE d._DatabaseID = x._DatabaseID AND d._ObjectID = x._ObjectID AND d.artid = x.artid);
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
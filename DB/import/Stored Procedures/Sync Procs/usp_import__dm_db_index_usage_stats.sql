CREATE PROCEDURE import.usp_import__dm_db_index_usage_stats (
    @DatabaseID int,
    @Dataset    import.import__dm_db_index_usage_stats READONLY,
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
            @output import.ItemName;

    -- object
    INSERT @input (ID, SchemaName, ObjectName, ObjectType, IndexName)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType, _IndexName FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._dm_db_index_usage_stats';

        /*  Deletes here are okay because the export query left joins to sys.dm_db_index_usage_stats
            so it will always return every index. The only time indexes will be deleted is when
            they have been completely dropped from the database and never re-created. */
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._dm_db_index_usage_stats x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM @output o WHERE o._IndexID = x._IndexID);
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x._ModifyDate            = SYSUTCDATETIME()
            , x._RowHash               = d._RowHash
            --
            , x.database_id             = d.database_id
            , x.[object_id]             = d.[object_id]
            , x.index_id                = d.index_id
            , x.user_seeks              = d.user_seeks
            , x.user_scans              = d.user_scans
            , x.user_lookups            = d.user_lookups
            , x.user_updates            = d.user_updates
            , x.last_user_seek_utc      = COALESCE(d.last_user_seek_utc, x.last_user_seek_utc)
            , x.last_user_scan_utc      = COALESCE(d.last_user_scan_utc, x.last_user_scan_utc)
            , x.last_user_lookup_utc    = COALESCE(d.last_user_lookup_utc, x.last_user_lookup_utc)
            , x.last_user_update_utc    = COALESCE(d.last_user_update_utc, x.last_user_update_utc)
            , x.system_seeks            = d.system_seeks
            , x.system_scans            = d.system_scans
            , x.system_lookups          = d.system_lookups
            , x.system_updates          = d.system_updates
            , x.last_system_seek_utc    = COALESCE(d.last_system_seek_utc, x.last_system_seek_utc)
            , x.last_system_scan_utc    = COALESCE(d.last_system_scan_utc, x.last_system_scan_utc)
            , x.last_system_lookup_utc  = COALESCE(d.last_system_lookup_utc, x.last_system_lookup_utc)
            , x.last_system_update_utc  = COALESCE(d.last_system_update_utc, x.last_system_update_utc)
        FROM dbo._dm_db_index_usage_stats x
            JOIN @output y ON y._IndexID = x._IndexID
        WHERE x._DatabaseID = @DatabaseID
            AND x._RowHash <> d._RowHash;
            JOIN @Dataset d ON d.__ID = y.ID
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._dm_db_index_usage_stats (_DatabaseID, _ObjectID, _IndexID, _RowHash
            , database_id, [object_id], index_id, user_seeks, user_scans, user_lookups, user_updates, last_user_seek_utc, last_user_scan_utc, last_user_lookup_utc, last_user_update_utc, system_seeks, system_scans, system_lookups, system_updates, last_system_seek_utc, last_system_scan_utc, last_system_lookup_utc, last_system_update_utc)
        SELECT @DatabaseID, y._ObjectID, y._IndexID, d._RowHash
            , d.database_id, d.[object_id], d.index_id, d.user_seeks, d.user_scans, d.user_lookups, d.user_updates, d.last_user_seek_utc, d.last_user_scan_utc, d.last_user_lookup_utc, d.last_user_update_utc, d.system_seeks, d.system_scans, d.system_lookups, d.system_updates, d.last_system_seek_utc, d.last_system_scan_utc, d.last_system_lookup_utc, d.last_system_update_utc
        FROM @Dataset d
            JOIN @output y ON y.ID = d.__ID
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._dm_db_index_usage_stats x
                WHERE x._DatabaseID = @DatabaseID
                    AND x._IndexID  = y._IndexID
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
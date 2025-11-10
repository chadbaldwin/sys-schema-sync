CREATE PROCEDURE import.usp_import__missing_indexes (
    @DatabaseID int,
    @Dataset    import.import__missing_indexes READONLY,
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
    INSERT @input (ID, SchemaName, ObjectName, ObjectType)
    SELECT __ID, _SchemaName, _ObjectName, _ObjectType FROM @Dataset;

    INSERT @output (ID, SchemaName, ObjectName, ObjectType, IndexName, ColumnName, _ObjectID, _IndexID, _ColumnID)
    EXEC import.usp_CreateItems @DatabaseID = @DatabaseID, @Dataset = @input, @Verbose = @Verbose;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._missing_indexes';

        /* -- Not doing standard delete for now
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x FROM dbo._missing_indexes x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (
                SELECT *
                FROM @Dataset d
                    JOIN @output o ON o.ID = d.__ID
                WHERE o._ObjectID = x._ObjectID
                    AND x.missing_index_hash = d.missing_index_hash
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
        */

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x._ModifyDate         = SYSUTCDATETIME()
            , x._RowHash            = d._RowHash
            --
            , x.unique_compiles     = d.unique_compiles
            , x.user_seeks          = d.user_seeks
            , x.user_scans          = d.user_scans
            , x.last_user_seek_utc  = d.last_user_seek_utc
            , x.last_user_scan_utc  = d.last_user_scan_utc
            , x.avg_total_user_cost = d.avg_total_user_cost
            , x.avg_user_impact     = d.avg_user_impact
            /* Technically, these should never change because the missing_index_hash is a hash of these columns.
               BUT, these columns are a straight pass-thru and their order could change, so we update anyway */
            , x.equality_columns    = d.equality_columns
            , x.inequality_columns  = d.inequality_columns
            , x.included_columns    = d.included_columns
        FROM dbo._missing_indexes x
            JOIN @output y ON y._ObjectID = x._ObjectID
            JOIN @Dataset d ON d.__ID = y.ID AND d.missing_index_hash = x.missing_index_hash
        WHERE x._DatabaseID = @DatabaseID
            AND x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._missing_indexes (_DatabaseID, _ObjectID, _RowHash
            , missing_index_hash, unique_compiles, user_seeks, user_scans, last_user_seek_utc, last_user_scan_utc, avg_total_user_cost, avg_user_impact, equality_columns, inequality_columns, included_columns, column_data)
        SELECT @DatabaseID, y._ObjectID, d._RowHash
            , d.missing_index_hash, d.unique_compiles, d.user_seeks, d.user_scans, d.last_user_seek_utc, d.last_user_scan_utc, d.avg_total_user_cost, d.avg_user_impact, d.equality_columns, d.inequality_columns, d.included_columns, d.column_data
        FROM @Dataset d
            JOIN @output y ON y.ID = d.__ID
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._missing_indexes x
                WHERE x._DatabaseID = @DatabaseID
                    AND x._ObjectID = y._ObjectID
                    AND x.missing_index_hash = d.missing_index_hash
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        -- Instead of standard deletes, just do simple time based pruning
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x
        FROM dbo._missing_indexes x
        WHERE x._DatabaseID = @DatabaseID
            AND x._ModifyDate < DATEADD(DAY, -30, SYSUTCDATETIME());
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
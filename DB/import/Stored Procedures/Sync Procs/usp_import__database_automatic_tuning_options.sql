CREATE PROCEDURE import.usp_import__database_automatic_tuning_options (
    @DatabaseID int,
    @Dataset    import.import__database_automatic_tuning_options READONLY,
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
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._database_automatic_tuning_options';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x
        FROM dbo._database_automatic_tuning_options x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.[name] = x.[name])
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x._ModifyDate        = SYSUTCDATETIME()
            , x._RowHash           = d._RowHash
            --
            , x.[name]             = d.[name]
            , x.[desired_state]    = d.[desired_state]
            , x.desired_state_desc = d.desired_state_desc
            , x.actual_state       = d.actual_state
            , x.actual_state_desc  = d.actual_state_desc
            , x.reason             = d.reason
            , x.reason_desc        = d.reason_desc
        FROM dbo._database_automatic_tuning_options x
            JOIN @Dataset d ON d.[name] = x.[name]
        WHERE x._DatabaseID = @DatabaseID
            AND x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._database_automatic_tuning_options (_DatabaseID, _RowHash, [name], [desired_state], desired_state_desc, actual_state, actual_state_desc, reason, reason_desc)
        SELECT @DatabaseID, d._RowHash, d.[name], d.[desired_state], d.desired_state_desc, d.actual_state, d.actual_state_desc, d.reason, d.reason_desc
        FROM @Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._database_automatic_tuning_options x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.[name] = d.[name]
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
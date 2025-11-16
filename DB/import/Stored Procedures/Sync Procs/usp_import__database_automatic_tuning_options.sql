CREATE PROCEDURE import.usp_import__database_automatic_tuning_options (
    @DatabaseID int,
    @Dataset    import.import__database_automatic_tuning_options READONLY,
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
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._database_automatic_tuning_options';

        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Start', @s1 = @ProcName, @s2 = @tableName;
        DELETE x FROM dbo._database_automatic_tuning_options x
        WHERE x._DatabaseID = @DatabaseID
            AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.[name] = x.[name]);
        EXEC dbo.usp_Raiserror '[%s] [%s] Delete: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Start', @s1 = @ProcName, @s2 = @tableName;
        UPDATE x
        SET x._ModifyDate        = SYSUTCDATETIME()
          , x._RowHash           = d._RowHash
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Update: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Start', @s1 = @ProcName, @s2 = @tableName;
        INSERT dbo._database_automatic_tuning_options (_DatabaseID, _RowHash, [name], [desired_state], desired_state_desc, actual_state, actual_state_desc, reason, reason_desc)
        SELECT @DatabaseID, d._RowHash, d.[name], d.[desired_state], d.desired_state_desc, d.actual_state, d.actual_state_desc, d.reason, d.reason_desc
        FROM @Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._database_automatic_tuning_options x
                WHERE x._DatabaseID = @DatabaseID
                    AND x.[name] = d.[name]
            );
        EXEC dbo.usp_Raiserror '[%s] [%s] Insert: Done', @rc = @@ROWCOUNT, @s1 = @ProcName, @s2 = @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @ts = @sw, @s1 = @ProcName;
END;
GO
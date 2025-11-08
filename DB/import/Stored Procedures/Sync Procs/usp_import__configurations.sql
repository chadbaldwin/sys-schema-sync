CREATE PROCEDURE import.usp_import__configurations (
    @InstanceID int,
    @Dataset    import.import__configurations READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    IF (@Verbose = 1) RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._configurations';

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        DELETE x
        FROM dbo._configurations x
        WHERE x._InstanceID = @InstanceID
            AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.configuration_id = x.configuration_id)
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        UPDATE x
        SET   x._ModifyDate      = SYSUTCDATETIME()
            , x._RowHash         = d._RowHash
            --
            , x.configuration_id = d.configuration_id
            , x.[name]           = d.[name]
            , x.[value]          = d.[value]
            , x.minimum          = d.minimum
            , x.maximum          = d.maximum
            , x.value_in_use     = d.value_in_use
            , x.[description]    = d.[description]
            , x.is_dynamic       = d.is_dynamic
            , x.is_advanced      = d.is_advanced
        FROM dbo._configurations x
            JOIN @Dataset d ON d.configuration_id = x.configuration_id
        WHERE x._InstanceID = @InstanceID
            AND x._RowHash <> d._RowHash;
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
        INSERT dbo._configurations (_InstanceID, _RowHash, configuration_id, [name], [value], minimum, maximum, value_in_use, [description], is_dynamic, is_advanced)
        SELECT @InstanceID, d._RowHash, d.configuration_id, d.[name], d.[value], d.minimum, d.maximum, d.value_in_use, d.[description], d.is_dynamic, d.is_advanced
        FROM @Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._configurations x
                WHERE x._InstanceID = @InstanceID
                    AND x.configuration_id = d.configuration_id
            );
        IF (@Verbose = 1) RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @duration varchar(15) = FORMAT(DATEADD(microsecond, DATEDIFF(microsecond, @sw, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff');
    IF (@Verbose = 1) RAISERROR('[%s] Done [%s]',0,1,@ProcName, @duration) WITH NOWAIT;
END;
GO
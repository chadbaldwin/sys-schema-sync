CREATE PROCEDURE import.usp_import__configurations (
    @InstanceID int,
    @Dataset    import.import__configurations READONLY,
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

    IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        DECLARE @tableName nvarchar(128) = N'dbo._configurations';

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        DELETE x FROM dbo._configurations x
        WHERE x._InstanceID = @InstanceID
            AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.configuration_id = x.configuration_id);
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
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
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @tableName;

        EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @tableName; SET @sw2 = SYSUTCDATETIME();
        INSERT dbo._configurations (_InstanceID, _RowHash, configuration_id, [name], [value], minimum, maximum, value_in_use, [description], is_dynamic, is_advanced)
        SELECT @InstanceID, d._RowHash, d.configuration_id, d.[name], d.[value], d.minimum, d.maximum, d.value_in_use, d.[description], d.is_dynamic, d.is_advanced
        FROM @Dataset d
        WHERE NOT EXISTS (
                SELECT *
                FROM dbo._configurations x
                WHERE x._InstanceID = @InstanceID
                    AND x.configuration_id = d.configuration_id
            );
        EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @tableName;
    COMMIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    EXEC dbo.usp_Raiserror '[%s] Done', @sw, NULL, @ProcName;
END;
GO
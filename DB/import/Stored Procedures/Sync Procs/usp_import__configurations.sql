CREATE PROC import.usp_import__configurations (
    @InstanceID int,
    @Dataset    import.import__configurations READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;
    EXEC sp_set_session_context N'Verbose', @Verbose;
    EXEC sp_set_session_context N'_InstanceID', @InstanceID;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME(), @sw2 datetime2, @TableName nvarchar(300);
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;
        IF (@InstanceID IS NULL) BEGIN; THROW 51000, 'Required parameter @InstanceID is NULL', 1; END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN TRAN;
            SET @TableName = N'dbo._configurations';

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            DELETE x FROM dbo._configurations x
            WHERE x._InstanceID = @InstanceID
                AND NOT EXISTS (SELECT * FROM @Dataset d WHERE d.configuration_id = x.configuration_id);
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
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
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw2, @@ROWCOUNT, @ProcName, @TableName;

            EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @ProcName, @TableName; SET @sw2 = SYSUTCDATETIME();
            INSERT dbo._configurations (_InstanceID, _RowHash, configuration_id, [name], [value], minimum, maximum, value_in_use, [description], is_dynamic, is_advanced)
            SELECT @InstanceID, d._RowHash, d.configuration_id, d.[name], d.[value], d.minimum, d.maximum, d.value_in_use, d.[description], d.is_dynamic, d.is_advanced
            FROM @Dataset d
            WHERE NOT EXISTS (
                    SELECT *
                    FROM dbo._configurations x
                    WHERE x._InstanceID = @InstanceID
                        AND x.configuration_id = d.configuration_id
                );
            EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw2, @@ROWCOUNT, @ProcName, @TableName;
        COMMIT;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @proc_sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @proc_sw, NULL, @ProcName, @ErrorMessage;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
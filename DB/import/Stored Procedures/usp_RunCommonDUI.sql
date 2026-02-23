CREATE PROC import.usp_RunCommonDUI (
    @InstanceID      int = NULL,
    @DatabaseID      int = NULL,
    @CallingProcName nvarchar(500),
    @TargetTable     nvarchar(300),
    @DeletesEnabled  bit = 1,
    @WhatIf          bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    DECLARE @proc_sw datetime2 = SYSUTCDATETIME();
    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));

    BEGIN TRY
        EXEC dbo.usp_Raiserror '[%s] Start: Import Proc', NULL, NULL, @ProcName;

        IF (COALESCE(@InstanceID, @DatabaseID) IS NULL AND @DeletesEnabled = 1)
        BEGIN;
            THROW 51000, 'Either @InstanceID or @DatabaseID must be provided when deletes are enabled', 1;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        DECLARE @ObjectID               int = OBJECT_ID(@TargetTable),
                @FQON                   nvarchar(300),
                @JoinPredicates         nvarchar(MAX),
                @UpdateSet              nvarchar(MAX),
                @InsertColumnList       nvarchar(MAX),
                @InsertColumnSelectList nvarchar(MAX);

        IF (@ObjectID IS NULL)
        BEGIN;
            THROW 50000, 'Table name supplied to @TargetTable was not found.', 1;
        END;

        SELECT @FQON = CONCAT(QUOTENAME(SCHEMA_NAME(o.[schema_id])), '.', QUOTENAME(o.[name]))
        FROM sys.objects o
        WHERE o.[object_id] = @ObjectID;
        ----------------------------------------

        ----------------------------------------
        CREATE TABLE #join_columns (
            key_ordinal int           NOT NULL,
            column_id   int           NOT NULL,
            [name]      nvarchar(128) NOT NULL,
        );

        INSERT #join_columns WITH(TABLOCK) (key_ordinal, column_id, [name])
        SELECT ic.key_ordinal, ic.column_id, c.[name]
        FROM sys.objects o
            JOIN sys.indexes i ON i.[object_id] = o.[object_id]
            JOIN sys.index_columns ic ON ic.[object_id] = o.[object_id] AND ic.index_id = i.index_id
            JOIN sys.columns c ON c.[object_id] = o.[object_id] AND c.column_id = ic.column_id
        WHERE o.[object_id] = @ObjectID
            AND i.index_id = 1
            AND i.is_unique = 1;

        IF (@@ROWCOUNT = 0)
        BEGIN;
            THROW 50001, 'No unique clustered index found on target table. A unique clustered index is required to use this method.', 1;
        END;

        SELECT @JoinPredicates = STRING_AGG(CONCAT('d.', QUOTENAME([name]), ' = x.', QUOTENAME([name])), N' AND ') WITHIN GROUP (ORDER BY key_ordinal)
        FROM #join_columns
        ----------------------------------------

        ----------------------------------------
        SELECT c.column_id
            , UpdateLine  = CONCAT('x.', x.ColName, SPACE(MAX(LEN(x.ColName)) OVER () - LEN(x.ColName)), ' = ', IIF(c.[name] = '_ModifyDate', 'SYSUTCDATETIME()', 'd.'+x.ColName))
            , InsertCol    = x.ColName
            , InsertSelect = 'd.'+x.ColName
            , ExcludeFromUpdate = CONVERT(bit, IIF(c.[name] IN ('_InsertDate'               , '_ValidFrom', '_ValidTo') OR c.[name] IN (SELECT [name] FROM #join_columns), 1, 0))
            , ExcludeFromInsert = CONVERT(bit, IIF(c.[name] IN ('_InsertDate', '_ModifyDate', '_ValidFrom', '_ValidTo'), 1, 0))
        INTO #tmpCols
        FROM sys.objects o
            JOIN sys.columns c ON c.[object_id] = o.[object_id]
            CROSS APPLY (SELECT ColName = QUOTENAME(c.[name])) x
        WHERE o.[object_id] = @ObjectID;

        SELECT @UpdateSet             = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromUpdate = 1, NULL, c.UpdateLine)), CHAR(13)+CHAR(10)+N'                  , ') WITHIN GROUP (ORDER BY c.column_id)
            , @InsertColumnList       = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertCol))   , N', ') WITHIN GROUP (ORDER BY c.column_id)
            , @InsertColumnSelectList = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertSelect)), N', ') WITHIN GROUP (ORDER BY c.column_id)
        FROM #tmpCols c;
        ----------------------------------------

        ----------------------------------------
        -- Prepare delete script
        ----------------------------------------
        IF (@DeletesEnabled = 1)
        BEGIN;
            DECLARE @template_delete nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
                DELETE x
                FROM {{FQON}} x
                WHERE NOT EXISTS (SELECT * FROM #Dataset d WHERE {{JoinPredicates}})
                    {{InstanceIDFilter}}
                    {{DatabaseIDFilter}}
                ;
            ');

            SELECT @template_delete = REPLACE(@template_delete, '{{FQON}}'          , @FQON)
                ,  @template_delete = REPLACE(@template_delete, '{{JoinPredicates}}', @JoinPredicates)
                --
                ,  @template_delete = REPLACE(@template_delete, '{{InstanceIDFilter}}', IIF(@InstanceID IS NOT NULL, 'AND x.[_InstanceID] = @InstanceID', ''))
                ,  @template_delete = REPLACE(@template_delete, '{{DatabaseIDFilter}}', IIF(@DatabaseID IS NOT NULL, 'AND x.[_DatabaseID] = @DatabaseID', ''));
        END;
        ----------------------------------------

        ----------------------------------------
        -- Prepare update script
        ----------------------------------------
        DECLARE @template_update nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
            UPDATE x
            SET {{UpdateSet}}
            FROM {{FQON}} x
                JOIN #Dataset d ON {{JoinPredicates}}
            WHERE 1=1
                {{RowHashCompare}}
            ;
        ');

        -- If _RowHash doesn't exist, then every row will be updated whether there are changes or not.
        -- Typically used by the delta table feeds since we want to record snapshots even when the row hasn't changed.
        SELECT @template_update = REPLACE(@template_update, '{{FQON}}'          , @FQON)
            ,  @template_update = REPLACE(@template_update, '{{JoinPredicates}}', @JoinPredicates)
            --
            ,  @template_update = REPLACE(@template_update, '{{RowHashCompare}}', IIF(COLUMNPROPERTY(@ObjectID, '_RowHash', 'ColumnId') IS NOT NULL, 'AND x.[_RowHash] <> d.[_RowHash]', ''))
            ,  @template_update = REPLACE(@template_update, '{{UpdateSet}}'     , @UpdateSet);
        ----------------------------------------

        ----------------------------------------
        -- Prepare insert script
        ----------------------------------------
        DECLARE @template_insert nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
            INSERT {{FQON}} ({{InsertColumnList}})
            SELECT {{InsertColumnSelectList}}
            FROM #Dataset d
            WHERE NOT EXISTS (SELECT * FROM {{FQON}} x WHERE {{JoinPredicates}});
        ');

        SELECT @template_insert = REPLACE(@template_insert, '{{FQON}}'                  , @FQON)
            ,  @template_insert = REPLACE(@template_insert, '{{JoinPredicates}}'        , @JoinPredicates)
            --
            ,  @template_insert = REPLACE(@template_insert, '{{InsertColumnList}}'      , @InsertColumnList)
            ,  @template_insert = REPLACE(@template_insert, '{{InsertColumnSelectList}}', @InsertColumnSelectList);
        ----------------------------------------

        ----------------------------------------
        IF (@WhatIf = 1)
        BEGIN;
            SELECT DeleteScript = IIF(@DeletesEnabled = 1, @template_delete, NULL)
                ,  UpdateScript = @template_update
                ,  InsertScript = @template_insert;
        END;
        ELSE
        BEGIN;
            DECLARE @sw datetime2 = SYSUTCDATETIME();

            BEGIN TRAN;
                IF (@DeletesEnabled = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Delete', NULL, NULL, @CallingProcName, @TargetTable;
                    EXEC sp_executesql @template_delete, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;
                END;

                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @CallingProcName, @TargetTable;
                EXEC sp_executesql @template_update, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;

                EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @CallingProcName, @TargetTable;
                EXEC sp_executesql @template_insert, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;
            COMMIT;
        END;
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
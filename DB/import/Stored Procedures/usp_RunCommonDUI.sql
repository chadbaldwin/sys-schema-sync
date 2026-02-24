CREATE PROC import.usp_RunCommonDUI (
    @InstanceID      int = NULL,
    @DatabaseID      int = NULL,
    @CallingProcName nvarchar(500),
    @TargetTable     nvarchar(300),
    @DeletesEnabled  bit = 1,
    @UpdatesEnabled  bit = 1,
    @InsertsEnabled  bit = 1,
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
        DECLARE @ObjectID int = OBJECT_ID(@TargetTable),
                @FQON     nvarchar(300);
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        IF (@ObjectID IS NULL)
        BEGIN;
            THROW 50000, 'Table name supplied to @TargetTable was not found.', 1;
        END;

        SELECT @FQON = CONCAT(QUOTENAME(SCHEMA_NAME(o.[schema_id])), '.', QUOTENAME(o.[name]))
        FROM sys.objects o
        WHERE o.[object_id] = @ObjectID;
        ----------------------------------------

        ----------------------------------------
        -- DROP TABLE IF EIXSTS #join_columns;
        CREATE TABLE #join_columns (
            key_ordinal int           NOT NULL,
            column_id   int           NOT NULL,
            [name]      nvarchar(128) NOT NULL,
        );

        INSERT #join_columns WITH(TABLOCK) (key_ordinal, column_id, [name])
        SELECT ic.key_ordinal, ic.column_id, COL_NAME(ic.[object_id], ic.column_id)
        FROM sys.indexes i
            JOIN sys.index_columns ic ON ic.[object_id] = i.[object_id] AND ic.index_id = i.index_id
        WHERE i.[object_id] = @ObjectID
            AND i.index_id = 1 AND i.is_unique = 1; -- clustered unique index

        IF (@@ROWCOUNT = 0)
        BEGIN;
            THROW 50001, 'No unique clustered index found on target table. A unique clustered index is required to use this method.', 1;
        END;

        DECLARE @JoinPredicates nvarchar(MAX);

        SELECT @JoinPredicates = STRING_AGG(CONCAT('d.', QUOTENAME([name]), ' = x.', QUOTENAME([name])), N' AND ') WITHIN GROUP (ORDER BY key_ordinal)
        FROM #join_columns;
        ----------------------------------------

        ----------------------------------------
        SELECT c.column_id
            , UpdateLine  = CONCAT('x.', x.ColName, SPACE(MAX(LEN(x.ColName)) OVER () - LEN(x.ColName)), ' = ', IIF(c.[name] = '_ModifyDate', 'SYSUTCDATETIME()', 'd.'+x.ColName))
            , InsertCol    = x.ColName
            , InsertSelect = 'd.'+x.ColName
            , ExcludeFromUpdate = CONVERT(bit, IIF(c.[name] IN ('_InsertDate'               , '_ValidFrom', '_ValidTo') OR c.[name] IN (SELECT jc.[name] FROM #join_columns jc), 1, 0))
            , ExcludeFromInsert = CONVERT(bit, IIF(c.[name] IN ('_InsertDate', '_ModifyDate', '_ValidFrom', '_ValidTo'), 1, 0))
        INTO #tmpCols
        FROM sys.objects o
            JOIN sys.columns c ON c.[object_id] = o.[object_id]
            CROSS APPLY (SELECT ColName = QUOTENAME(c.[name])) x
        WHERE o.[object_id] = @ObjectID;

        DECLARE @UpdateSet              nvarchar(MAX),
                @InsertColumnList       nvarchar(MAX),
                @InsertColumnSelectList nvarchar(MAX);

        SELECT @UpdateSet             = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromUpdate = 1, NULL, c.UpdateLine)), CHAR(13)+CHAR(10)+N'                  , ') WITHIN GROUP (ORDER BY c.column_id)
            , @InsertColumnList       = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertCol))   , N', ') WITHIN GROUP (ORDER BY c.column_id)
            , @InsertColumnSelectList = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertSelect)), N', ') WITHIN GROUP (ORDER BY c.column_id)
        FROM #tmpCols c;
        ----------------------------------------

        ----------------------------------------
        -- Prepare delete script
        ----------------------------------------
        DECLARE @template_delete nvarchar(MAX);
        IF (@DeletesEnabled = 1)
        BEGIN;
            SET @template_delete = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
                DELETE x
                FROM {{FQON}} x
                WHERE NOT EXISTS (SELECT * FROM #Dataset d WHERE {{JoinPredicates}})
                    {{InstanceIDFilter}}
                    {{DatabaseIDFilter}};');

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
        DECLARE @template_update nvarchar(MAX);
        IF (@UpdatesEnabled = 1)
        BEGIN;
            SET @template_update = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
                UPDATE x
                SET {{UpdateSet}}
                FROM {{FQON}} x
                    JOIN #Dataset d ON {{JoinPredicates}}
                {{RowHashCompare}};');

            DECLARE @filter_predicates nvarchar(MAX);
            SELECT @filter_predicates = 'WHERE (' + NULLIF(CONCAT_WS(' OR '
                    , IIF(COLUMNPROPERTY(@ObjectID, '_RowHash'           , 'ColumnId') IS NOT NULL, 'x.[_RowHash] <> d.[_RowHash]', NULL)
                    -- Kind of an annoying hack just for one single proc that uses this scenario, but sticking with this for now until I come up with a better solution
                    , IIF(COLUMNPROPERTY(@ObjectID, '_ObjectDefinitionID', 'ColumnId') IS NOT NULL, 'x.[_ObjectDefinitionID] <> d.[_ObjectDefinitionID]', NULL)
                ), '') + ')';
            -- If _RowHash doesn't exist, then every row will be updated whether there are changes or not.
            -- Typically used by the delta table feeds since we want to record snapshots even when the row hasn't changed.
            SELECT @template_update = REPLACE(@template_update, '{{FQON}}'          , @FQON)
                ,  @template_update = REPLACE(@template_update, '{{JoinPredicates}}', @JoinPredicates)
                --
                ,  @template_update = REPLACE(@template_update, '{{RowHashCompare}}', COALESCE(@filter_predicates, ''))
                ,  @template_update = REPLACE(@template_update, '{{UpdateSet}}'     , @UpdateSet);
        END;
        ----------------------------------------

        ----------------------------------------
        -- Prepare insert script
        ----------------------------------------
        DECLARE @template_insert nvarchar(MAX);
        IF (@InsertsEnabled = 1)
        BEGIN;
            SET @template_insert = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
                INSERT {{FQON}} ({{InsertColumnList}})
                SELECT {{InsertColumnSelectList}}
                FROM #Dataset d
                WHERE NOT EXISTS (SELECT * FROM {{FQON}} x WHERE {{JoinPredicates}});');

            SELECT @template_insert = REPLACE(@template_insert, '{{FQON}}'                  , @FQON)
                ,  @template_insert = REPLACE(@template_insert, '{{JoinPredicates}}'        , @JoinPredicates)
                --
                ,  @template_insert = REPLACE(@template_insert, '{{InsertColumnList}}'      , @InsertColumnList)
                ,  @template_insert = REPLACE(@template_insert, '{{InsertColumnSelectList}}', @InsertColumnSelectList);
        END;
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
                    EXEC sys.sp_executesql @template_delete, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Delete', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;
                END;

                IF (@UpdatesEnabled = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Update', NULL, NULL, @CallingProcName, @TargetTable;
                    EXEC sys.sp_executesql @template_update, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Update', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;
                END;

                IF (@InsertsEnabled = 1)
                BEGIN;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Start: Insert', NULL, NULL, @CallingProcName, @TargetTable;
                    EXEC sys.sp_executesql @template_insert, N'@InstanceID int, @DatabaseID int', @InstanceID = @InstanceID, @DatabaseID = @DatabaseID;
                    EXEC dbo.usp_Raiserror '[%s] [%s] Done: Insert', @sw, @@ROWCOUNT, @CallingProcName, @TargetTable;
                END;
            COMMIT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror '[%s] Done: Import Proc', @proc_sw, NULL, @ProcName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Line %d)', ERROR_MESSAGE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror '[%s] Error: Import Proc - %s', @proc_sw, NULL, @ProcName, @ErrorMessage, @IsError = 1;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
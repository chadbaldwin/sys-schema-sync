CREATE PROC import.usp_RunCommonDUI (
    @DatabaseID      int,
    @CallingProcName nvarchar(500),
    @TargetTable     nvarchar(300),
    @DeletesEnabled  bit = 1,
    @WhatIf          bit = 0
)
AS
BEGIN;
    DECLARE @ObjectID               int = OBJECT_ID(@TargetTable),
            @FQON                   nvarchar(300),
            @JoinPredicates         nvarchar(MAX),
            @UpdateSet              nvarchar(MAX),
            @InsertColumnList       nvarchar(MAX),
            @InsertColumnSelectList nvarchar(MAX);

    IF (@DatabaseID IS NULL) BEGIN;
        THROW 51000, 'Required parameter @DatabaseID is NULL', 1;
    END;

    IF (@ObjectID IS NULL)
    BEGIN;
        THROW 50000, 'Table name supplied to @TargetTable was not found.', 1;
    END;

    SELECT @FQON = CONCAT(QUOTENAME(SCHEMA_NAME(o.[schema_id])), '.', QUOTENAME(o.[name]))
    FROM sys.objects o
    WHERE o.[object_id] = @ObjectID;

    CREATE TABLE #join_columns (
        key_ordinal int           NOT NULL,
        column_id   int           NOT NULL,
        [name]      nvarchar(128) NOT NULL,
    );

    INSERT #join_columns (key_ordinal, column_id, [name])
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

    SELECT @UpdateSet             = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromUpdate = 1, NULL, c.UpdateLine)), CHAR(13)+CHAR(10)+N'              , ') WITHIN GROUP (ORDER BY c.column_id)
        , @InsertColumnList       = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertCol))   , N', ') WITHIN GROUP (ORDER BY c.column_id)
        , @InsertColumnSelectList = STRING_AGG(CONVERT(nvarchar(MAX), IIF(ExcludeFromInsert = 1, NULL, c.InsertSelect)), N', ') WITHIN GROUP (ORDER BY c.column_id)
    FROM #tmpCols c;

    DECLARE @template_delete nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
            EXEC dbo.usp_Raiserror ''[%s] [%s] Start: Delete'', NULL, NULL, @ProcName, @TableName; SET @sw = SYSUTCDATETIME();
            DELETE x
            FROM {{FQON}} x
            WHERE x.[_DatabaseID] = @DatabaseID
                AND NOT EXISTS (
                    SELECT *
                    FROM #Dataset d
                    WHERE {{JoinPredicates}}
                );
            EXEC dbo.usp_Raiserror ''[%s] [%s] Done: Delete'', @sw, @@ROWCOUNT, @ProcName, @TableName;'),
            @template_update nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
            EXEC dbo.usp_Raiserror ''[%s] [%s] Start: Update'', NULL, NULL, @ProcName, @TableName; SET @sw = SYSUTCDATETIME();
            UPDATE x
            SET {{UpdateSet}}
            FROM {{FQON}} x
                JOIN #Dataset d ON {{JoinPredicates}}
            WHERE x.[_RowHash] <> d.[_RowHash];
            EXEC dbo.usp_Raiserror ''[%s] [%s] Done: Update'', @sw, @@ROWCOUNT, @ProcName, @TableName;'),
            @template_insert nvarchar(MAX) = TRIM(CHAR(13)+CHAR(10)+CHAR(32) FROM N'
            EXEC dbo.usp_Raiserror ''[%s] [%s] Start: Insert'', NULL, NULL, @ProcName, @TableName; SET @sw = SYSUTCDATETIME();
            INSERT {{FQON}} ({{InsertColumnList}})
            SELECT {{InsertColumnSelectList}}
            FROM #Dataset d
            WHERE NOT EXISTS (
                    SELECT *
                    FROM {{FQON}} x
                    WHERE {{JoinPredicates}}
                );
            EXEC dbo.usp_Raiserror ''[%s] [%s] Done: Insert'', @sw, @@ROWCOUNT, @ProcName, @TableName;');

    DECLARE @sql nvarchar(MAX);
    SELECT @sql = N'
        BEGIN TRAN;
            DECLARE @sw datetime2(7);
            {{delete}}
            {{update}}
            {{insert}}
        COMMIT;'
        ----
        ,  @sql = REPLACE(@sql, '{{delete}}'                , IIF(@DeletesEnabled = 1, @template_delete, ''))
        ,  @sql = REPLACE(@sql, '{{update}}'                , @template_update)
        ,  @sql = REPLACE(@sql, '{{insert}}'                , @template_insert)
        ----
        ,  @sql = REPLACE(@sql, '{{FQON}}'                  , @FQON)
        ,  @sql = REPLACE(@sql, '{{JoinPredicates}}'        , @JoinPredicates)
        ,  @sql = REPLACE(@sql, '{{UpdateSet}}'             , @UpdateSet)
        ,  @sql = REPLACE(@sql, '{{InsertColumnList}}'      , @InsertColumnList)
        ,  @sql = REPLACE(@sql, '{{InsertColumnSelectList}}', @InsertColumnSelectList)
        ----
        ,  @sql = TRIM(CHAR(13)+CHAR(10) FROM @sql);

    IF (@WhatIf = 1)
    BEGIN;
        SELECT SQLToRun = @sql;
    END
    ELSE
    BEGIN;
        EXEC sp_executesql @sql, N'@DatabaseID int, @ProcName nvarchar(200), @TableName nvarchar(200)', @DatabaseID = @DatabaseID, @ProcName = @CallingProcName, @TableName = @TargetTable;
    END;
END;
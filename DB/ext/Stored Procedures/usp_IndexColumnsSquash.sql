CREATE PROC ext.usp_IndexColumnsSquash
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    DECLARE @process_id  int = 1,
            @old_version bigint,
            @new_version bigint,
            @min_version bigint;

    SELECT @old_version = LastChangeTrackingVersion
        ,  @new_version = CHANGE_TRACKING_CURRENT_VERSION()
        ,  @min_version = CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('dbo._index_columns'))
    FROM ext.ProcessRunState
    WHERE ID = @process_id;

    IF (@old_version = @new_version)
    BEGIN;
        RAISERROR('Nothing has changed',0,1) WITH NOWAIT;
        RETURN;
    END;

    -- DROP TABLE IF EXISTS #changes;
    CREATE TABLE #changes (
        _DatabaseID int NOT NULL,
        _IndexID bigint NOT NULL,
        INDEX IX UNIQUE CLUSTERED (_DatabaseID, _IndexID)
    );

    IF (@old_version >= @min_version)
    BEGIN;
        RAISERROR('Partial refresh',0,1) WITH NOWAIT;
        INSERT #changes WITH(TABLOCK) (_DatabaseID, _IndexID)
        SELECT DISTINCT x._DatabaseID, x._IndexID
        FROM CHANGETABLE(CHANGES dbo._index_columns, @old_version) x
        WHERE x.SYS_CHANGE_VERSION <= @new_version;

        IF (@@ROWCOUNT = 0)
        BEGIN;
            RAISERROR('Nothing to do',0,1) WITH NOWAIT;
            RETURN;
        END;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    BEGIN TRAN;
        IF NOT EXISTS (SELECT * FROM #changes)
        BEGIN;
            RAISERROR('Truncate table',0,1) WITH NOWAIT;
            TRUNCATE TABLE ext.IndexColumnsSquash;
        END;
        ELSE
        BEGIN;
            RAISERROR('Partial delete',0,1) WITH NOWAIT;
            DELETE x
            FROM ext.IndexColumnsSquash x
            WHERE EXISTS (
                    SELECT *
                    FROM #changes c
                    WHERE c._DatabaseID = x._DatabaseID
                        AND c._IndexID = x._IndexID
                );
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        RAISERROR('Insert changed rows',0,1) WITH NOWAIT;
        DECLARE @d nchar(1) = NCHAR(9999); -- Delimeter to use for separating values in templates
        INSERT ext.IndexColumnsSquash (_DatabaseID, _IndexID, KeyColsN, KeyColsNQ, KeyColsNQO, InclColsNQ)
        SELECT ic._DatabaseID, ic._IndexID
            , KeyColsN   = STRING_AGG(IIF(ic.is_included_column = 0, n.ColN  , NULL), @d) WITHIN GROUP (ORDER BY ic.key_ordinal, n.ColN)
            , KeyColsNQ  = STRING_AGG(IIF(ic.is_included_column = 0, q.ColNQ , NULL), @d) WITHIN GROUP (ORDER BY ic.key_ordinal, n.ColN)
            , KeyColsNQO = STRING_AGG(IIF(ic.is_included_column = 0, t.ColNQO, NULL), @d) WITHIN GROUP (ORDER BY ic.key_ordinal, n.ColN)
            , InclColsNQ = STRING_AGG(IIF(ic.is_included_column = 1, q.ColNQ , NULL), @d) WITHIN GROUP (ORDER BY ic.key_ordinal, n.ColN)
        FROM dbo._index_columns ic
            JOIN dbo.vw_Column c ON c._ColumnID = ic._ColumnID
            CROSS APPLY (SELECT ColN   = c.ColumnName) n                                                         -- ColumnName
            CROSS APPLY (SELECT ColNQ  = QUOTENAME(n.ColN)) q                                                    -- [ColumnName]
            CROSS APPLY (SELECT ColNQO = CONCAT_WS(' ', q.ColNQ, IIF(ic.is_descending_key = 1, 'DESC', NULL))) t -- [ColumnName] DESC
        WHERE EXISTS (SELECT * FROM #changes x WHERE x._DatabaseID = ic._DatabaseID AND x._IndexID = ic._IndexID)
            OR @old_version < @min_version -- First run, or gap since last run exceeds change tracking history
        GROUP BY ic._DatabaseID, ic._IndexID
        OPTION (RECOMPILE);
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        UPDATE ext.ProcessRunState SET LastChangeTrackingVersion = @new_version, ModifyDateUTC = SYSUTCDATETIME() WHERE ID = @process_id;
    COMMIT;
END;
GO
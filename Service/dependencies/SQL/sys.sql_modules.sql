/* Column overrides */
DROP TABLE IF EXISTS #column_overrides;
CREATE TABLE #column_overrides (
    ColumnName nvarchar(128),
    ColumnOverride nvarchar(MAX),
);

INSERT #column_overrides (ColumnName, ColumnOverride)
VALUES ('definition'
    , '[definition] = TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM x.[definition])');

DECLARE @columns nvarchar(MAX);

SELECT @columns = STRING_AGG(CONVERT(nvarchar(MAX), COALESCE(co.ColumnOverride, 'x.'+QUOTENAME(sc.[name]))), CHAR(13)+CHAR(10)+'        , ') WITHIN GROUP (ORDER BY column_id)
FROM sys.system_columns sc
    LEFT JOIN #column_overrides co ON co.ColumnName = sc.[name]
WHERE [object_id] = OBJECT_ID('sys.sql_modules');

/* Template query */
DECLARE @sql nvarchar(MAX) = '
WITH cte_obj AS (
    SELECT o.[object_id], SchemaName = s.[name], ObjectName = o.[name], ObjectType = o.[type]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
    UNION
    SELECT t.[object_id], ''<<DB>>'', t.[name], t.[type]
    FROM sys.triggers t
    WHERE parent_class = 0
        AND t.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _ObjectDefinitionHash = CONVERT(binary(32), COALESCE(HASHBYTES(''SHA2_256'', x.[definition]), 0x0)) -- Encrypted SPs have a NULL definition
    , _RowHash = CONVERT(binary(32), HASHBYTES(''SHA2_256'', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM (
    SELECT {{columns}}
    FROM sys.sql_modules x
) x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
OPTION (RECOMPILE);
';

SELECT @sql = REPLACE(@sql, '{{columns}}', @columns);

/* Run the query */
EXEC sys.sp_executesql @stmt = @sql;
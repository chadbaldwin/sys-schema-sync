/* Column overrides */
DROP TABLE IF EXISTS #column_overrides;
CREATE TABLE #column_overrides (
    ColumnName nvarchar(128),
    ColumnOverride nvarchar(MAX),
);

INSERT #column_overrides (ColumnName, ColumnOverride)
VALUES ('default_value'
    , '[default_value] = CONVERT(nvarchar(MAX),
            CASE -- Adapted from: https://github.com/chadbaldwin/SQL/blob/main/Scripts/Convert%20sql_variant%20to%20portable%20format.sql
                WHEN v.BaseType = ''date''                    THEN FORMAT(CONVERT(date, x.[default_value]), ''yyyy-MM-dd'')
                WHEN v.BaseType = ''datetime''                THEN FORMAT(CONVERT(datetime, x.[default_value]), ''yyyy-MM-dd HH:mm:ss.fff'')
                WHEN v.BaseType = ''smalldatetime''           THEN FORMAT(CONVERT(smalldatetime, x.[default_value]), ''yyyy-MM-dd HH:mm'')
                WHEN v.BaseType = ''datetime2''               THEN LEFT(FORMAT(CONVERT(datetime2, x.[default_value]), ''o''), v.[Precision])
                WHEN v.BaseType = ''datetimeoffset''          THEN STUFF(FORMAT(CONVERT(datetimeoffset, x.[default_value]), ''o''), v.[Precision]-6, 34-v.[Precision], '''')
                WHEN v.BaseType = ''time''                    THEN LEFT(CONVERT(nvarchar(16), x.[default_value], 114), v.[Precision])
                WHEN v.BaseType IN (''float'',''real'')       THEN CONVERT(nvarchar(MAX), CONVERT(float, x.[default_value]), 3)
                WHEN v.BaseType = ''varbinary''               THEN CONVERT(nvarchar(MAX), CONVERT(varbinary(MAX), x.[default_value]), 1)
                WHEN v.BaseType = ''binary''                  THEN CONVERT(nvarchar(MAX), CONVERT(varbinary(MAX), LEFT(CONVERT(varbinary(MAX), x.[default_value]), v.[MaxLength])), 1)
                WHEN v.BaseType IN (''money'',''smallmoney'') THEN CONVERT(nvarchar(MAX), CONVERT(money, x.[default_value]), 2)
                ELSE CONVERT(nvarchar(MAX), x.[default_value]) -- Tested OK: bigint, int, smallint, tinyint, bit, decimal, numeric, char, nchar, varchar, nvarchar, xml, uniqueidentifier
            END)');

DECLARE @columns nvarchar(MAX);

SELECT @columns = STRING_AGG(CONVERT(nvarchar(MAX), COALESCE(co.ColumnOverride, 'x.'+QUOTENAME(sc.[name]))), CHAR(13)+CHAR(10)+'        , ') WITHIN GROUP (ORDER BY column_id)
FROM sys.system_columns sc
    LEFT JOIN #column_overrides co ON co.ColumnName = sc.[name]
WHERE [object_id] = OBJECT_ID('sys.parameters');

/* Template query */
DECLARE @sql nvarchar(MAX) = '
WITH cte_obj AS (
    SELECT o.[object_id], SchemaName = s.[name], ObjectName = o.[name], ObjectType = o.[type]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _RowHash = CONVERT(binary(32), HASHBYTES(''SHA2_256'', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.*
FROM (
    SELECT {{columns}}
    FROM sys.parameters x
        CROSS APPLY (
            SELECT BaseType   = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(x.[default_value], ''BaseType''))
                , [Precision] = CONVERT(int          , SQL_VARIANT_PROPERTY(x.[default_value], ''Precision''))
                , [MaxLength] = CONVERT(int          , SQL_VARIANT_PROPERTY(x.[default_value], ''MaxLength''))
        ) v
) x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
OPTION (RECOMPILE);
';

SELECT @sql = REPLACE(@sql, '{{columns}}', @columns);

/* Run the query */
EXEC sys.sp_executesql @stmt = @sql;
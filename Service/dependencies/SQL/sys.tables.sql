DECLARE @rowhash_columns nvarchar(MAX);

SELECT @rowhash_columns = STRING_AGG(CONVERT(nvarchar(MAX), 'x.'+QUOTENAME(sc.[name])), ', ') WITHIN GROUP (ORDER BY column_id)
FROM sys.system_columns sc
WHERE [object_id] = OBJECT_ID('sys.tables')
    AND sc.[name] NOT IN ('create_date','modify_date','is_ms_shipped','type_desc'); -- exclude unecessary columns from rowhash calculation

/* Template query */
DECLARE @sql nvarchar(MAX) = '
WITH cte_obj AS (
    SELECT o.[object_id], ObjectType = o.[type], SchemaName = s.[name], ObjectName = o.[name]
    FROM sys.objects o
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
    WHERE o.is_ms_shipped = 0
)
SELECT _SchemaName = o.SchemaName
    , _ObjectName = o.ObjectName
    , _ObjectType = o.ObjectType
    , _RowHash = CONVERT(binary(32), HASHBYTES(''SHA2_256'', (SELECT {{x.rowhash_columns}} FOR JSON PATH)))
    --
    , x.*
FROM sys.tables x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
OPTION (RECOMPILE);
';

SELECT @sql = REPLACE(@sql, '{{x.rowhash_columns}}', @rowhash_columns);

/* Run the query */
EXEC sys.sp_executesql @stmt = @sql;
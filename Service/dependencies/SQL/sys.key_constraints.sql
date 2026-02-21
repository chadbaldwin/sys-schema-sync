DECLARE @rowhash_columns nvarchar(MAX);

SELECT @rowhash_columns = STRING_AGG(CONVERT(nvarchar(MAX), 'x.'+QUOTENAME(sc.[name])), ', ') WITHIN GROUP (ORDER BY column_id)
FROM sys.system_columns sc
WHERE [object_id] = OBJECT_ID('sys.objects')
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
    , _ParentObjectName = po.ObjectName
    , _ParentObjectType = po.ObjectType
    , _UniqueIndexName = ui.[name]
    , _RowHash = CONVERT(binary(32), HASHBYTES(''SHA2_256'', (SELECT {{x.rowhash_columns}} FOR JSON PATH)))
    --
    , x.*
FROM sys.key_constraints x
    JOIN cte_obj o ON o.[object_id] = x.[object_id]
    JOIN cte_obj po ON po.[object_id] = x.parent_object_id
    JOIN sys.indexes ui ON ui.[object_id] = x.parent_object_id AND ui.index_id = x.unique_index_id
OPTION (RECOMPILE, USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''), LOOP JOIN);
';

SELECT @sql = REPLACE(@sql, '{{x.rowhash_columns}}', @rowhash_columns);

/* Run the query */
EXEC sys.sp_executesql @stmt = @sql;
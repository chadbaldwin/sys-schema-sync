/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
/*  Get instance time zone
    2019 (v15) and under, registry is the only way to get it
    2022 (v16) and up we can use the new CURRENT_TIMEZONE_ID() function
*/
DECLARE @tzsql nvarchar(MAX), @LocalTZ nvarchar(128);
IF (CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) < 16)
BEGIN;
    SELECT @tzsql = N'EXEC [master].dbo.xp_regread @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SYSTEM\CurrentControlSet\Control\TimeZoneInformation'', @value_name = ''TimeZoneKeyName'', @value = @LocalTZ OUT;'
END;
ELSE
BEGIN;
    SELECT @tzsql = N'SELECT @LocalTZ = CURRENT_TIMEZONE_ID();'
END;

EXEC sys.sp_executesql @stmt = @tzsql, @params = N'@LocalTZ nvarchar(128) OUT', @LocalTZ = @LocalTZ OUT;
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
SELECT _SchemaName, _ObjectName, _ObjectType
    , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , missing_index_hash
    , unique_compiles, user_seeks, user_scans
    , last_user_seek_utc, last_user_scan_utc
    , avg_total_user_cost, avg_user_impact
    , equality_columns, inequality_columns, included_columns
    , column_data
FROM ( -- Encapsulating in a sub-query to make row-hash calculation easier using x.*
    SELECT _SchemaName = n.SchemaName
        , _ObjectName = n.ObjectName
        , _ObjectType = o.[type]
        --
        , missing_index_hash = CONVERT(binary(32), HASHBYTES('SHA2_256', j.column_data))
        , migs.unique_compiles, migs.user_seeks, migs.user_scans
        , last_user_seek_utc = CONVERT(datetime2, migs.last_user_seek AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
        , last_user_scan_utc = CONVERT(datetime2, migs.last_user_scan AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
        , migs.avg_total_user_cost, migs.avg_user_impact
        , mid.equality_columns, mid.inequality_columns, mid.included_columns
        , j.column_data
    FROM sys.dm_db_missing_index_groups mig
        JOIN sys.dm_db_missing_index_details mid ON mid.index_handle = mig.index_handle
        JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
        JOIN sys.objects o ON o.[object_id] = mid.[object_id]
        CROSS APPLY (SELECT SchemaName = SCHEMA_NAME(o.[schema_id]), ObjectName = o.[name]) n
        CROSS APPLY (
            SELECT EQUALITY  = STRING_AGG(IIF(column_usage = 'EQUALITY'  , x.col_name_clean, NULL), ',') WITHIN GROUP (ORDER BY column_name)
                , INEQUALITY = STRING_AGG(IIF(column_usage = 'INEQUALITY', x.col_name_clean, NULL), ',') WITHIN GROUP (ORDER BY column_name)
                , [INCLUDE]  = STRING_AGG(IIF(column_usage = 'INCLUDE'   , x.col_name_clean, NULL), ',') WITHIN GROUP (ORDER BY column_name)
            FROM sys.dm_db_missing_index_columns(mig.index_handle) mic
                CROSS APPLY (SELECT col_name_clean = QUOTENAME(STRING_ESCAPE(column_name,'json'),'"')) x
            GROUP BY () /* Ensures that if nothing is returned from `sys.dm_db_missing_index_columns`, then it is not included in the result of this query.
                           I ran into situations where, for some unknown reason, nothing was returned from this view, causing unrelated index suggestions
                           to get the same JSON blob, and thus the same missing_index_hash */
        ) c
        /* Generate a JSON blob for two uses:
            1) to make storing lists of columns easier to store in a single table and also avoid issues like columns which contain a comma or other delimiter
            2) to use for generating a unique missing index identifier as a hash
        */
        CROSS APPLY (
            SELECT n.SchemaName, n.ObjectName -- Not needed here for storing the column data, but helps with making the missing_index_hash more unique
                , EQUALITY   = JSON_QUERY('[' + c.EQUALITY   + ']')
                , INEQUALITY = JSON_QUERY('[' + c.INEQUALITY + ']')
                , [INCLUDE]  = JSON_QUERY('[' + c.[INCLUDE]  + ']')
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) j (column_data)
    WHERE database_id = DB_ID()
) x;
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
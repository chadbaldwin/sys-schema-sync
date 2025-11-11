/* 
    This export script is a special case due to how the `sys.dm_db_index_usage_stats` DMV works.

    This DMV is cleared and reset for various reasons at the instnace, DB, object and index level.

    Since this table is used to determine how often an index is used, then it makes sense to generate
    rows for indexes that are not in the table at all. Allows us to see if an index is NEVER used.
*/
DECLARE @LocalTZ            nvarchar(128),
        @CollectionTime     datetime2 = SYSUTCDATETIME(),
        @SQLServerStartTime datetime2,
        @DBLastRestoreTime  datetime2;
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
/*  Get instance time zone
    2019 (v15) and under, registry is the only way to get it
    2022 (v16) and up we can use the new CURRENT_TIMEZONE_ID() function
*/
DECLARE @tzsql nvarchar(MAX);
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
/* Get SQL Server service start time */
SELECT @SQLServerStartTime = sqlserver_start_time AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC'
FROM sys.dm_os_sys_info;

/* DB Restores don't require a service restart, but they do clear the restored database's stats DMVs */
SELECT @DBLastRestoreTime = MAX(restore_date) AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC'
FROM msdb.dbo.restorehistory WHERE destination_database_name = DB_NAME();
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
DROP TABLE IF EXISTS #prv;
CREATE TABLE #prv (
    data_space_id    int           NOT NULL,
    partition_number int           NOT NULL,
    boundary_value   nvarchar(100) NOT NULL,
    INDEX CIX CLUSTERED (data_space_id, partition_number)
);

INSERT #prv (data_space_id, partition_number, boundary_value)
SELECT s.data_space_id, rv.boundary_id + f.boundary_value_on_right
    , CASE -- Convert boundary values to a lossless portable string value
        WHEN v.BaseType = 'date'                  THEN FORMAT(CONVERT(date, rv.[value]), 'yyyy-MM-dd')
        WHEN v.BaseType = 'datetime'              THEN FORMAT(CONVERT(datetime, rv.[value]), 'yyyy-MM-dd HH:mm:ss.fff')
        WHEN v.BaseType = 'smalldatetime'         THEN FORMAT(CONVERT(smalldatetime, rv.[value]), 'yyyy-MM-dd HH:mm')
        WHEN v.BaseType = 'datetime2'             THEN LEFT(FORMAT(CONVERT(datetime2, rv.[value]), 'o'), v.[Precision])
        WHEN v.BaseType = 'datetimeoffset'        THEN STUFF(FORMAT(CONVERT(datetimeoffset, rv.[value]), 'o'), v.[Precision]-6, 34-v.[Precision], '')
        WHEN v.BaseType = 'time'                  THEN LEFT(CONVERT(nvarchar(16), rv.[value], 114), v.[Precision])
        WHEN v.BaseType IN ('float','real')       THEN CONVERT(nvarchar(MAX), CONVERT(float, rv.[value]), 3)
        WHEN v.BaseType IN ('money','smallmoney') THEN CONVERT(nvarchar(MAX), CONVERT(money, rv.[value]), 2)
        WHEN v.BaseType = 'varbinary'             THEN CONVERT(nvarchar(MAX), CONVERT(varbinary(MAX), rv.[value]), 1)
        WHEN v.BaseType = 'binary'                THEN CONVERT(nvarchar(MAX), CONVERT(varbinary(MAX), LEFT(CONVERT(varbinary(MAX), rv.[value]), v.[MaxLength])), 1)
        ELSE CONVERT(nvarchar(MAX), rv.[value]) -- Tested OK: bigint, int, smallint, tinyint, bit, decimal, numeric, char, nchar, varchar, nvarchar, xml, uniqueidentifier
    END
FROM sys.partition_schemes s
	JOIN sys.partition_functions f ON f.function_id = s.function_id
	JOIN sys.partition_range_values rv ON f.function_id = rv.function_id
    CROSS APPLY (
        SELECT BaseType   = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(rv.[value], 'BaseType'))
            , [Precision] = CONVERT(int, SQL_VARIANT_PROPERTY(rv.[value], 'Precision'))
            , [MaxLength] = CONVERT(int, SQL_VARIANT_PROPERTY(rv.[value], 'MaxLength'))
    ) v;

DROP TABLE IF EXISTS #ios;
SELECT *
INTO #ios
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL);

SELECT _SchemaName            = s.[name]
    , _ObjectName             = o.[name]
    , _ObjectType             = o.[type]
    , _IndexName              = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
    , _BoundaryValue          = prv.boundary_value
    , EstimatedStatsBeginTime = r.BeginDate
    , StatsEndTime            = @CollectionTime
    /*--*/
    , x.*
FROM sys.schemas s
    JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    JOIN sys.indexes i ON i.[object_id] = o.[object_id]
    JOIN sys.partitions p ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
    LEFT HASH JOIN #ios x ON x.[object_id] = i.[object_id] AND x.index_id = i.index_id AND x.partition_number = p.partition_number AND x.hobt_id = p.hobt_id
    LEFT JOIN sys.key_constraints kc ON kc.parent_object_id = i.[object_id] AND kc.unique_index_id = i.index_id
    LEFT JOIN #prv prv ON prv.data_space_id = i.data_space_id AND prv.partition_number = p.partition_number
    /* Handle time zone conversions */
    CROSS APPLY (
        /*  Unfortunately, SQL Server stores everything using system time, rather than UTC. Need to convert to UTC for historical storage */
        /*  First set the values to the local time zone (no shift), then convert to UTC (with shift) */
        SELECT object_create_date_utc     = CONVERT(datetime2, o.create_date  AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  constraint_create_date_utc = CONVERT(datetime2, kc.create_date AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
    ) tz
    /*  This is a best attempt determination of when the stats snapshot we're currently taking likely began.

        Restarting SQL Server and restoring a database clears out the stats tables. However, if an index is
        dropped and recreated, then the age of the snapshot is as of the index create date instead. Since
        SQL Server does not provide an index create date in all cases, we then have to rely on the object
        create date instead.

        So the best solution (without creating some other process) is to take the max of all those dates.

        Please vote on these SQL Server feedback items asking Microsoft to add create_date / modify_date columns to sys.indexes, sys.dm_db_index_usage_stats and sys.dm_db_index_operational_stats
        https://feedback.azure.com/d365community/idea/2a984a79-5025-ec11-b6e6-000d3a4f0da0
        https://feedback.azure.com/d365community/idea/9fec9e0e-3f25-ec11-b6e6-000d3a4f0da0
        https://feedback.azure.com/d365community/idea/e9e84bf2-64c4-ee11-92bc-000d3a0fb290
    */
    CROSS APPLY (SELECT BeginDate = MAX(x.BeginDate) FROM (VALUES (@SQLServerStartTime), (@DBLastRestoreTime), (tz.object_create_date_utc), (tz.constraint_create_date_utc)) x(BeginDate)) r
WHERE o.is_ms_shipped = 0
    AND o.[type] IN ('U','V')
ORDER BY 1,2,3,4
OPTION(RECOMPILE);
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/

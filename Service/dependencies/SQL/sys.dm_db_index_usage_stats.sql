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
--DROP TABLE IF EXISTS #ius;
SELECT *
INTO #ius
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID();

SELECT _SchemaName            = s.[name]
    , _ObjectName             = o.[name]
    , _ObjectType             = o.[type]
    , _IndexName              = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
    , EstimatedStatsBeginTime = r.BeginDate
    , StatsEndTime            = @CollectionTime
    /*--*/
    , database_id             = DB_ID()
    , [object_id]             = i.[object_id]
    , index_id                = i.index_id
    /*--*/
    , user_seeks              = COALESCE(x.user_seeks  , 0)
    , user_scans              = COALESCE(x.user_scans  , 0)
    , user_lookups            = COALESCE(x.user_lookups, 0)
    , user_updates            = COALESCE(x.user_updates, 0)
    , last_user_seek_utc      = tz.last_user_seek_utc
    , last_user_scan_utc      = tz.last_user_scan_utc
    , last_user_lookup_utc    = tz.last_user_lookup_utc
    , last_user_update_utc    = tz.last_user_update_utc
    /*--*/
    , system_seeks            = COALESCE(x.system_seeks  , 0)
    , system_scans            = COALESCE(x.system_scans  , 0)
    , system_lookups          = COALESCE(x.system_lookups, 0)
    , system_updates          = COALESCE(x.system_updates, 0)
    , last_system_seek_utc    = tz.last_system_seek_utc
    , last_system_scan_utc    = tz.last_system_scan_utc
    , last_system_lookup_utc  = tz.last_system_lookup_utc
    , last_system_update_utc  = tz.last_system_update_utc
FROM sys.schemas s
    JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    JOIN sys.indexes i ON i.[object_id] = o.[object_id]
    LEFT JOIN #ius x ON x.[object_id] = i.[object_id] AND x.index_id = i.index_id
    LEFT JOIN sys.key_constraints kc ON kc.parent_object_id = i.[object_id] AND kc.unique_index_id = i.index_id
    /* Handle time zone conversions */
    CROSS APPLY (
        /*  Unfortunately, SQL Server stores everything using system time, rather than UTC. Need to convert to UTC for historical storage */
        /*  First set the values to the local time zone (no shift), then convert to UTC (with shift) */
        SELECT object_create_date_utc     = CONVERT(datetime2, o.create_date       AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  constraint_create_date_utc = CONVERT(datetime2, kc.create_date      AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            -- Original datatype is datetime, so we don't gain any precision by using datetime2, might as well retain original types
            ,  last_user_seek_utc         = CONVERT(datetime, x.last_user_seek     AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_user_scan_utc         = CONVERT(datetime, x.last_user_scan     AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_user_lookup_utc       = CONVERT(datetime, x.last_user_lookup   AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_user_update_utc       = CONVERT(datetime, x.last_user_update   AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_system_seek_utc       = CONVERT(datetime, x.last_system_seek   AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_system_scan_utc       = CONVERT(datetime, x.last_system_scan   AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_system_lookup_utc     = CONVERT(datetime, x.last_system_lookup AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
            ,  last_system_update_utc     = CONVERT(datetime, x.last_system_update AT TIME ZONE @LocalTZ AT TIME ZONE 'UTC')
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
OPTION(RECOMPILE);
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
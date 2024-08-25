# sys-schema-sync

> [!CAUTION]
> This project is still in early development and testing. Behavior is subect to (and expected to) change, including breaking changes of configurations, installation, file names, database schema, etc.

## What is this, and how does it help?

Let's say you need to check whether RSCI is enabled on every production database, how would you do that? What are the query store settings on all databases? Does a particular table index exist and match on all databases?

In order to answer these questions, you need to write some sort of tool or script, maybe loop through linked servers, or try to use some other tool to get that data. What happens when you have dozens of people building these types of processes that reach out to all of your databases every day just to query the same information and store it in some altered format?

This is a database that centralizes various SQL Server instance and database level metadata into a familiar schema. Processes can be built to utilize this data, reading from a single database, rather than having to reach out to every production database.

----

## Primary Objective

To sync useful SQL Server system objects and other metadata from multiple databases into a central location while maintaining the original schema with as little changes as possible.

This ensures a level of familiarity with the schema and making it easier to convert existing queries over to use this system.

----

## Installation and Setup

For now, because this project is still in the early stages of development, there isn't a simple installer. Maybe in the future I'll find a nice way to package it up.

### Deploy the database

To deploy the database, you need to be familiar with SSDT. Open the SSDT Solution `/DB/SysSchemaSync.sln`, and publish the database to your location of choosing.

> TODO: In the future I may have releases which include things like a DACPAC or a database backup that can be restored. Along with things like scripts to make deployment easier. Such as using `sqlpackage.exe` or a PowerShell wrapper to publish the database.

### Configure the database

For now, the database is populated manually in regard to the Instances and Databases we want to target for syncing. However, I have not yet decided how I want the database configuration to be handled for the public version of this service.

To configure the database, you can do one of a few things...

1. You can manually insert the Instances and Databases into the appropriate tables yourself. You can do this in `dbo.[Instance]` `dbo.[Database]`. These tables are read by the service and fed into dbatoools for connecting to the various instances and collecting the data.
1. I have provided a sample stored procedure which you can modify to hardcode the list within the proc here: `/DB/import/Stored Procedures/usp_UpdateTargets.sql`

> TODO: In the future I may end up going the route of storing this information in a JSON file where users will populate connection strings into the `appsettings.json` file, and the Instance and Database tables would be updated accordingly.

### Deploy the service

Once that is set up, next you need to set up the sync service. Copy the "Service" directory wherever you plan to host the service as you will need to set up a Scheduled task. You can use anything that is able to run a PowerShell script in a regular interval, I'm using Windows Task Scheduler, but you can use whatever works for you.

### Configure the service

Next, update the `/Service/appsettings.json` file. Note: SysSchemaSync Service uses a generic PowerShell utility script that I use in multiple projects, which is why some of the configuration parameters are pre-configured and do not need to be changed.

```jsonc
{
  // For now, this is simply the NAME of the folder to create within the "Service" folder to use for logs
  "LogDirectory": "Logs",

  // Tells the generic PowerShell script runner what Instances and Databases to run against
  "TargetDatabaseListScriptPath": "target_databases.sql", // Do not change

  // Connection string pointing to where the SysSchemaSync database was deployed
  // This connection string is used by the generic script runner to get the list of databases to run against
  "TargetDatabaseListConnectionString": "Server=MYINSTANCE;Database=SysSchemaSync;MultiSubnetFailover=True;Application Name=SysSchemaSyncService",

  // Tells the generic PowerShell script runner what file we want to execute for each instance/database
  "PowerShellScriptToRunPath": "sync_objects.ps1", // Do not change

  // How many instances do we want to run syncs against in parallel
  "InstanceConcurrencyLimit": 10,
  // How many databases PER INSTANCE do we want to run syncs against in parallel?
  "DatabaseConcurrencyLimit": 3,
  // If Instance is set to 10 and Database is set to 3, then the highest number of concurrent processes possible is 30

  // Connection string pointing to where the SysSchemaSync database was deployed
  // This connection string is used by the SysSchemaSync scripts to know where to push the collected data
  "RepositoryDatabaseConnectionString": "Server=MYINSTANCE;Database=SysSchemaSync;MultiSubnetFailover=True;Application Name=SysSchemaSyncService"
}
```

### Schedule the service

Now set up an automated job / Windows Scheduled Task to call `/Service/database_parallel_runner.ps1`. I recommend running it every 5 minutes. You can run it as often as you like, but the process will only pick up items that are scheduled to run in the queue. If there's nothing to do, it will almost immediately close.

> TODO: In the future possibly include a script to set up the scheduled task automatically?

### Done

That's it. So to sum it up...

1. Deploy databawse via SSDT / Visual Studio
1. Configure database `dbo.[Instance]` and `dbo.[Database]` tables
1. Copy service files to host
1. Configure service `appsettings.json` file
1. Set up scheduled job to run (recommended every 5 minutes)
1. Database should start populating

----

## Querying

Terms:

* "sync table" - the destination table used in this database to store the results of the sync. For example `dbo._objects`, `dbo._dm_db_index_usage_stats`

The database follows a standard naming convention to make querying easier.

T-SQL considers most system object names as reserved keywords; So, sync tables are prefixed with an underscore, like `dbo._objects` and `dbo._views`, generally correlating with a system table in SQL Server, like `sys.objects`, `sys.views`. There are _some_ exceptions here due to various system tables existing in non-standard locations, like `msdb` (e.g. `msdb.dbo.restorehistory`), a user database (e.g. `dbo.sysarticles`), or no table exists and is the result of a system command (e.g. `DATABASEPROPERTYEX()` or `DBCC TRACESTATUS`).

All syncs can be seen, and controlled in the `import.SyncObject` configuration table, details about this table (and others) are in the Configuration section.

A standard naming convention is also used for the column names within the sync tables. Custom added columns are prefixed with an underscore (e.g. `_ObjectID`, `_DatabaseID`, `_InsertDate`). This is to ensure that the differentiation from source columns is obvious since (at least as of this writing) there are no system columns which also start with an underscore.

Source columns have the original column names, and in 99% of cases the original datatype, nullability etc. There are a few exceptions, such as `sql_variant`, which is not supported by the sync process for complex syncs (simple vs complex syncs explained later), so the datatype is changed to whichever makes the most sense. Another exception is if the column was added by later versions of SQL Server and is a `NOT NULL` column. In order to support backward compatibility for SQL Server 2017 and 2019, the columns are stored as nullable but are noted in the SSDT project as deviations.

SQL Server re-uses `index_id` and `column_id` values and if you drop + re-create an object, the `object_id` does not stick. In order to handle this, tables such as `dbo.[Object]`, `dbo.[Index]`, `dbo.[Column]`, etc were created. This ensures that relationships are maintained even if the source ID values change. For example, if a nonclustered index with `index_id` of 2 is dropped and a new nonclustered index is created, the new index will have an `index_id` of 2. So while this system will sync the ID values, they should not be relied upon for joining, and instead you should use the added FK columns such as `_ObjectID`, `_IndexID`, `_ColumnID`, `_ParentColumnID`, etc. These values are all globally unique within the system, so unlike in SQL Server where both `object_id` and `index_id` would be needed, here only `_IndexID` is needed for the join.

`Instance` vs `Database` level tables - Some system tables in SQL Server run at different "levels" or scopes. For example, `sys.dm_os_host_info` returns the same result no matter which database context it is run from, and the data returned is at the instance level. Depending on which "level" the data is, the sync table will have either a `_DatabaseID` or an `_InstanceID`. In some cases, a sync table might have both where the `_DatabaseID` is nullable, this is typically when it's most useful to have ALL records from that system object, but we may not have all databases within that instance set up to be sync'd. For example, `sys.databases`, all records are synced, but only databases which have a record in `dbo.[Database]` will have a `_DatabaseID` value set.

Lastly, this system relies on soft-deletes. In order to make life easier, views have been created. Rather than using `dbo.[Column]`, instead use `dbo.vw_Column` as it will have the soft-delete logic baked in, not just at the Column level, but also at the Object, Database and Instance level; So only a single view is usually is necessary.

----

### Example queries

#### Helper Views

```sql
-- Notice that each view includes info about all upper levels as well
-- (Instance -> Database -> Object -> Column/Index)

SELECT * FROM dbo.vw_Instance WHERE InstanceName = 'Instance1'
SELECT * FROM dbo.vw_Database WHERE DatabaseName = 'DBFoo'

SELECT TOP(100) * FROM dbo.vw_Object WHERE DatabaseName = 'DBFoo'
SELECT TOP(100) * FROM dbo.vw_Column WHERE DatabaseName = 'DBFoo'
SELECT TOP(100) * FROM dbo.vw_Index  WHERE DatabaseName = 'DBFoo'
```

Use these views to help with following soft delete logic and to access various helper columns for common tasks like filtering on AG replica status or getting an index's FQIN (fully qualified index name - `[dbo].[TableName].[PK_TableName]`).

#### Querying Objects

If you wanted to run a query against a SQL Server database directly to get a list of columns for a particular index, it might look something like this:

```sql
-- Get all columns for index 'PK_TableName' on table `dbo.TableName`
USE DBFoo;
GO
SELECT c.[name]
    , ic.[object_id], ic.index_id, ic.index_column_id, ic.column_id, ic.key_ordinal, ic.partition_ordinal, ic.is_descending_key, ic.is_included_column
FROM sys.indexes i
    JOIN sys.index_columns ic ON ic.[object_id] = i.[object_id] AND ic.[index_id] = i.[index_id]
    JOIN sys.columns c ON c.[object_id] = ic.[object_id] AND c.[column_id] = ic.[column_id]
WHERE OBJECT_SCHEMA_NAME(i.[object_id]) = 'dbo'
    AND OBJECT_NAME(i.[object_id]) = 'TableName'
    AND i.[name] = 'PK_TableName'
```

The equivalent for SysSchemaSync would be:

```sql
USE SysSchemaSync;
GO
SELECT vc.ColumnName
    , ic.[object_id], ic.index_id, ic.index_column_id, ic.column_id, ic.key_ordinal, ic.partition_ordinal, ic.is_descending_key, ic.is_included_column
FROM dbo._indexes i
    JOIN dbo._index_columns ic ON ic._IndexID = i._IndexID -- notice only IndexID is needed since it is unique within the system
    JOIN dbo.vw_Index vi  ON vi.IndexID = i._IndexID -- to follow soft delete logic
    JOIN dbo.vw_Column vc ON vc.ColumnID = ic._ColumnID -- again, to follow soft delete logic
WHERE vi.InstanceName = 'Instance1'
    AND vi.DatabaseName = 'DBFoo'
    AND vi.SchemaName = 'dbo'
    AND vi.ObjectName = 'TableName'
    AND vi.IndexName = 'PK_TableName'
```

Note: The reason the join to `dbo.vw_Column` is necessary is due to how the sync process works.

For example say a column was removed from an index and dropped from the table...If `dbo._columns` last synced 5 min ago, but `dbo._index_columns` is not scheduled to sync for another 3 hours. Then the column would be marked as deleted in `dbo.[Column]` and subsequently filtered out of `dbo.vw_Column`. Its record in `dbo._columns` will be removed, but it will still have a record in `dbo._index_columns` until the next time it is synced.

A similar issue can happen in reverse...if `dbo._index_columns` last synced 5 min ago, but `dbo._columns` is not scheduled to sync for another 3 hours. Then the column would NOT be marked as deleted since only the `sys.columns` sync can reliably capture that action. So a record would still exist in `dbo._columns`, but not in `dbo._index_columns` and would not be marked as deleted.

These data issues are generally rare to happen since schema changes are not something that occurs very frequently. However, because of this sync order issue, the data in this database should not be relied upon as a real-time status of their source, however, if needed, a sync can be manually forced to grab the latest data.

#### Instance Level Tables

Some queries are much easier and more straight forward, especially when not dealing with objects, indexes, columns etc.

Normally you might run something like this:

```sql
-- Get the instance service start time for the current instance
-- Connected to instance: Instance1
SELECT sqlserver_start_time
FROM sys.dm_os_sys_info
```

The equivalent SysSchemaSync query would be:

```sql
USE SysSchemaSync;
GO
SELECT sqlserver_start_time
FROM dbo.vw_Instance vd
    JOIN dbo._dm_os_sys_info d ON d._InstanceID = vd.InstanceID
WHERE vd.InstanceName = 'Instance1'
```

#### Object Definitions

One special case to point out is how object definitions are handled. In order to reduce the amount of storage space used, object definitions are stored in a table shared by all databases.

```sql
-- Get the object definition of a specific stored procedure
SELECT od.ObjectDefinition
FROM vw_Object vo
    JOIN dbo.sql_modules sm ON sm._ObjectID = vo.ObjectID
    JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionID = sm._ObjectDefinitionID
WHERE vo.InstanceName = 'Instance1'
    AND vo.DatabaseName = 'DBFoo'
    AND vo.ObjectName = 'usp_SomeProcName'
    AND vo.ObjectType = 'P'
```

Storing the object definitions this way also makes it easier to get a list of all versions of that object across all of your DB's

```sql
-- Get the object definition of a specific stored procedure
SELECT vo.SchemaName, vo.ObjectName, od.ObjectDefinition, COUNT(*)
FROM dbo.vw_Object vo
    JOIN dbo._sql_modules sm ON sm._ObjectID = vo.ObjectID
    JOIN dbo.ObjectDefinition od ON od.ObjectDefinitionID = sm._ObjectDefinitionID
WHERE vo.ObjectType = 'P'
    AND vo.ObjectName = 'usp_SomeProcName'
GROUP BY vo.SchemaName, vo.ObjectName, od.ObjectDefinition
```

----

## Architecture / Configuration

SysSchemaSync consists of two parts, a database where all synced data is stored, and a service (PowerShell script) which is run on an interval to pick up items to sync.

There are two types of syncs that can be configured "simple" and "complex", either of which can have an override export query, otherwise a default query is generated based on the SyncObjectName.

Both sync types require two things 1) a record in `import.SyncObject` and 2) a sync table for the data to go into (e.g. `dbo._dm_os_host_info`).

* `import.SyncObject` configuration types
* Required columns for all types:
  * `SyncObjectID`
    * Can by anything as long as it's unique.
    * Typically, if it is a `sys` schema object, then the `object_id` is used, but this is not required.
  * `SyncObjectName`
    * If `ExportQueryPath` is not provided, it must be the name of the source table as the name is used to generate the export query
    * If `ExportQueryPath` is provided, then this can be anything as it's only used for informational purposes.
  * `SyncObjectLevelID`
    * Indicates what level the data is stored at and impacts how queries and checks are generated.
    * 1 = Instance level - e.g. `sys.dm_os_host_info`
    * 2 = Database level - e.g. `sys.objects`
    * If the result of the query is always the same no matter which database it is run from on the instance and the result set doesn't have a `database_id`/`db_id` in its output, it is _usually_ level 1.
  * `IsEnabled`
    * Controls whether that `SyncObject` is active. Disabling a sync does not delete the data, it only excludes it from the sync process.
  * `SyncStaleAgeMinutes`
    * The minimum amount of time that should pass before syncing that object again, there is no guarantee it will sync exactly at that interval, only that it will be placed in the queue once that amount of time has passed.
  * `ExportQueryPath` (optional)
    * An optional override query when the export is not a simple `SELECT *`. For example, filtering on `is_ms_shipped` or on `database_id`.
    * A `.sql` file needs to be created with the export query (ensuring backward compatibility for previous versions of SQL Server) and placed in the appropriate folder where the service is deployed.
    * If not provided, then the query is generated using the `SyncObjectName` like `SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {SyncObjectName}`.
    * An additional column for the `_DatabaseID` or `_InstanceID` (depending on `SyncObjectLevelID`) is prepended to the dataset prior to uploading.
  * `ChecksumQueryText` (optional)
    * An optional query that returns an integer checksum value. The value is used to determine whether the data has changed and whether the sync needs to run. This adds some minor overhead by running an extra query, however, overall it dramatically improves the efficiency of the process by stopping the sync early, skipping the need to upload the data in order to check for data changes.
    * Checksum queries MUST return a value if configured. If a table has the possibility of being empty, then `0` should be returned. If it's possible for the table to not exist, an existence check should be part of the query.
    * If the table has a high rate of change, then a checksum query is not recommended. For example, tables reporting on stats like memory, storage or CPU tend to rapidly change, so a checksum query would have no benefit. In this case, either consider a higher `SyncStaleAgeMinutes` or using a complex sync.
* Simple - "Delete and insert"
  * Some syncs don't need a lot of pre-processing. For example, maybe they only return a few rows. In these cases, a simple delete and insert is all that's needed.
  * `ImportTable`
    * Name of the table in the sync database where the query results will be pushed. For example `dbo._dm_os_host_info`
    * A checksum query is highly recommended (if possible) to avoid unnecessary deletes and inserts every time the sync is run.
* Complex - "Upload and execute"
  * Useful for syncs that require some pre-processing before merging. For example when syncing `sys.columns` where `dbo.[Object]` and `dbo.[Column]` records need to be added and soft deleted/undeleted.
  * `ImportType`
    * A user-defined table type which matches the query output (including order) and is passed into the configured `ImportProc`.
    * Naming standard: `import.import_{sync table name}` (e.g. `import.import__objects`).
  * `ImportProc`
    * Stored procedure used for pre-processing and merging the result set into its target sync table.
    * Required parameters:
      * `@DatabaseID` OR `@InstanceID` - depending on the `SyncObjectLevelID`
      * `@Dataset` - using the configured `ImportType`

Once all of these items are created and populated, the system will ensure (upon deployment) that everything is configured correctly. Any errors and the `SyncObject` record will not get created/updated.

The service runs on a regular interval, for example, every 5 minutes. It checks in with `import.vw_SyncObjectQueue` to see if there are any syncs which are now stale and need to be run. Checksum queries are run first to verify whether the sync can stop early otherwise the full sync is run.

Checksums, sync times and caught exceptions are tracked in `import.DatabaseSyncObjectStatus`. To force a sync, records can either be deleted from this table, or by updating the `LastSyncCheck` to an older value, to ensure the sync is not stopped early, also set the `LastSyncChecksum` to `NULL`.

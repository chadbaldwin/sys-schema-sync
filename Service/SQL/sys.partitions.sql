DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 15) -- SQL Server 2019 and lower
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
        --
        , xml_compression      = CONVERT(bit       , NULL) -- Added: SQL Server 2022
        , xml_compression_desc = CONVERT(varchar(3), NULL) -- Added: SQL Server 2022
    FROM sys.partitions x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
    WHERE o.is_ms_shipped = 0;
END;
ELSE -- SQL Server 2022 and higher
BEGIN;
    SELECT _SchemaName = s.[name]
        , _ObjectName = o.[name]
        , _ObjectType = o.[type]
        , _IndexName = IIF(i.[type] = 0, '<<HEAP>>', i.[name])
        , _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
        --
        , x.*
    FROM sys.partitions x
        JOIN sys.objects o ON o.[object_id] = x.[object_id]
        JOIN sys.schemas s ON s.[schema_id] = o.[schema_id]
        JOIN sys.indexes i ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
    WHERE o.is_ms_shipped = 0;
END;

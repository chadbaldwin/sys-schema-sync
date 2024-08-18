DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
        --
        , host_architecture = CONVERT(nvarchar(256), NULL) -- Added: SQL Server 2019
    FROM sys.dm_os_host_info x
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.dm_os_host_info x
END;

SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT d.* FROM (SELECT NULL) x(x) FOR JSON AUTO)))
    --
    , x.*
FROM sys.databases x;
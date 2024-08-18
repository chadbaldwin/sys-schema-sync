SELECT _RowHash = CONVERT(binary(32), HASHBYTES('SHA2_256', (SELECT x.* FROM (SELECT NULL) n(n) FOR JSON AUTO)))
    --
    , x.configuration_id, x.[name]
    /*  Prefer to use SELECT * for export queries so that new columns cause exceptions and we know to update
        the schema. But in this case, we need to convert the sql_variant columns to bigint since sql_variant
        is not supported by System.Data.Common.DbDataAdapter.Fill, which is used by dbatools Invoke-DbaQuery
        to populate TVP parameters. */
    , [value]      = CONVERT(int, x.[value])
    , minimum      = CONVERT(int, x.minimum)
    , maximum      = CONVERT(int, x.maximum)
    , value_in_use = CONVERT(int, x.value_in_use)
    , x.[description], x.is_dynamic, x.is_advanced
FROM sys.configurations x
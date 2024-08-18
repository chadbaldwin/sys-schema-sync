DECLARE @MajorVer int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
IF (@MajorVer <= 14) -- SQL Server 2017 and lower
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.[desired_state], x.desired_state_desc, x.actual_state, x.actual_state_desc, x.readonly_reason, x.current_storage_size_mb, x.[flush_interval_seconds], x.[interval_length_minutes], x.[max_storage_size_mb], x.stale_query_threshold_days, x.[max_plans_per_query], x.[query_capture_mode], x.query_capture_mode_desc
        --
        , capture_policy_execution_count             = CONVERT(int   , NULL) -- Added: SQL Server 2019
        , capture_policy_total_compile_cpu_time_ms   = CONVERT(bigint, NULL) -- Added: SQL Server 2019
        , capture_policy_total_execution_cpu_time_ms = CONVERT(bigint, NULL) -- Added: SQL Server 2019
        , capture_policy_stale_threshold_hours       = CONVERT(int   , NULL) -- Added: SQL Server 2019
        --
        , x.[size_based_cleanup_mode], x.size_based_cleanup_mode_desc, x.wait_stats_capture_mode, x.wait_stats_capture_mode_desc, x.actual_state_additional_info
    FROM sys.database_query_store_options x;
END;
ELSE -- SQL Server 2019 and higher
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME()
        --
        , x.*
    FROM sys.database_query_store_options x;
END;

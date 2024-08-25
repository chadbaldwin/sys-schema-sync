CREATE PROCEDURE import.usp_import__databases (
    @InstanceID int,
    @Dataset    import.import__databases READONLY
)
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID));
    RAISERROR('[%s] Start',0,1,@ProcName) WITH NOWAIT;

    IF (@InstanceID IS NULL) BEGIN; RAISERROR('[%s] ERROR: Required parameter @InstanceID is NULL',16,1,@ProcName) WITH NOWAIT; END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    DECLARE @tableName nvarchar(128) = N'dbo._databases';

    RAISERROR('[%s] [%s] Delete: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    DELETE x
    FROM dbo._databases x
    WHERE x._InstanceID = @InstanceID
        AND NOT EXISTS (
            SELECT *
            FROM @Dataset d
            WHERE d.[name] = x.[name]
        )
    RAISERROR('[%s] [%s] Delete: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Update: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    UPDATE x
    SET   x._DatabaseID                                 = sd._DatabaseID
        , x._ModifyDate                                 = SYSUTCDATETIME()
        , x._RowHash                                    = d._RowHash
        --
        , x.[name]                                      = d.[name]
        , x.database_id                                 = d.database_id
        , x.source_database_id                          = d.source_database_id
        , x.owner_sid                                   = d.owner_sid
        , x.create_date                                 = d.create_date
        , x.[compatibility_level]                       = d.[compatibility_level]
        , x.collation_name                              = d.collation_name
        , x.user_access                                 = d.user_access
        , x.user_access_desc                            = d.user_access_desc
        , x.is_read_only                                = d.is_read_only
        , x.is_auto_close_on                            = d.is_auto_close_on
        , x.is_auto_shrink_on                           = d.is_auto_shrink_on
        , x.[state]                                     = d.[state]
        , x.state_desc                                  = d.state_desc
        , x.is_in_standby                               = d.is_in_standby
        , x.is_cleanly_shutdown                         = d.is_cleanly_shutdown
        , x.is_supplemental_logging_enabled             = d.is_supplemental_logging_enabled
        , x.snapshot_isolation_state                    = d.snapshot_isolation_state
        , x.snapshot_isolation_state_desc               = d.snapshot_isolation_state_desc
        , x.is_read_committed_snapshot_on               = d.is_read_committed_snapshot_on
        , x.recovery_model                              = d.recovery_model
        , x.recovery_model_desc                         = d.recovery_model_desc
        , x.page_verify_option                          = d.page_verify_option
        , x.page_verify_option_desc                     = d.page_verify_option_desc
        , x.is_auto_create_stats_on                     = d.is_auto_create_stats_on
        , x.is_auto_create_stats_incremental_on         = d.is_auto_create_stats_incremental_on
        , x.is_auto_update_stats_on                     = d.is_auto_update_stats_on
        , x.is_auto_update_stats_async_on               = d.is_auto_update_stats_async_on
        , x.is_ansi_null_default_on                     = d.is_ansi_null_default_on
        , x.is_ansi_nulls_on                            = d.is_ansi_nulls_on
        , x.is_ansi_padding_on                          = d.is_ansi_padding_on
        , x.is_ansi_warnings_on                         = d.is_ansi_warnings_on
        , x.is_arithabort_on                            = d.is_arithabort_on
        , x.is_concat_null_yields_null_on               = d.is_concat_null_yields_null_on
        , x.is_numeric_roundabort_on                    = d.is_numeric_roundabort_on
        , x.is_quoted_identifier_on                     = d.is_quoted_identifier_on
        , x.is_recursive_triggers_on                    = d.is_recursive_triggers_on
        , x.is_cursor_close_on_commit_on                = d.is_cursor_close_on_commit_on
        , x.is_local_cursor_default                     = d.is_local_cursor_default
        , x.is_fulltext_enabled                         = d.is_fulltext_enabled
        , x.is_trustworthy_on                           = d.is_trustworthy_on
        , x.is_db_chaining_on                           = d.is_db_chaining_on
        , x.is_parameterization_forced                  = d.is_parameterization_forced
        , x.is_master_key_encrypted_by_server           = d.is_master_key_encrypted_by_server
        , x.is_query_store_on                           = d.is_query_store_on
        , x.is_published                                = d.is_published
        , x.is_subscribed                               = d.is_subscribed
        , x.is_merge_published                          = d.is_merge_published
        , x.is_distributor                              = d.is_distributor
        , x.is_sync_with_backup                         = d.is_sync_with_backup
        , x.service_broker_guid                         = d.service_broker_guid
        , x.is_broker_enabled                           = d.is_broker_enabled
        , x.log_reuse_wait                              = d.log_reuse_wait
        , x.log_reuse_wait_desc                         = d.log_reuse_wait_desc
        , x.is_date_correlation_on                      = d.is_date_correlation_on
        , x.is_cdc_enabled                              = d.is_cdc_enabled
        , x.is_encrypted                                = d.is_encrypted
        , x.is_honor_broker_priority_on                 = d.is_honor_broker_priority_on
        , x.replica_id                                  = d.replica_id
        , x.group_database_id                           = d.group_database_id
        , x.resource_pool_id                            = d.resource_pool_id
        , x.default_language_lcid                       = d.default_language_lcid
        , x.default_language_name                       = d.default_language_name
        , x.default_fulltext_language_lcid              = d.default_fulltext_language_lcid
        , x.default_fulltext_language_name              = d.default_fulltext_language_name
        , x.is_nested_triggers_on                       = d.is_nested_triggers_on
        , x.is_transform_noise_words_on                 = d.is_transform_noise_words_on
        , x.two_digit_year_cutoff                       = d.two_digit_year_cutoff
        , x.containment                                 = d.containment
        , x.containment_desc                            = d.containment_desc
        , x.target_recovery_time_in_seconds             = d.target_recovery_time_in_seconds
        , x.[delayed_durability]                        = d.[delayed_durability]
        , x.delayed_durability_desc                     = d.delayed_durability_desc
        , x.is_memory_optimized_elevate_to_snapshot_on  = d.is_memory_optimized_elevate_to_snapshot_on
        , x.is_federation_member                        = d.is_federation_member
        , x.is_remote_data_archive_enabled              = d.is_remote_data_archive_enabled
        , x.is_mixed_page_allocation_on                 = d.is_mixed_page_allocation_on
        , x.is_temporal_history_retention_enabled       = d.is_temporal_history_retention_enabled
        , x.catalog_collation_type                      = d.catalog_collation_type
        , x.catalog_collation_type_desc                 = d.catalog_collation_type_desc
        , x.physical_database_name                      = d.physical_database_name
        , x.is_result_set_caching_on                    = d.is_result_set_caching_on
        , x.is_accelerated_database_recovery_on         = d.is_accelerated_database_recovery_on
        , x.is_tempdb_spill_to_remote_store             = d.is_tempdb_spill_to_remote_store
        , x.is_stale_page_detection_on                  = d.is_stale_page_detection_on
        , x.is_memory_optimized_enabled                 = d.is_memory_optimized_enabled
        , x.is_data_retention_enabled                   = d.is_data_retention_enabled
        , x.is_ledger_on                                = d.is_ledger_on
        , x.is_change_feed_enabled                      = d.is_change_feed_enabled
    FROM dbo._databases x
        JOIN @Dataset d ON d.[name] = x.[name]
        LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d.[name]
    WHERE x._InstanceID = @InstanceID
        AND x._RowHash <> d._RowHash;
    RAISERROR('[%s] [%s] Update: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;

    RAISERROR('[%s] [%s] Insert: Start',0,1,@ProcName,@tableName) WITH NOWAIT;
    INSERT INTO dbo._databases (_InstanceID, _DatabaseID, _RowHash
        , [name], database_id, source_database_id, owner_sid, create_date, [compatibility_level], collation_name, user_access, user_access_desc, is_read_only, is_auto_close_on, is_auto_shrink_on, [state], state_desc, is_in_standby, is_cleanly_shutdown, is_supplemental_logging_enabled, snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on, recovery_model, recovery_model_desc, page_verify_option, page_verify_option_desc, is_auto_create_stats_on, is_auto_create_stats_incremental_on, is_auto_update_stats_on, is_auto_update_stats_async_on, is_ansi_null_default_on, is_ansi_nulls_on, is_ansi_padding_on, is_ansi_warnings_on, is_arithabort_on, is_concat_null_yields_null_on, is_numeric_roundabort_on, is_quoted_identifier_on, is_recursive_triggers_on, is_cursor_close_on_commit_on, is_local_cursor_default, is_fulltext_enabled, is_trustworthy_on, is_db_chaining_on, is_parameterization_forced, is_master_key_encrypted_by_server, is_query_store_on, is_published, is_subscribed, is_merge_published, is_distributor, is_sync_with_backup, service_broker_guid, is_broker_enabled, log_reuse_wait, log_reuse_wait_desc, is_date_correlation_on, is_cdc_enabled, is_encrypted, is_honor_broker_priority_on, replica_id, group_database_id, resource_pool_id, default_language_lcid, default_language_name, default_fulltext_language_lcid, default_fulltext_language_name, is_nested_triggers_on, is_transform_noise_words_on, two_digit_year_cutoff, containment, containment_desc, target_recovery_time_in_seconds, [delayed_durability], delayed_durability_desc, is_memory_optimized_elevate_to_snapshot_on, is_federation_member, is_remote_data_archive_enabled, is_mixed_page_allocation_on, is_temporal_history_retention_enabled, catalog_collation_type, catalog_collation_type_desc, physical_database_name, is_result_set_caching_on, is_accelerated_database_recovery_on, is_tempdb_spill_to_remote_store, is_stale_page_detection_on, is_memory_optimized_enabled, is_data_retention_enabled, is_ledger_on, is_change_feed_enabled)
    SELECT @InstanceID, sd._DatabaseID, d._RowHash
        , d.[name], d.database_id, d.source_database_id, d.owner_sid, d.create_date, d.[compatibility_level], d.collation_name, d.user_access, d.user_access_desc, d.is_read_only, d.is_auto_close_on, d.is_auto_shrink_on, d.[state], d.state_desc, d.is_in_standby, d.is_cleanly_shutdown, d.is_supplemental_logging_enabled, d.snapshot_isolation_state, d.snapshot_isolation_state_desc, d.is_read_committed_snapshot_on, d.recovery_model, d.recovery_model_desc, d.page_verify_option, d.page_verify_option_desc, d.is_auto_create_stats_on, d.is_auto_create_stats_incremental_on, d.is_auto_update_stats_on, d.is_auto_update_stats_async_on, d.is_ansi_null_default_on, d.is_ansi_nulls_on, d.is_ansi_padding_on, d.is_ansi_warnings_on, d.is_arithabort_on, d.is_concat_null_yields_null_on, d.is_numeric_roundabort_on, d.is_quoted_identifier_on, d.is_recursive_triggers_on, d.is_cursor_close_on_commit_on, d.is_local_cursor_default, d.is_fulltext_enabled, d.is_trustworthy_on, d.is_db_chaining_on, d.is_parameterization_forced, d.is_master_key_encrypted_by_server, d.is_query_store_on, d.is_published, d.is_subscribed, d.is_merge_published, d.is_distributor, d.is_sync_with_backup, d.service_broker_guid, d.is_broker_enabled, d.log_reuse_wait, d.log_reuse_wait_desc, d.is_date_correlation_on, d.is_cdc_enabled, d.is_encrypted, d.is_honor_broker_priority_on, d.replica_id, d.group_database_id, d.resource_pool_id, d.default_language_lcid, d.default_language_name, d.default_fulltext_language_lcid, d.default_fulltext_language_name, d.is_nested_triggers_on, d.is_transform_noise_words_on, d.two_digit_year_cutoff, d.containment, d.containment_desc, d.target_recovery_time_in_seconds, d.[delayed_durability], d.delayed_durability_desc, d.is_memory_optimized_elevate_to_snapshot_on, d.is_federation_member, d.is_remote_data_archive_enabled, d.is_mixed_page_allocation_on, d.is_temporal_history_retention_enabled, d.catalog_collation_type, d.catalog_collation_type_desc, d.physical_database_name, d.is_result_set_caching_on, d.is_accelerated_database_recovery_on, d.is_tempdb_spill_to_remote_store, d.is_stale_page_detection_on, d.is_memory_optimized_enabled, d.is_data_retention_enabled, d.is_ledger_on, d.is_change_feed_enabled
    FROM @Dataset d
        LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d.[name]
    WHERE NOT EXISTS (
            SELECT *
            FROM dbo._databases x
            WHERE x._InstanceID = @InstanceID
                AND x.[name] = d.[name]
        );
    RAISERROR('[%s] [%s] Insert: Done (%i)',0,1,@ProcName,@tableName,@@ROWCOUNT) WITH NOWAIT;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    RAISERROR('[%s] Done',0,1,@ProcName) WITH NOWAIT;
END;
GO

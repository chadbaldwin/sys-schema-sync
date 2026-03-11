CREATE PROC import.usp_import__databases (
    @InstanceID int,
    @Dataset    import.import__databases READONLY,
    @Verbose    bit = 0
)
AS
BEGIN;
    SET NOCOUNT, XACT_ABORT ON;

    EXEC sys.sp_set_session_context @key = N'Verbose', @value = @Verbose;
    EXEC sys.sp_set_session_context @key = N'_InstanceID', @value = @InstanceID;

    DECLARE @ProcName nvarchar(257) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), @proc_sw datetime2;
    EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw OUTPUT;

    BEGIN TRY
        IF (@InstanceID IS NULL) BEGIN; THROW 51000, 'Required parameter @InstanceID is NULL', 1; END;

        DECLARE @TableName nvarchar(300), @sw2 datetime2;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        BEGIN;
            SET @TableName = '#Dataset';
            EXEC dbo.usp_Raiserror @EventType = 'Start', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2 OUTPUT;
            SELECT TOP (0) * INTO #Dataset FROM dbo._databases;
            EXEC sys.sp_executesql @stmt = N'ALTER TABLE #Dataset DROP COLUMN IF EXISTS _InsertDate, COLUMN IF EXISTS _ModifyDate, COLUMN IF EXISTS _ValidFrom, COLUMN IF EXISTS _ValidTo;';
            CREATE CLUSTERED INDEX CIX ON #Dataset (_InstanceID, [name]);

            INSERT #Dataset WITH(TABLOCK) (_InstanceID, _DatabaseID, _RowHash, [name], database_id, source_database_id, owner_sid, create_date, [compatibility_level], collation_name, user_access, user_access_desc, is_read_only, is_auto_close_on, is_auto_shrink_on, [state], state_desc, is_in_standby, is_cleanly_shutdown, is_supplemental_logging_enabled, snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on, recovery_model, recovery_model_desc, page_verify_option, page_verify_option_desc, is_auto_create_stats_on, is_auto_create_stats_incremental_on, is_auto_update_stats_on, is_auto_update_stats_async_on, is_ansi_null_default_on, is_ansi_nulls_on, is_ansi_padding_on, is_ansi_warnings_on, is_arithabort_on, is_concat_null_yields_null_on, is_numeric_roundabort_on, is_quoted_identifier_on, is_recursive_triggers_on, is_cursor_close_on_commit_on, is_local_cursor_default, is_fulltext_enabled, is_trustworthy_on, is_db_chaining_on, is_parameterization_forced, is_master_key_encrypted_by_server, is_query_store_on, is_published, is_subscribed, is_merge_published, is_distributor, is_sync_with_backup, service_broker_guid, is_broker_enabled, log_reuse_wait, log_reuse_wait_desc, is_date_correlation_on, is_cdc_enabled, is_encrypted, is_honor_broker_priority_on, replica_id, group_database_id, resource_pool_id, default_language_lcid, default_language_name, default_fulltext_language_lcid, default_fulltext_language_name, is_nested_triggers_on, is_transform_noise_words_on, [two_digit_year_cutoff], containment, containment_desc, target_recovery_time_in_seconds, [delayed_durability], delayed_durability_desc, is_memory_optimized_elevate_to_snapshot_on, is_federation_member, is_remote_data_archive_enabled, is_mixed_page_allocation_on, is_temporal_history_retention_enabled, catalog_collation_type, catalog_collation_type_desc, physical_database_name, is_result_set_caching_on, is_accelerated_database_recovery_on, is_tempdb_spill_to_remote_store, is_stale_page_detection_on, is_memory_optimized_enabled, is_data_retention_enabled, is_ledger_on, is_change_feed_enabled, is_data_lake_replication_enabled, is_event_stream_enabled, [data_compaction], data_compaction_desc, [data_lake_log_publishing], data_lake_log_publishing_desc, is_vorder_enabled, is_proactive_statistics_refresh_on, is_optimized_locking_on)
            SELECT @InstanceID, sd._DatabaseID, d._RowHash, d.[name], d.database_id, d.source_database_id, d.owner_sid, d.create_date, d.[compatibility_level], d.collation_name, d.user_access, d.user_access_desc, d.is_read_only, d.is_auto_close_on, d.is_auto_shrink_on, d.[state], d.state_desc, d.is_in_standby, d.is_cleanly_shutdown, d.is_supplemental_logging_enabled, d.snapshot_isolation_state, d.snapshot_isolation_state_desc, d.is_read_committed_snapshot_on, d.recovery_model, d.recovery_model_desc, d.page_verify_option, d.page_verify_option_desc, d.is_auto_create_stats_on, d.is_auto_create_stats_incremental_on, d.is_auto_update_stats_on, d.is_auto_update_stats_async_on, d.is_ansi_null_default_on, d.is_ansi_nulls_on, d.is_ansi_padding_on, d.is_ansi_warnings_on, d.is_arithabort_on, d.is_concat_null_yields_null_on, d.is_numeric_roundabort_on, d.is_quoted_identifier_on, d.is_recursive_triggers_on, d.is_cursor_close_on_commit_on, d.is_local_cursor_default, d.is_fulltext_enabled, d.is_trustworthy_on, d.is_db_chaining_on, d.is_parameterization_forced, d.is_master_key_encrypted_by_server, d.is_query_store_on, d.is_published, d.is_subscribed, d.is_merge_published, d.is_distributor, d.is_sync_with_backup, d.service_broker_guid, d.is_broker_enabled, d.log_reuse_wait, d.log_reuse_wait_desc, d.is_date_correlation_on, d.is_cdc_enabled, d.is_encrypted, d.is_honor_broker_priority_on, d.replica_id, d.group_database_id, d.resource_pool_id, d.default_language_lcid, d.default_language_name, d.default_fulltext_language_lcid, d.default_fulltext_language_name, d.is_nested_triggers_on, d.is_transform_noise_words_on, d.[two_digit_year_cutoff], d.containment, d.containment_desc, d.target_recovery_time_in_seconds, d.[delayed_durability], d.delayed_durability_desc, d.is_memory_optimized_elevate_to_snapshot_on, d.is_federation_member, d.is_remote_data_archive_enabled, d.is_mixed_page_allocation_on, d.is_temporal_history_retention_enabled, d.catalog_collation_type, d.catalog_collation_type_desc, d.physical_database_name, d.is_result_set_caching_on, d.is_accelerated_database_recovery_on, d.is_tempdb_spill_to_remote_store, d.is_stale_page_detection_on, d.is_memory_optimized_enabled, d.is_data_retention_enabled, d.is_ledger_on, d.is_change_feed_enabled, d.is_data_lake_replication_enabled, d.is_event_stream_enabled, d.[data_compaction], d.data_compaction_desc, d.[data_lake_log_publishing], d.data_lake_log_publishing_desc, d.is_vorder_enabled, d.is_proactive_statistics_refresh_on, d.is_optimized_locking_on
            FROM @Dataset d
                LEFT JOIN dbo.[Database] sd ON sd._InstanceID = @InstanceID AND sd.DatabaseName = d.[name];
            EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Insert', @Scope1 = @ProcName, @Scope2 = @TableName, @ts = @sw2, @rc = @@ROWCOUNT;
        END;
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC import.usp_RunCommonDUI @InstanceID = @InstanceID, @TargetTable = 'dbo._databases';
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        EXEC dbo.usp_Raiserror @EventType = 'Done', @ActionName = 'Proc', @Scope1 = @ProcName, @ts = @proc_sw;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(2047) = FORMATMESSAGE('%s (Error %d, State %d, Line %d)', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        EXEC dbo.usp_Raiserror @EventType = 'Error', @ActionName = 'Proc', @Scope1 = @ProcName, @DetailMessage = @ErrorMessage, @ts = @proc_sw;

        THROW; -- re-throw original error so that an exception is returned to the caller
    END CATCH;
END;
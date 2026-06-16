-- ============================================================
-- ROLLBACK TO ORIGINAL SINGLE TABLE STATE
-- ============================================================

-- 1) Remove the routing layer
DROP TRIGGER test_events_insert;
DROP TRIGGER test_events_delete;
DROP TRIGGER test_events_update;
DROP VIEW test_events;

-- 2) Restore the original base table name
ALTER TABLE test_events_old RENAME TO test_events;

-- 3) Move partitioned rows back into the restored base table
INSERT /*+ APPEND */ INTO test_events (event_id, user_id, event_data, created_date, event_type)
SELECT event_id, user_id, event_data, created_date, event_type
FROM test_events_part;

COMMIT;

-- 4) Remove the partitioned table now that all rows are back in test_events
DROP TABLE test_events_part;

-- 5) Verify the rollback result
SELECT COUNT(*) AS restored_count FROM test_events;
SELECT COUNT(*) AS old_table_exists FROM user_tables WHERE table_name = 'TEST_EVENTS_PART';

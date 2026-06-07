-- ============================================================
-- DROP TEST DATA (cleanup)
-- ============================================================

DELETE FROM test_events WHERE event_id >= 9000000;
COMMIT;


-- ============================================================
-- TEST INSERTS - Verify triggers route data correctly
-- ============================================================

SELECT * FROM test_events;
SELECT * FROM test_events_old WHERE event_id IN (9000004, 9000005);
SELECT * FROM test_events_part WHERE event_id IN (9000004, 9000005);

-- Test 1: Insert a record from TODAY (should go to test_events_part)
INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
VALUES (9000001, 500, 'Test data - today', SYSDATE, 'TEST_EVENT');

-- Test 2: Insert a record from 30 days ago (should go to test_events_part - within 90 days)
INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
VALUES (9000002, 501, 'Test data - 30 days ago', SYSDATE - 30, 'TEST_EVENT');

-- Test 3: Insert a record from 90 days ago (should go to test_events_part - exactly at boundary)
INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
VALUES (9000003, 502, 'Test data - 90 days ago', SYSDATE - 90, 'TEST_EVENT');

-- Test 4: Insert a record from 100 days ago (should go to test_events_old - older than 90 days)
INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
VALUES (9000004, 503, 'Test data - 100 days ago', SYSDATE - 100, 'TEST_EVENT');

-- Test 5: Insert a record from 180 days ago (should go to test_events_old - old data)
INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
VALUES (9000005, 504, 'Test data - 180 days ago', SYSDATE - 180, 'TEST_EVENT');

COMMIT;

-- ============================================================
-- VERIFY DATA DISTRIBUTION
-- ============================================================

-- Count records in old table
SELECT COUNT(*) as old_table_count FROM test_events_old WHERE event_id >= 9000000;

-- Count records in partitioned table
SELECT COUNT(*) as partitioned_table_count FROM test_events_part WHERE event_id >= 9000000;

-- Count records through view (should be sum of both)
SELECT COUNT(*) as view_total_count FROM test_events WHERE event_id >= 9000000;

-- Detailed view - where did each test record go?
SELECT event_id, user_id, event_data, created_date, event_type, 'test_events_old' as source
FROM test_events_old
WHERE event_id >= 9000000
UNION ALL
SELECT event_id, user_id, event_data, created_date, event_type, 'test_events_part' as source
FROM test_events_part
WHERE event_id >= 9000000
ORDER BY event_id;

-- ============================================================
-- SHOW PARTITION INFORMATION
-- ============================================================
SELECT partition_name, partition_position, high_value
FROM user_tab_partitions
WHERE table_name = 'TEST_EVENTS_PART'
ORDER BY partition_position;

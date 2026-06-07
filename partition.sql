-- ============================================================
-- DROP ALL OBJECTS (cleanup)
-- ============================================================
DROP TRIGGER test_events_insert;
DROP TRIGGER test_events_delete;
DROP TRIGGER test_events_update;
DROP VIEW test_events;
DROP TABLE test_events_old;
DROP TABLE test_events_part;


-- ============================================================
-- 3. CREATE PARTITIONED TABLE - test_events_part
-- ============================================================
CREATE TABLE test_events_part (
    event_id NUMBER,
    user_id NUMBER,
    event_data VARCHAR2(4000),
    created_date DATE DEFAULT SYSDATE,
    event_type VARCHAR2(100)
)
PARTITION BY RANGE (created_date)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
    PARTITION p_old VALUES LESS THAN (DATE '2026-06-01')
);

SELECT * FROM test_events_part;

-- ============================================================
-- 4. RENAME TABLE
-- ============================================================
ALTER TABLE test_events RENAME TO test_events_old;

-- ============================================================
-- 5. CREATE VIEW - test_events
-- ============================================================
CREATE OR REPLACE VIEW test_events AS
SELECT event_id, user_id, event_data, created_date, event_type
FROM test_events_old
UNION ALL
SELECT event_id, user_id, event_data, created_date, event_type
FROM test_events_part;

-- ============================================================
-- 6. CREATE INSTEAD OF INSERT TRIGGER
-- ============================================================
CREATE OR REPLACE TRIGGER test_events_insert
INSTEAD OF INSERT ON test_events
FOR EACH ROW
BEGIN
    -- Insert into partitioned table if date is in the last 90 days
    IF TRUNC(:NEW.created_date) >= TRUNC(SYSDATE - 90) THEN
        INSERT INTO test_events_part (event_id, user_id, event_data, created_date, event_type)
        VALUES (:NEW.event_id, :NEW.user_id, :NEW.event_data, :NEW.created_date, :NEW.event_type);
    ELSE
        -- Insert into old table (for data older than 90 days)
        INSERT INTO test_events_old (event_id, user_id, event_data, created_date, event_type)
        VALUES (:NEW.event_id, :NEW.user_id, :NEW.event_data, :NEW.created_date, :NEW.event_type);
    END IF;
END test_events_insert;


-- ============================================================
-- 7. CREATE INSTEAD OF DELETE TRIGGER
-- ============================================================
CREATE OR REPLACE TRIGGER test_events_delete
INSTEAD OF DELETE ON test_events
FOR EACH ROW
BEGIN
    -- Delete from appropriate table based on date
    IF TRUNC(:OLD.created_date) >= TRUNC(SYSDATE - 90) THEN
        DELETE FROM test_events_part
        WHERE event_id = :OLD.event_id
        AND created_date = :OLD.created_date;
    ELSE
        DELETE FROM test_events_old
        WHERE event_id = :OLD.event_id
        AND created_date = :OLD.created_date;
    END IF;
END test_events_delete;


-- ============================================================
-- 8. CREATE INSTEAD OF UPDATE TRIGGER
-- ============================================================
CREATE OR REPLACE TRIGGER test_events_update
INSTEAD OF UPDATE ON test_events
FOR EACH ROW
BEGIN
    -- Update appropriate table based on old date
    IF TRUNC(:OLD.created_date) >= TRUNC(SYSDATE - 90) THEN
        UPDATE test_events_part
        SET user_id = :NEW.user_id,
            event_data = :NEW.event_data,
            created_date = :NEW.created_date,
            event_type = :NEW.event_type
        WHERE event_id = :OLD.event_id
        AND created_date = :OLD.created_date;
    ELSE
        UPDATE test_events_old
        SET user_id = :NEW.user_id,
            event_data = :NEW.event_data,
            created_date = :NEW.created_date,
            event_type = :NEW.event_type
        WHERE event_id = :OLD.event_id
        AND created_date = :OLD.created_date;
    END IF;
END test_events_update;

-- ============================================================
-- 9. VERIFICATION
-- ============================================================
SELECT COUNT(*) as old_table_count FROM test_events_old;
SELECT COUNT(*) as partitioned_table_count FROM test_events_part;
SELECT COUNT(*) as view_total_count FROM test_events;

-- View partition information
SELECT partition_name, partition_position, high_value
FROM user_tab_partitions
WHERE table_name = 'TEST_EVENTS_PART'
ORDER BY partition_position;

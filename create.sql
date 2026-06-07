DROP TABLE TEST_EVENTS;

-- ============================================================
-- 1. CREATE TEST TABLE
-- ============================================================
CREATE TABLE test_events (
    event_id NUMBER PRIMARY KEY,
    user_id NUMBER,
    event_data VARCHAR2(4000),
    created_date DATE DEFAULT SYSDATE,
    event_type VARCHAR2(100)
);

SELECT count(*) FROM test_events;

-- ============================================================
-- 2. INSERT 2 MILLION ROWS (takes ~2-3 minutes)
-- ============================================================
BEGIN
    INSERT INTO test_events (event_id, user_id, event_data, created_date, event_type)
    SELECT 
        ROWNUM,
        MOD(ROWNUM, 1000),
        RPAD('X', 3000, 'X'),  -- 3KB per row
        SYSDATE - MOD(ROWNUM, 180),
        'EVENT'
    FROM (SELECT 1 FROM dual CONNECT BY LEVEL <= 2000000);
    COMMIT;
END;


SELECT count(*) FROM test_events;

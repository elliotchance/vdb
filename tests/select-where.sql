/* setup */
CREATE TABLE foo (num FLOAT);
INSERT INTO foo (num) VALUES (13);
INSERT INTO foo (num) VALUES (27);
INSERT INTO foo (num) VALUES (35);

EXPLAIN SELECT * FROM foo WHERE num = 27.0;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (NUM DOUBLE PRECISION)
-- EXPLAIN: WHERE ":memory:".PUBLIC.FOO.NUM = 27
-- EXPLAIN: EXPR (":memory:".PUBLIC.FOO.NUM DOUBLE PRECISION)

SELECT * FROM foo WHERE num = 27.0;
-- NUM: 27

SELECT * FROM foo WHERE num <> 13.0;
-- NUM: 27
-- NUM: 35

SELECT * FROM foo WHERE num > 27.0;
-- NUM: 35

SELECT * FROM foo WHERE num >= 27.0;
-- NUM: 27
-- NUM: 35

SELECT * FROM foo WHERE num < 27.0;
-- NUM: 13

EXPLAIN SELECT * FROM foo WHERE num <= 27.0;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (NUM DOUBLE PRECISION)
-- EXPLAIN: WHERE ":memory:".PUBLIC.FOO.NUM <= 27
-- EXPLAIN: EXPR (":memory:".PUBLIC.FOO.NUM DOUBLE PRECISION)

SELECT * FROM foo WHERE num <= 27.0;
-- NUM: 13
-- NUM: 27

EXPLAIN SELECT * FROM foo WHERE foo.num = 27.0;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (NUM DOUBLE PRECISION)
-- EXPLAIN: WHERE ":memory:".PUBLIC.FOO.NUM = 27
-- EXPLAIN: EXPR (":memory:".PUBLIC.FOO.NUM DOUBLE PRECISION)

SELECT * FROM foo WHERE foo.num = 27.0;
-- NUM: 27

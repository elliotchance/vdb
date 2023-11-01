/* setup */
CREATE TABLE foo (x FLOAT, y VARCHAR(32));
INSERT INTO foo (x, y) VALUES (1.234, 'hello');
INSERT INTO foo (x, y) VALUES (12.34, 'hello');
INSERT INTO foo (x, y) VALUES (1.234, 'world');
INSERT INTO foo (x, y) VALUES (5.6, 'world');
INSERT INTO foo (x, y) VALUES (5.6, 'world');

EXPLAIN SELECT x FROM foo GROUP BY x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: EXPR (X DOUBLE PRECISION)

SELECT x FROM foo GROUP BY x;
-- X: 1.234
-- X: 5.6
-- X: 12.34

EXPLAIN SELECT x, count(*) FROM foo GROUP BY x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION, COUNT(*) INTEGER)
-- EXPLAIN: EXPR (X DOUBLE PRECISION, COL2 INTEGER)

SELECT x, count(*) FROM foo GROUP BY x;
-- X: 1.234 COL2: 2
-- X: 5.6 COL2: 2
-- X: 12.34 COL2: 1

EXPLAIN SELECT count(*), x FROM foo GROUP BY x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION, COUNT(*) INTEGER)
-- EXPLAIN: EXPR (COL1 INTEGER, X DOUBLE PRECISION)

SELECT count(*), x FROM foo GROUP BY x;
-- COL1: 2 X: 1.234
-- COL1: 2 X: 5.6
-- COL1: 1 X: 12.34

EXPLAIN SELECT x, y FROM foo GROUP BY x, y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC, ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION, ":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING)

SELECT x, y FROM foo GROUP BY x, y;
-- X: 1.234 Y: hello
-- X: 1.234 Y: world
-- X: 5.6 Y: world
-- X: 12.34 Y: hello

EXPLAIN SELECT y, x FROM foo GROUP BY x, y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC, ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION, ":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: EXPR (Y CHARACTER VARYING, X DOUBLE PRECISION)

SELECT y, x FROM foo GROUP BY x, y;
-- Y: hello X: 1.234
-- Y: world X: 1.234
-- Y: world X: 5.6
-- Y: hello X: 12.34

EXPLAIN SELECT x, y FROM foo GROUP BY y, x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.Y ASC, ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32), ":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING)

SELECT x, y FROM foo GROUP BY y, x;
-- X: 1.234 Y: hello
-- X: 12.34 Y: hello
-- X: 1.234 Y: world
-- X: 5.6 Y: world

EXPLAIN SELECT x + 1.0, x FROM foo GROUP BY x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: EXPR (COL1 DOUBLE PRECISION, X DOUBLE PRECISION)

SELECT x + 1.0, x FROM foo GROUP BY x;
-- COL1: 2.234 X: 1.234
-- COL1: 6.6 X: 5.6
-- COL1: 13.34 X: 12.34

EXPLAIN SELECT x, count(x) FROM foo GROUP BY x;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION, COUNT(":memory:".PUBLIC.FOO.X) INTEGER)
-- EXPLAIN: EXPR (X DOUBLE PRECISION, COL2 INTEGER)

SELECT x, count(x) FROM foo GROUP BY x;
-- X: 1.234 COL2: 2
-- X: 5.6 COL2: 2
-- X: 12.34 COL2: 1

EXPLAIN SELECT y, min(x) FROM foo GROUP BY y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32), MIN(":memory:".PUBLIC.FOO.X) DOUBLE PRECISION)
-- EXPLAIN: EXPR (Y CHARACTER VARYING, COL2 DOUBLE PRECISION)

SELECT y, min(x) FROM foo GROUP BY y;
-- Y: hello COL2: 1.234
-- Y: world COL2: 1.234

EXPLAIN SELECT y, max(x) AS largest FROM foo GROUP BY y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32), MAX(":memory:".PUBLIC.FOO.X) DOUBLE PRECISION)
-- EXPLAIN: EXPR (Y CHARACTER VARYING, LARGEST DOUBLE PRECISION)

SELECT y, max(x) AS largest FROM foo GROUP BY y;
-- Y: hello LARGEST: 12.34
-- Y: world LARGEST: 5.6

SELECT y, sum(x) FROM foo GROUP BY y;
-- Y: hello COL2: 13.574
-- Y: world COL2: 12.434

SELECT y, avg(x) FROM foo GROUP BY y;
-- Y: hello COL2: 6.787
-- Y: world COL2: 4.144667

EXPLAIN SELECT y, avg(x) FROM foo WHERE y = 'hello' GROUP BY y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: WHERE ":memory:".PUBLIC.FOO.Y = 'hello'
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32), AVG(":memory:".PUBLIC.FOO.X) DOUBLE PRECISION)
-- EXPLAIN: EXPR (Y CHARACTER VARYING, COL2 DOUBLE PRECISION)

SELECT y, avg(x) FROM foo WHERE y = 'hello' GROUP BY y;
-- Y: hello COL2: 6.787

EXPLAIN SELECT count(*) FROM foo;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: GROUP BY (COUNT(*) INTEGER)
-- EXPLAIN: EXPR (COL1 INTEGER)

SELECT count(*) FROM foo;
-- COL1: 5

SELECT count(x) FROM foo;
-- COL1: 5

SELECT min(x) FROM foo;
-- COL1: 1.234

SELECT max(x) FROM foo;
-- COL1: 12.34

SELECT avg(x) FROM foo;
-- COL1: 5.2016

SELECT sum(x) FROM foo;
-- COL1: 26.008

EXPLAIN SELECT min(x), max(x) FROM foo;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: GROUP BY (MIN(":memory:".PUBLIC.FOO.X) DOUBLE PRECISION, MAX(":memory:".PUBLIC.FOO.X) DOUBLE PRECISION)
-- EXPLAIN: EXPR (COL1 DOUBLE PRECISION, COL2 DOUBLE PRECISION)

SELECT min(x), max(x) FROM foo;
-- COL1: 1.234 COL2: 12.34

EXPLAIN SELECT avg(x * 2.0) FROM foo;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: GROUP BY (AVG(":memory:".PUBLIC.FOO.X * 2.0) DOUBLE PRECISION)
-- EXPLAIN: EXPR (COL1 DOUBLE PRECISION)

SELECT avg(x * 2.0) FROM foo;
-- COL1: 10.4032

EXPLAIN SELECT x FROM foo GROUP BY x FETCH FIRST 2 ROWS ONLY;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: FETCH FIRST 2 ROWS ONLY
-- EXPLAIN: EXPR (X DOUBLE PRECISION)

SELECT x FROM foo GROUP BY x FETCH FIRST 2 ROWS ONLY;
-- X: 1.234
-- X: 5.6

EXPLAIN SELECT x FROM foo GROUP BY x 
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: OFFSET 1 ROWS FETCH FIRST 2 ROWS ONLY
-- EXPLAIN: EXPR (X DOUBLE PRECISION)

SELECT x FROM foo GROUP BY x 
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- X: 5.6
-- X: 12.34

EXPLAIN SELECT x FROM foo GROUP BY x ORDER BY x DESC FETCH FIRST 2 ROWS ONLY;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X DESC
-- EXPLAIN: FETCH FIRST 2 ROWS ONLY
-- EXPLAIN: EXPR (X DOUBLE PRECISION)

SELECT x FROM foo GROUP BY x ORDER BY x DESC FETCH FIRST 2 ROWS ONLY;
-- X: 12.34
-- X: 5.6

EXPLAIN SELECT x FROM foo
GROUP BY x
ORDER BY x DESC
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.X DOUBLE PRECISION)
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.X DESC
-- EXPLAIN: OFFSET 1 ROWS FETCH FIRST 2 ROWS ONLY
-- EXPLAIN: EXPR (X DOUBLE PRECISION)

SELECT x FROM foo
GROUP BY x
ORDER BY x DESC
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- X: 5.6
-- X: 1.234

EXPLAIN SELECT y, min(x) * avg(x) FROM foo GROUP BY y;
-- EXPLAIN: TABLE ":memory:".PUBLIC.FOO (X DOUBLE PRECISION, Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ":memory:".PUBLIC.FOO.Y ASC
-- EXPLAIN: GROUP BY (":memory:".PUBLIC.FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: EXPR (Y CHARACTER VARYING, COL2 DOUBLE PRECISION)

SELECT y, min(x) * avg(x) FROM foo GROUP BY y;
-- error 42601: syntax error: unknown column: MIN(":memory:".PUBLIC.FOO.X)

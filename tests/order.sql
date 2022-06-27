/* setup */
CREATE TABLE foo (x FLOAT, y VARCHAR(32));
INSERT INTO foo (x, y) VALUES (1.234, 'hi');
INSERT INTO foo (x, y) VALUES (12.34, 'there');
INSERT INTO foo (x, y) VALUES (0.1234, 'hi');
INSERT INTO foo (x, y) VALUES (5.6, 'bar');

EXPLAIN SELECT * FROM foo ORDER BY x;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.X ASC
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo ORDER BY x;
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi
-- X: 5.6 Y: bar
-- X: 12.34 Y: there

EXPLAIN SELECT * FROM foo ORDER BY x ASC;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.X ASC
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

EXPLAIN SELECT * FROM foo ORDER BY x DESC;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.X DESC
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo ORDER BY x DESC;
-- X: 12.34 Y: there
-- X: 5.6 Y: bar
-- X: 1.234 Y: hi
-- X: 0.1234 Y: hi

SELECT * FROM foo ORDER BY y;
-- X: 5.6 Y: bar
-- X: 1.234 Y: hi
-- X: 0.1234 Y: hi
-- X: 12.34 Y: there

EXPLAIN SELECT * FROM foo ORDER BY y, x;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.Y ASC, FOO.X ASC
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo ORDER BY y, x;
-- X: 5.6 Y: bar
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi
-- X: 12.34 Y: there

SELECT * FROM foo ORDER BY y, x DESC;
-- X: 5.6 Y: bar
-- X: 1.234 Y: hi
-- X: 0.1234 Y: hi
-- X: 12.34 Y: there

SELECT * FROM foo ORDER BY x DESC, y;
-- X: 12.34 Y: there
-- X: 5.6 Y: bar
-- X: 1.234 Y: hi
-- X: 0.1234 Y: hi

EXPLAIN SELECT * FROM foo ORDER BY ABS(10 - x);
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY ABS(10 - FOO.X) ASC
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo ORDER BY ABS(10 - x);
-- X: 12.34 Y: there
-- X: 5.6 Y: bar
-- X: 1.234 Y: hi
-- X: 0.1234 Y: hi

SELECT * FROM foo ORDER BY ABS(10 - x) DESC;
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi
-- X: 5.6 Y: bar
-- X: 12.34 Y: there

SELECT * FROM foo
ORDER BY y, x
OFFSET 0 ROWS;
-- X: 5.6 Y: bar
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi
-- X: 12.34 Y: there

EXPLAIN SELECT * FROM foo
ORDER BY y, x
OFFSET 2 ROW;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.Y ASC, FOO.X ASC
-- EXPLAIN: OFFSET 2 ROWS
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo
ORDER BY y, x
OFFSET 2 ROW;
-- X: 1.234 Y: hi
-- X: 12.34 Y: there

SELECT * FROM foo
ORDER BY y, x
OFFSET 50 ROW;

SELECT * FROM foo
ORDER BY y, x
FETCH FIRST 2 ROWS ONLY;
-- X: 5.6 Y: bar
-- X: 0.1234 Y: hi

EXPLAIN SELECT * FROM foo
ORDER BY y, x
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- EXPLAIN: TABLE FOO (FOO.X DOUBLE PRECISION, FOO.Y CHARACTER VARYING(32))
-- EXPLAIN: ORDER BY FOO.Y ASC, FOO.X ASC
-- EXPLAIN: OFFSET 1 ROWS FETCH FIRST 2 ROWS ONLY
-- EXPLAIN: EXPR (X DOUBLE PRECISION, Y CHARACTER VARYING(32))

SELECT * FROM foo
ORDER BY y, x
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi

SELECT * FROM foo
ORDER BY y, x
OFFSET 10 ROWS
FETCH FIRST 2 ROWS ONLY;

/* set offset_num 1 */
/* set row_num 2 */
SELECT * FROM foo
ORDER BY y, x
OFFSET :offset_num ROW
FETCH FIRST :row_num ROWS ONLY;
-- X: 0.1234 Y: hi
-- X: 1.234 Y: hi
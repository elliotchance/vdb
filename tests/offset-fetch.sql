/* setup */
CREATE TABLE t1 (x INT);
INSERT INTO t1 (x) VALUES (1);
INSERT INTO t1 (x) VALUES (2);
INSERT INTO t1 (x) VALUES (3);
INSERT INTO t1 (x) VALUES (4);
INSERT INTO t1 (x) VALUES (5);

SELECT * FROM t1
OFFSET 0 ROWS;
-- X: 1
-- X: 2
-- X: 3
-- X: 4
-- X: 5

SELECT * FROM t1
OFFSET 2 ROW;
-- X: 3
-- X: 4
-- X: 5

SELECT * FROM t1
OFFSET 5 ROWS;

SELECT * FROM t1
OFFSET 50 ROW;

SELECT * FROM t1
FETCH FIRST 1 ROW ONLY;
-- X: 1

SELECT * FROM t1
FETCH FIRST 2 ROWS ONLY;
-- X: 1
-- X: 2

SELECT * FROM t1
OFFSET 1 ROW
FETCH FIRST 2 ROWS ONLY;
-- X: 2
-- X: 3

SELECT * FROM t1
OFFSET 10 ROWS
FETCH FIRST 2 ROWS ONLY;
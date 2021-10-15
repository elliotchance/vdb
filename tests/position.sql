/* setup */
CREATE TABLE t1 (x VARCHAR(64));
INSERT INTO t1 (x) VALUES ('hello Hello');

SELECT POSITION('h' IN x) FROM t1;
-- COL1: 1

SELECT POSITION('l' IN x) FROM t1;
-- COL1: 3

SELECT POSITION('H' IN x) FROM t1;
-- COL1: 7

SELECT POSITION('llo' IN x) FROM t1;
-- COL1: 3

SELECT POSITION('z' IN x) FROM t1;
-- COL1: 0
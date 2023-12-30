CREATE TABLE foo (bar DECIMAL);
-- error 42601: syntax error: column BAR: DECIMAL must specify a size

CREATE TABLE foo (bar DECIMAL(4, 2));
INSERT INTO foo (bar) VALUES (1.23);
INSERT INTO foo (bar) VALUES (12345);
INSERT INTO foo (bar) VALUES (-1.24);
SELECT * FROM foo;
SELECT -bar FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- error 22003: numeric value out of range
-- msg: INSERT 1
-- BAR: 1.23
-- BAR: -1.24
-- COL1: -1.23
-- COL1: 1.24

VALUES CAST(1.23 AS DECIMAL(10, 6));
-- COL1: 1.23

VALUES CAST(1.23 AS DECIMAL(10, 2));
-- COL1: 1.23

VALUES CAST(1.23 AS DECIMAL(10, 1));
-- COL1: 1.2

VALUES CAST(1234.5 AS DECIMAL(3, 0));
-- error 22003: numeric value out of range

VALUES CAST(-1.23 AS DECIMAL);
-- COL1: -1.23

VALUES CAST(-12.34 AS DECIMAL(4, 2));
-- COL1: -12.34

VALUES CAST(-12.34 AS DECIMAL(4, 1));
-- COL1: -12.3

VALUES CAST(-12.34 AS DECIMAL(2, 0));
-- COL1: -12

VALUES CAST(-12.34 AS DECIMAL(3, 2));
-- error 22003: numeric value out of range

VALUES CAST(1.23 AS DECIMAL(6, 2)) + CAST(1.5 AS DECIMAL(6, 3));
-- COL1: 2.73

VALUES CAST(1.23 AS DECIMAL(6, 2)) - CAST(1.5 AS DECIMAL(6, 3));
-- COL1: -0.27

VALUES CAST(1.23 AS DECIMAL(6, 2)) - CAST(-1.5 AS DECIMAL(6, 3));
-- COL1: 2.73

VALUES CAST(1.23 AS DECIMAL(6, 2)) * CAST(1.5 AS DECIMAL(6, 3));
-- COL1: 1.845

VALUES CAST(CAST(1.23 AS DECIMAL(6, 2)) * CAST(1.5 AS DECIMAL(6, 3)) AS DECIMAL(6, 4));
-- COL1: 1.845

VALUES CAST(1.24 AS DECIMAL(6, 2)) / CAST(1.5 AS DECIMAL(6, 3));
-- COL1: 0.82666

VALUES CAST(1.24 AS DECIMAL(6, 3)) / CAST(1.5 AS DECIMAL(6, 2));
-- COL1: 0.82666

VALUES CAST(CAST(1.24 AS DECIMAL(6, 2)) / CAST(1.5 AS DECIMAL(6, 3)) AS DECIMAL(6, 4));
-- COL1: 0.8266

/* types */
VALUES CAST(1.23 AS DECIMAL(3,2)) / 5;
-- COL1: 0.24 (DECIMAL(3, 2))

/* types */
VALUES CAST(CAST(1.23 AS DECIMAL(3,2)) / 5 AS DECIMAL(4, 3));
-- COL1: 0.246 (DECIMAL(4, 3))

-- # This is an important case because it's described in detail in the docs for
-- # DECIMAL vs DECIMAL.
VALUES CAST(1.23 AS DECIMAL(3,2)) / 5 * 5;
-- COL1: 1.23

-- # This is an important case because it's described in detail in the docs for
-- # DECIMAL vs DECIMAL.
VALUES CAST(1.23 AS DECIMAL(3,2)) / 11;
-- COL1: 0.11

-- # This is an important case because it's described in detail in the docs for
-- # DECIMAL vs DECIMAL.
VALUES CAST(CAST(5 AS DECIMAL(3,2)) / CAST(7 AS DECIMAL(5,4)) AS DECIMAL(5,4));
-- COL1: 0.7142

/* types */
VALUES CAST(10.24 AS DECIMAL(4,2)) + CAST(12.123 AS DECIMAL(8,3));
-- COL1: 22.36 (DECIMAL(8, 3))

/* types */
VALUES CAST(10.24 AS DECIMAL(4,2)) * CAST(12.123 AS DECIMAL(8,3));
-- COL1: 124.13952 (DECIMAL(32, 5))

VALUES CAST(1 AS DECIMAL(2,1)) / CAST(3 AS DECIMAL(2,1));
-- COL1: 0.33

VALUES CAST(CAST(1 AS DECIMAL(2,1)) / CAST(3 AS DECIMAL(2,1)) AS DECIMAL(10, 8));
-- COL1: 0.33333333

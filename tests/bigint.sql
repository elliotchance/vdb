CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (-9223372036854775807);
INSERT INTO foo (x) VALUES (9223372036854775807);
SELECT * FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- msg: INSERT 1
-- X: -9223372036854775807
-- X: 9223372036854775807

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (123);
SELECT CAST(x AS SMALLINT) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- COL1: 123

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS SMALLINT) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- error 22003: numeric value out of range

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (123456);
SELECT CAST(x AS INTEGER) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- COL1: 123456

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS INT) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- error 22003: numeric value out of range

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS BIGINT) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- COL1: 1000000000000

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS REAL) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- COL1: 1e+12

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS DOUBLE PRECISION) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- COL1: 1e+12

CREATE TABLE foo (x BIGINT);
INSERT INTO foo (x) VALUES (1000000000000);
SELECT CAST(x AS BOOLEAN) FROM foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- error 42846: cannot coerce BIGINT to BOOLEAN

VALUES CAST(123 AS BIGINT) + 53.7;
-- COL1: 176

VALUES 53.7 + CAST(123 AS BIGINT);
-- COL1: 176

VALUES CAST(5000000000000000000 AS BIGINT) + 5000000000000000000.7;
-- error 22003: numeric value out of range

VALUES 5000000000000000000.7 + CAST(5000000000000000000 AS BIGINT);
-- error 22003: numeric value out of range

VALUES CAST(123 AS BIGINT) - 53.7;
-- COL1: 70

VALUES 53.7 - CAST(123 AS BIGINT);
-- COL1: -70

VALUES CAST(-5000000000000000000 AS BIGINT) - 5000000000000000000.7;
-- error 22003: numeric value out of range

VALUES -5000000000000000000.7 - CAST(5000000000000000000 AS BIGINT);
-- error 22003: numeric value out of range

VALUES CAST(123 AS BIGINT) * 53.7;
-- COL1: 6519

VALUES -53.7 * CAST(123 AS BIGINT);
-- COL1: -6519

VALUES CAST(-5000000000000000000 AS BIGINT) * 200000.7;
-- error 22003: numeric value out of range

VALUES -5000000000000000000.7 * CAST(5000000000000000000 AS BIGINT);
-- error 22003: numeric value out of range

VALUES CAST(123 AS BIGINT) / 53.7;
-- COL1: 2

VALUES -123.7 / CAST(53 AS BIGINT);
-- COL1: -3

VALUES CAST(-5000000000000000000 AS BIGINT) / 0.02;
-- error 22012: division by zero

VALUES -5000000000000000000.7 / CAST(3.2 AS BIGINT);
-- COL1: -1666666666666666667

VALUES CAST(-5000000000000000000 AS BIGINT) / 0;
-- error 22012: division by zero

VALUES -5000000000000000000 / CAST(0.1 AS BIGINT);
-- error 22012: division by zero

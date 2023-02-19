CREATE TABLE ":memory:".PUBLIC.foo (baz INTEGER);
INSERT INTO ":memory:".PUBLIC.foo (baz) VALUES (123);
INSERT INTO ":memory:".PUBLIC.foo (baz) VALUES (456);
SELECT * FROM ":memory:".PUBLIC.foo;
UPDATE ":memory:".PUBLIC.foo SET baz = 789 WHERE baz = 123;
SELECT * FROM ":memory:".PUBLIC.foo;
DELETE FROM ":memory:".PUBLIC.foo WHERE baz > 700;
SELECT * FROM ":memory:".PUBLIC.foo;
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- msg: INSERT 1
-- BAZ: 123
-- BAZ: 456
-- msg: UPDATE 1
-- BAZ: 789
-- BAZ: 456
-- msg: DELETE 1
-- BAZ: 456

/* create_catalog FOO */
CREATE TABLE foo.public.bar (baz INTEGER);
EXPLAIN SELECT * FROM foo.public.bar;
-- msg: CREATE TABLE 1
-- EXPLAIN: TABLE FOO.PUBLIC.BAR (BAZ INTEGER)
-- EXPLAIN: EXPR (FOO.PUBLIC.BAR.BAZ INTEGER)

/* create_catalog FOO */
CREATE TABLE foo.public.bar (baz INTEGER);
INSERT INTO foo.public.bar (baz) VALUES (123);
EXPLAIN SELECT * FROM foo.public.bar;
SET CATALOG ':memory:';
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- EXPLAIN: TABLE FOO.PUBLIC.BAR (BAZ INTEGER)
-- EXPLAIN: EXPR (FOO.PUBLIC.BAR.BAZ INTEGER)
-- msg: SET CATALOG 1

VALUES CURRENT_CATALOG;
/* create_catalog FOO */
/* create_catalog BAR */
VALUES CURRENT_CATALOG;
SET CATALOG 'FOO';
VALUES CURRENT_CATALOG;
SET CATALOG 'BAR';
VALUES CURRENT_CATALOG;
CREATE TABLE baz (num1 INTEGER);
INSERT INTO baz (num1) VALUES (123);
SELECT * FROM baz;
SET CATALOG 'FOO';
SELECT * FROM baz;
CREATE TABLE baz (num2 INTEGER);
INSERT INTO baz (num2) VALUES (456);
SELECT * FROM baz;
SET CATALOG ':memory:';
SELECT * FROM foo.public.baz;
SELECT * FROM bar.public.baz;
SELECT * FROM foo.public.baz JOIN bar.public.baz ON TRUE;
-- COL1: :memory:
-- COL1: BAR
-- msg: SET CATALOG 1
-- COL1: FOO
-- msg: SET CATALOG 1
-- COL1: BAR
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- NUM1: 123
-- msg: SET CATALOG 1
-- error 42P01: no such table: FOO.PUBLIC.BAZ
-- msg: CREATE TABLE 1
-- msg: INSERT 1
-- NUM2: 456
-- msg: SET CATALOG 1
-- NUM2: 456
-- NUM1: 123
-- NUM2: 456 NUM1: 123

EXPLAIN VALUES SUBSTRING('hello' FROM 3);
-- EXPLAIN: VALUES (COL1 CHARACTER VARYING) = ROW(SUBSTRING('hello' FROM 3 USING CHARACTERS))

EXPLAIN VALUES SUBSTRING('hello world' FROM 3 FOR 5);
-- EXPLAIN: VALUES (COL1 CHARACTER VARYING) = ROW(SUBSTRING('hello world' FROM 3 FOR 5 USING CHARACTERS))

EXPLAIN VALUES SUBSTRING('hello world' FROM 3 USING CHARACTERS);
-- EXPLAIN: VALUES (COL1 CHARACTER VARYING) = ROW(SUBSTRING('hello world' FROM 3 USING CHARACTERS))

EXPLAIN VALUES SUBSTRING('hello world' FROM 3 FOR 5 USING CHARACTERS);
-- EXPLAIN: VALUES (COL1 CHARACTER VARYING) = ROW(SUBSTRING('hello world' FROM 3 FOR 5 USING CHARACTERS))

EXPLAIN VALUES SUBSTRING('hello world' FROM 3 FOR 2 + 3 USING OCTETS);
-- EXPLAIN: VALUES (COL1 CHARACTER VARYING) = ROW(SUBSTRING('hello world' FROM 3 FOR 2 + 3 USING OCTETS))

/* types */
VALUES SUBSTRING('hello' FROM 0);
-- COL1:  (CHARACTER VARYING)

/* types */
VALUES SUBSTRING('hello' FROM 2);
-- COL1: ello (CHARACTER VARYING(4))

/* types */
VALUES SUBSTRING('hello' FROM 4);
-- COL1: lo (CHARACTER VARYING(2))

/* types */
VALUES SUBSTRING('hello' FROM 5);
-- COL1: o (CHARACTER VARYING(1))

/* types */
VALUES SUBSTRING('hello' FROM 6);
-- COL1:  (CHARACTER VARYING)

/* types */
VALUES SUBSTRING('hello' FROM 20);
-- COL1:  (CHARACTER VARYING)

/* types */
VALUES SUBSTRING('hello' FROM -1);
-- COL1:  (CHARACTER VARYING)

/* types */
VALUES SUBSTRING('hello world' FROM 3 FOR 5);
-- COL1: llo w (CHARACTER VARYING(5))

/* types */
VALUES SUBSTRING('hello world' FROM 3 USING CHARACTERS);
-- COL1: llo world (CHARACTER VARYING(9))

/* types */
VALUES SUBSTRING('hello world' FROM 3 FOR 5 USING CHARACTERS);
-- COL1: llo w (CHARACTER VARYING(5))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 1);
-- COL1: Жabڣc (CHARACTER VARYING(7))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 2);
-- COL1: abڣc (CHARACTER VARYING(5))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 1 FOR 1);
-- COL1: Ж (CHARACTER VARYING(2))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 1 FOR 2);
-- COL1: Жa (CHARACTER VARYING(3))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 3 USING OCTETS);
-- COL1: abڣc (CHARACTER VARYING(5))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 4 USING OCTETS);
-- COL1: bڣc (CHARACTER VARYING(4))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 1 FOR 2 USING OCTETS);
-- COL1: Ж (CHARACTER VARYING(2))

/* types */
VALUES SUBSTRING('Жabڣc' FROM 3 FOR 2 USING OCTETS);
-- COL1: ab (CHARACTER VARYING(2))

SELECT 'foo' || 'bar';
-- COL1: foobar

SELECT 123 || 'bar';
-- error 42804: data type mismatch cannot INTEGER || CHARACTER VARYING: expected another type but got INTEGER and CHARACTER VARYING

VALUES CHAR_LENGTH('hello Hello');
-- COL1: 11

VALUES CHARACTER_LENGTH('hello Hello');
-- COL1: 11

VALUES OCTET_LENGTH('hello Hello');
-- COL1: 11

VALUES CHAR_LENGTH('😊£');
-- COL1: 2

VALUES OCTET_LENGTH('😊£');
-- COL1: 6

VALUES char_length('😊£');
-- COL1: 2

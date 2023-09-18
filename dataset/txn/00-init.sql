DROP TABLE IF EXISTS test;

CREATE TABLE test (k int primary key, v int);

TRUNCATE TABLE test;
INSERT INTO test VALUES (1, 5);

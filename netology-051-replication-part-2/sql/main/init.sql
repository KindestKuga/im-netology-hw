\getenv shard_user POSTGRES_USER
\getenv shard_password POSTGRES_PASSWORD
\getenv shard_db POSTGRES_DB

CREATE TABLE users (
    id integer PRIMARY KEY,
    name text NOT NULL,
    email text NOT NULL UNIQUE
);

CREATE TABLE stores (
    id integer PRIMARY KEY,
    name text NOT NULL,
    city text NOT NULL
);

CREATE EXTENSION postgres_fdw;

CREATE SERVER books_1_server FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'pg-books1', dbname :'shard_db');
CREATE SERVER books_2_server FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'pg-books2', dbname :'shard_db');
CREATE SERVER books_3_server FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'pg-books3', dbname :'shard_db');

CREATE USER MAPPING FOR CURRENT_USER SERVER books_1_server
    OPTIONS (user :'shard_user', password :'shard_password');
CREATE USER MAPPING FOR CURRENT_USER SERVER books_2_server
    OPTIONS (user :'shard_user', password :'shard_password');
CREATE USER MAPPING FOR CURRENT_USER SERVER books_3_server
    OPTIONS (user :'shard_user', password :'shard_password');

CREATE FOREIGN TABLE books_1 (
    id bigint NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    year integer NOT NULL,
    store_id integer NOT NULL
) SERVER books_1_server OPTIONS (schema_name 'public', table_name 'books');

CREATE FOREIGN TABLE books_2 (
    id bigint NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    year integer NOT NULL,
    store_id integer NOT NULL
) SERVER books_2_server OPTIONS (schema_name 'public', table_name 'books');

CREATE FOREIGN TABLE books_3 (
    id bigint NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    year integer NOT NULL,
    store_id integer NOT NULL
) SERVER books_3_server OPTIONS (schema_name 'public', table_name 'books');

CREATE VIEW books AS
SELECT * FROM books_1
UNION ALL
SELECT * FROM books_2
UNION ALL
SELECT * FROM books_3;

CREATE RULE books_insert AS ON INSERT TO books
    DO INSTEAD NOTHING;

CREATE RULE books_insert_to_1 AS ON INSERT TO books
    WHERE (NEW.year <= 1950)
    DO ALSO INSERT INTO books_1 VALUES (NEW.*);

CREATE RULE books_insert_to_2 AS ON INSERT TO books
    WHERE (NEW.year > 1950 AND NEW.year <= 2000)
    DO ALSO INSERT INTO books_2 VALUES (NEW.*);

CREATE RULE books_insert_to_3 AS ON INSERT TO books
    WHERE (NEW.year > 2000)
    DO ALSO INSERT INTO books_3 VALUES (NEW.*);

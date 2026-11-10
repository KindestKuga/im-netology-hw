CREATE TABLE books (
    id bigint PRIMARY KEY,
    title text NOT NULL,
    author text NOT NULL,
    year integer NOT NULL CHECK (year > 1950 AND year <= 2000),
    store_id integer NOT NULL
);

# PL-SQL-CURSORS

CREATE TABLE publisher (
    pub_id      NUMBER(4),
    pub_name    VARCHAR2(40) NOT NULL,
    city        VARCHAR2(30),
    country     VARCHAR2(30),
    CONSTRAINT pk_publisher PRIMARY KEY (pub_id)
);

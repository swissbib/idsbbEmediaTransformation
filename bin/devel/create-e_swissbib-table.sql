-- create-e_swissbib-table.sql
-- mysql --host=ub-filesvm.ub.unibas.ch --user=admin -p --execute="source create-e_swissbib-table.sql"
-- 13.05.2016/ava

USE e_swissbib_test;

DROP TABLE IF EXISTS emedia;

CREATE TABLE emedia (
    ssid        VARCHAR (16) PRIMARY KEY,
    HolBS       TINYINT(1) DEFAULT 0,
    HolBE       TINYINT(1) DEFAULT 0,
    HolBBZ      TINYINT(1) DEFAULT 0,
    HolEHB      TINYINT(1) DEFAULT 0,
    HolFREE     TINYINT(1) DEFAULT 0,
    MARC        TINYINT(1) DEFAULT 0,
    modified    DATE
);

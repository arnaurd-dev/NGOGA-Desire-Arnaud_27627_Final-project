SELECT name, cdb, con_id FROM v$database;


CREATE PLUGGABLE DATABASE mon_27627_ngoga_NutritionCropDB
ADMIN USER arnaud IDENTIFIED BY 123
FILE_NAME_CONVERT = ('C:\ORACLE19C\ORADATA\ORCL\PDBSEED\',
                     'C:\ORACLE19C\ORADATA\ORCL\PDBSEED\mon_27627_ngoga_NutritionCropDB/');
                     
ALTER PLUGGABLE DATABASE mon_27627_ngoga_NutritionCropDB OPEN;
ALTER SESSION SET CONTAINER = mon_27627_ngoga_NutritionCropDB;    


CREATE TABLESPACE nutrition_data 
DATAFILE 'nutrition_data01.dbf' SIZE 100M 
AUTOEXTEND ON NEXT 50M MAXSIZE 1G
EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;



CREATE TABLESPACE nutrition_idx 
DATAFILE 'nutrition_idx01.dbf' SIZE 50M 
AUTOEXTEND ON NEXT 25M MAXSIZE 500M;


CREATE TEMPORARY TABLESPACE nutrition_temp
TEMPFILE 'nutrition_temp01.dbf' SIZE 50M 
AUTOEXTEND ON NEXT 25M;



GRANT CONNECT, RESOURCE, DBA TO arnaud;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE,
      CREATE TYPE, CREATE SYNONYM TO arnaud;
      
      

ALTER USER arnaud QUOTA UNLIMITED ON nutrition_data;
ALTER USER arnaud QUOTA UNLIMITED ON nutrition_idx;
ALTER USER arnaud DEFAULT TABLESPACE nutrition_data;
ALTER USER arnaud TEMPORARY TABLESPACE nutrition_temp;   


ALTER SYSTEM SET SGA_TARGET=500M SCOPE=BOTH;



ALTER DATABASE DATAFILE 'nutrition_data01.dbf' AUTOEXTEND ON MAXSIZE 2G;
ALTER DATABASE DATAFILE 'nutrition_idx01.dbf' AUTOEXTEND ON MAXSIZE 1G;


-- Farmer user
CREATE USER farmer_user IDENTIFIED BY farmer123
DEFAULT TABLESPACE nutrition_data
TEMPORARY TABLESPACE nutrition_temp
QUOTA 100M ON nutrition_data;

-- Lab technician user
CREATE USER lab_user IDENTIFIED BY lab123
DEFAULT TABLESPACE nutrition_data
TEMPORARY TABLESPACE nutrition_temp
QUOTA 100M ON nutrition_data;

-- Quality inspector user
CREATE USER inspector_user IDENTIFIED BY inspector123
DEFAULT TABLESPACE nutrition_data
TEMPORARY TABLESPACE nutrition_temp
QUOTA 100M ON nutrition_data;

-- Grant basic privileges
GRANT CREATE SESSION TO farmer_user, lab_user, inspector_user;


ALTER SESSION SET CONTAINER = mon_27627_ngoga_NutritionCropDB;

SELECT username, account_status, created 
FROM dba_users 
ORDER BY username;

GRANT CREATE SESSION TO arnaud; 

SELECT name, open_mode FROM v$pdbs;
CONNECT arnaud/123@localhost:1521/mon_27627_ngoga_NutritionCropDB

-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II
-- Script 00 - USUARIO DUENO DEL ESQUEMA
-- Ejecucion : conectado como SYSTEM al contenedor FREEPDB1 (Oracle 26ai Free) o
--             XEPDB1 (Oracle XE 21c), usando Service name, no SID.
--             Se ejecuta UNA vez, antes de todos los demas scripts.
--             Se puede ejecutar varias veces: el usuario se crea solo si no existe.
--
-- Al ejecutar, SQL Developer pregunta el nombre del usuario (por ejemplo TURISMO o
-- PRUEBA, en mayusculas) y su clave.
-- =====================================================================================
SET SERVEROUTPUT ON
DEFINE usuario_trabajo = '&usuario_trabajo'
DEFINE clave_usuario   = '&clave_usuario'

DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe FROM dba_users WHERE username = UPPER('&usuario_trabajo');
    IF v_existe = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER &usuario_trabajo IDENTIFIED BY "&clave_usuario"'
                       || ' DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp'
                       || ' QUOTA UNLIMITED ON users';
        DBMS_OUTPUT.PUT_LINE('Usuario &usuario_trabajo creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Usuario &usuario_trabajo ya existia.');
    END IF;
END;
/

-- Privilegios de sistema que necesitan los scripts 01 a 11
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE MATERIALIZED VIEW, CREATE JOB
   TO &usuario_trabajo;

-- Verificacion
SELECT username, account_status, default_tablespace, profile
  FROM dba_users
 WHERE username = UPPER('&usuario_trabajo');

SELECT privilege FROM dba_sys_privs
 WHERE grantee = UPPER('&usuario_trabajo')
 ORDER BY privilege;

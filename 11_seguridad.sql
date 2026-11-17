-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 3
-- Script 11 - SEGURIDAD: PERFIL, ROLES, USUARIOS, VISTAS Y GRANT
-- Requisito : haber ejecutado antes los scripts 01 a 08.
-- Ejecucion : por partes, cada una con su conexion:
--               PARTE A -> SYSTEM (FREEPDB1 / XEPDB1): perfil, roles y usuarios
--               PARTE B -> TURISMO (dueno del esquema): vistas y GRANT sobre sus objetos
--               PARTE C -> cada usuario de prueba: lo que puede y lo que no
--               PARTE D -> pruebas del perfil (conexiones desde SQL Developer)
--             Se puede re-ejecutar: perfil, roles y usuarios se borran y se recrean.
--
-- Modelo de acceso (minimo privilegio):
--   rol_recepcion          consulta disponibilidad, tarifas y clientes por VISTAS;
--                          reserva solo a traves de pkg_operaciones. Nunca toca tablas.
--   rol_admin_alojamiento  mantiene habitaciones, tarifas y servicios (cada cambio de
--                          tarifa queda en auditoria_tarifa con su usuario).
--   rol_gerente            solo lectura de indicadores (vista materializada, ingresos).
--   rol_auditor            solo lectura de auditoria, pagos e historico. Sin DML.
-- =====================================================================================

-------------------------------------------------------------------------------
-- PARTE A [SYSTEM]
-------------------------------------------------------------------------------
SET SERVEROUTPUT ON

-- A.0 Los limites de recursos del perfil (SESSIONS_PER_USER, IDLE_TIME) solo se
--     aplican si RESOURCE_LIMIT = TRUE (valor por defecto desde Oracle 12c).
SELECT name, value FROM v$parameter WHERE name = 'resource_limit';

-- A.1 Limpieza para re-ejecutar
BEGIN
    FOR u IN (SELECT username FROM dba_users
               WHERE username IN ('U_RECEPCION', 'U_ADMIN_ALOJ', 'U_GERENTE', 'U_AUDITOR')) LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
    END LOOP;
    FOR r IN (SELECT role FROM dba_roles
               WHERE role IN ('ROL_RECEPCION', 'ROL_ADMIN_ALOJAMIENTO', 'ROL_GERENTE', 'ROL_AUDITOR')) LOOP
        EXECUTE IMMEDIATE 'DROP ROLE ' || r.role;
    END LOOP;
    FOR p IN (SELECT DISTINCT profile FROM dba_profiles WHERE profile = 'PERFIL_TURISMO') LOOP
        EXECUTE IMMEDIATE 'DROP PROFILE ' || p.profile || ' CASCADE';
    END LOOP;
END;
/

-- A.2 Perfil para los usuarios de la aplicacion
CREATE PROFILE perfil_turismo LIMIT
    SESSIONS_PER_USER      2          -- maximo 2 conexiones simultaneas por usuario
    IDLE_TIME              10         -- minutos de inactividad antes de cortar la sesion
    FAILED_LOGIN_ATTEMPTS  3          -- al tercer intento fallido se bloquea la cuenta
    PASSWORD_LOCK_TIME     1/24;      -- ... durante 1 hora (o hasta ACCOUNT UNLOCK)

-- A.3 Roles (CREATE SESSION va en el rol: quien no tenga rol no entra)
CREATE ROLE rol_recepcion;
CREATE ROLE rol_admin_alojamiento;
CREATE ROLE rol_gerente;
CREATE ROLE rol_auditor;

GRANT CREATE SESSION TO rol_recepcion, rol_admin_alojamiento, rol_gerente, rol_auditor;

-- A.4 Usuarios de prueba, uno por rol, todos con el perfil
CREATE USER u_recepcion  IDENTIFIED BY "Recepcion2026" PROFILE perfil_turismo;
CREATE USER u_admin_aloj IDENTIFIED BY "AdminAloj2026" PROFILE perfil_turismo;
CREATE USER u_gerente    IDENTIFIED BY "Gerente2026"   PROFILE perfil_turismo;
CREATE USER u_auditor    IDENTIFIED BY "Auditor2026"   PROFILE perfil_turismo;

GRANT rol_recepcion         TO u_recepcion;
GRANT rol_admin_alojamiento TO u_admin_aloj;
GRANT rol_gerente           TO u_gerente;
GRANT rol_auditor           TO u_auditor;

-- A.5 Verificacion
SELECT username, profile, account_status FROM dba_users
 WHERE username IN ('U_RECEPCION', 'U_ADMIN_ALOJ', 'U_GERENTE', 'U_AUDITOR')
 ORDER BY username;

SELECT resource_name, limit FROM dba_profiles
 WHERE profile = 'PERFIL_TURISMO'
   AND resource_name IN ('SESSIONS_PER_USER', 'IDLE_TIME', 'FAILED_LOGIN_ATTEMPTS', 'PASSWORD_LOCK_TIME')
 ORDER BY resource_name;


-------------------------------------------------------------------------------
-- PARTE B [TURISMO] - Vistas y privilegios sobre objetos
-- (el dueno de un objeto puede otorgar privilegios sobre el a cualquier rol)
-------------------------------------------------------------------------------
-- B.1 Vistas para recepcion: lo justo para atender, sin datos sensibles
CREATE OR REPLACE VIEW vw_habitaciones AS
SELECT h.id_habitacion, m.nombre AS municipio, a.nombre_comercial AS alojamiento,
       ta.nombre AS tipo_alojamiento, h.numero, h.tipo_habitacion, h.capacidad_maxima
  FROM habitacion h
  JOIN alojamiento a       ON a.id_alojamiento = h.id_alojamiento
  JOIN municipio m         ON m.id_municipio = a.id_municipio
  JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento;

CREATE OR REPLACE VIEW vw_ocupacion_habitacion AS     -- noches tomadas, sin datos del cliente
SELECT rh.id_habitacion, rh.fecha_checkin, rh.fecha_checkout, r.estado
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE r.estado <> 'CANCELADA';

CREATE OR REPLACE VIEW vw_tarifas AS
SELECT tf.id_habitacion, t.anio, t.nombre AS temporada, t.tipo_temporada,
       t.fecha_inicio, t.fecha_fin, tf.precio_noche
  FROM tarifa tf
  JOIN temporada t ON t.id_temporada = tf.id_temporada;

CREATE OR REPLACE VIEW vw_clientes_contacto AS         -- sin documento de identidad
SELECT id_cliente, nombre, correo, telefono, ciudad_origen
  FROM cliente;

-- B.2 Vista para gerencia: ingresos de estadias completadas por mes
CREATE OR REPLACE VIEW vw_ingresos_mensuales AS
SELECT m.nombre AS municipio, a.nombre_comercial AS alojamiento,
       TO_CHAR(r.fecha_checkout, 'YYYY-MM') AS mes,
       COUNT(DISTINCT r.id_reserva) AS reservas,
       SUM(rh.valor_linea) AS ingresos_hospedaje
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
  JOIN habitacion h          ON h.id_habitacion = rh.id_habitacion
  JOIN alojamiento a         ON a.id_alojamiento = h.id_alojamiento
  JOIN municipio m           ON m.id_municipio = a.id_municipio
 WHERE r.estado = 'COMPLETADA'
 GROUP BY m.nombre, a.nombre_comercial, TO_CHAR(r.fecha_checkout, 'YYYY-MM');

-- B.3 Vista para auditoria: movimientos de dinero con el estado de su reserva
CREATE OR REPLACE VIEW vw_pagos_auditoria AS
SELECT p.id_pago, p.id_reserva, r.id_cliente, r.estado AS estado_reserva,
       p.fecha_pago, p.monto, p.metodo_pago, p.estado_pago
  FROM pago p
  JOIN reserva r ON r.id_reserva = p.id_reserva;

-- B.4 Privilegios por rol
-- Recepcion: SOLO vistas + el paquete de operaciones (reserva con los permisos del
-- dueno del paquete, sin INSERT directo sobre ninguna tabla)
GRANT SELECT  ON vw_habitaciones         TO rol_recepcion;
GRANT SELECT  ON vw_ocupacion_habitacion TO rol_recepcion;
GRANT SELECT  ON vw_tarifas              TO rol_recepcion;
GRANT SELECT  ON vw_clientes_contacto    TO rol_recepcion;
GRANT EXECUTE ON pkg_operaciones         TO rol_recepcion;

-- Administrador de alojamiento: mantiene su oferta
GRANT SELECT, INSERT, UPDATE ON habitacion TO rol_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE ON tarifa     TO rol_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE ON servicio   TO rol_admin_alojamiento;
GRANT SELECT ON temporada                  TO rol_admin_alojamiento;
GRANT SELECT ON alojamiento                TO rol_admin_alojamiento;
GRANT UPDATE (telefono_contacto, correo_contacto) ON alojamiento TO rol_admin_alojamiento;
GRANT SELECT ON vw_ocupacion_habitacion    TO rol_admin_alojamiento;

-- Gerente: indicadores, solo lectura
GRANT SELECT ON mv_ocupacion_mensual  TO rol_gerente;
GRANT SELECT ON vw_ingresos_mensuales TO rol_gerente;
GRANT SELECT ON vw_habitaciones       TO rol_gerente;
GRANT SELECT ON reserva_historico     TO rol_gerente;

-- Auditor: solo lectura de rastros
GRANT SELECT ON auditoria_tarifa   TO rol_auditor;
GRANT SELECT ON vw_pagos_auditoria TO rol_auditor;
GRANT SELECT ON reserva_historico  TO rol_auditor;

-- B.5 Verificacion: que tiene cada rol
SELECT grantee, table_name, privilege
  FROM user_tab_privs_made
 WHERE grantee LIKE 'ROL\_%' ESCAPE '\'
 ORDER BY grantee, table_name, privilege;

SELECT grantee, table_name, column_name, privilege
  FROM user_col_privs_made
 ORDER BY grantee, table_name, column_name;


-------------------------------------------------------------------------------
-- PARTE C - PRUEBAS POR USUARIO
-- Crear en SQL Developer una conexion por usuario (mismo host y Service name).
-- CURRENT_SCHEMA evita escribir "TURISMO." delante de cada objeto.
-------------------------------------------------------------------------------

-- C.1 [U_RECEPCION]
ALTER SESSION SET CURRENT_SCHEMA = TURISMO;

SELECT * FROM reserva FETCH FIRST 5 ROWS ONLY;           -- Esperado: ORA-00942 (no ve la tabla)

UPDATE tarifa SET precio_noche = 1 WHERE id_tarifa = 1;  -- Esperado: ORA-00942

SELECT * FROM vw_ocupacion_habitacion                    -- Esperado: 4 filas
 WHERE id_habitacion = 1 AND fecha_checkout > DATE '2026-11-01'
 ORDER BY fecha_checkin;

SELECT pkg_operaciones.fn_cotizar(1, DATE '2026-11-10', DATE '2026-11-13') AS valor FROM dual; -- 636000

DELETE FROM vw_clientes_contacto WHERE id_cliente = 1;   -- Esperado: ORA-01031 (solo tiene SELECT)

-- C.2 [U_ADMIN_ALOJ] cambia una tarifa y la devuelve: la auditoria registra su usuario
ALTER SESSION SET CURRENT_SCHEMA = TURISMO;

UPDATE tarifa SET precio_noche = precio_noche + 1000 WHERE id_tarifa = 1;
COMMIT;
UPDATE tarifa SET precio_noche = precio_noche - 1000 WHERE id_tarifa = 1;
COMMIT;

DELETE FROM tarifa WHERE id_tarifa = 1;                  -- Esperado: ORA-01031 (sin DELETE)
SELECT * FROM pago FETCH FIRST 1 ROWS ONLY;              -- Esperado: ORA-00942

-- C.3 [U_GERENTE]
ALTER SESSION SET CURRENT_SCHEMA = TURISMO;

SELECT municipio, alojamiento, pct_ocupacion
  FROM mv_ocupacion_mensual
 WHERE mes = '2026-08'
 ORDER BY pct_ocupacion DESC
 FETCH FIRST 5 ROWS ONLY;

SELECT municipio, SUM(ingresos_hospedaje) AS ingresos
  FROM vw_ingresos_mensuales
 WHERE mes LIKE '2026-%'
 GROUP BY municipio
 ORDER BY ingresos DESC;

UPDATE habitacion SET capacidad_maxima = 9 WHERE id_habitacion = 1;  -- Esperado: ORA-00942

-- C.4 [U_AUDITOR] ve el cambio que hizo U_ADMIN_ALOJ en C.2
ALTER SESSION SET CURRENT_SCHEMA = TURISMO;

SELECT id_tarifa, operacion, precio_anterior, precio_nuevo, usuario, fecha_cambio
  FROM auditoria_tarifa
 WHERE usuario = 'U_ADMIN_ALOJ'
 ORDER BY id_auditoria;

DELETE FROM auditoria_tarifa;                            -- Esperado: ORA-01031 (no puede borrar rastros)


-------------------------------------------------------------------------------
-- PARTE D - PRUEBAS DEL PERFIL (se hacen desde la ventana de conexiones)
-------------------------------------------------------------------------------
-- D.1 SESSIONS_PER_USER = 2
--     Abrir 3 conexiones con U_RECEPCION. La tercera falla con:
--     ORA-02391: exceeded simultaneous SESSIONS_PER_USER limit
--
-- D.2 FAILED_LOGIN_ATTEMPTS = 3
--     Conectar 3 veces U_AUDITOR con clave equivocada (ORA-01017). Al 4.o intento,
--     incluso con la clave correcta: ORA-28000: The account is locked.
--     [SYSTEM] Verificar y desbloquear:
SELECT username, account_status, lock_date FROM dba_users WHERE username = 'U_AUDITOR';
ALTER USER u_auditor ACCOUNT UNLOCK;
--
-- D.3 IDLE_TIME = 10
--     Dejar una sesion de U_GERENTE quieta mas de 10 minutos y ejecutar cualquier
--     consulta: ORA-02396: exceeded maximum idle time, please connect again.
--     (Para no esperar tanto en clase: ALTER PROFILE perfil_turismo LIMIT IDLE_TIME 1;
--      probar con una conexion NUEVA y luego volver a 10.)

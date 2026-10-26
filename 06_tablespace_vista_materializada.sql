-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 2
-- Script 06 - TABLESPACE DEL HISTORICO Y VISTA MATERIALIZADA
-- Requisito : haber ejecutado antes los scripts 01, 02, 04 y 05.
-- Ejecucion : por partes, cada una con su conexion:
--               PARTE A  -> conectado como SYSTEM (servicio FREEPDB1 / XEPDB1)
--               PARTE B  -> conectado con el usuario de trabajo
--             Se puede ejecutar varias veces: cada objeto se crea solo si no existe
--             o se borra antes de volver a crearlo.
--
-- Privilegios requeridos para el usuario de trabajo (los otorga SYSTEM):
--   CREATE MATERIALIZED VIEW, CREATE JOB (refresco programado de la vista)
--   y cuota en ts_turismo_hist (la da la Parte A).
--
-- Contenido:
--   1. Tablespace ts_turismo_hist y tabla reserva_historico
--   2. Vista materializada de ocupacion mensual (mv_ocupacion_mensual)
-- =====================================================================================

-- =====================================================================================
-- 1. TABLESPACE PARA EL HISTORICO DE RESERVAS
--
-- Por que separar el historico:
--   - Consultas: las reservas de 2024 y 2025 ya no cambian, pero hoy viven junto a
--     las de 2026; la operacion diaria recorre tambien los anios cerrados.
--   - Respaldos: cada copia de seguridad vuelve a copiar anios que no cambian.
--     Separados, el historico se respalda una vez y lo vigente con frecuencia.
--   - Organizacion: lo que se consulta a diario y lo que casi nadie mira quedan en
--     archivos fisicos distintos (datafiles), cada uno en su propio "edificio".
--
-- Que se guarda: las reservas CERRADAS (COMPLETADA o CANCELADA) cuya salida fue
--   antes del 01-ene-2026, una fila por linea de habitacion.
-- Decision: es una COPIA de archivo, no un traslado. Borrarlas de RESERVA romperia
--   sus pagos, servicios y resenas (llaves foraneas). En produccion el paso
--   siguiente seria trasladar el grupo completo en una sola operacion.
-- =====================================================================================

-------------------------------------------------------------------------------
-- PARTE A [SYSTEM] - Crear el tablespace y dar cuota al usuario de trabajo
-- Al ejecutar, SQL Developer pregunta el nombre del usuario de trabajo
-- (por ejemplo TURISMO o PRUEBA), en mayusculas.
-------------------------------------------------------------------------------
SET SERVEROUTPUT ON
DEFINE usuario_trabajo = '&usuario_trabajo'

DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
      FROM dba_tablespaces
     WHERE tablespace_name = 'TS_TURISMO_HIST';

    IF v_existe = 0 THEN
        -- SMALLFILE: permite agregarle mas datafiles despues (en Oracle 23ai el
        -- valor por defecto es BIGFILE, que no lo permite).
        EXECUTE IMMEDIATE '
            CREATE SMALLFILE TABLESPACE ts_turismo_hist
              DATAFILE ''ts_turismo_hist01.dbf'' SIZE 20M
              AUTOEXTEND ON NEXT 10M MAXSIZE 500M';
        DBMS_OUTPUT.PUT_LINE('Tablespace TS_TURISMO_HIST creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace TS_TURISMO_HIST ya existia.');
    END IF;
END;
/

ALTER USER &usuario_trabajo QUOTA UNLIMITED ON ts_turismo_hist;

-- Verificacion: el tablespace y su archivo fisico
-- Nota: con un nombre de archivo sin ruta, Oracle lo crea en la carpeta dbs del
-- motor (en la evidencia: /opt/oracle/product/26ai/dbhomeFree/dbs/). En un servidor
-- real se indicaria la ruta completa de la carpeta de datos (oradata).
SELECT tablespace_name, file_name, ROUND(bytes / 1024 / 1024) AS mb, autoextensible
  FROM dba_data_files
 WHERE tablespace_name = 'TS_TURISMO_HIST';

-------------------------------------------------------------------------------
-- PARTE B [USUARIO DE TRABAJO] - Tabla del historico dentro del tablespace
-------------------------------------------------------------------------------
SET SERVEROUTPUT ON

-- Borrar la tabla si ya existe (para poder re-ejecutar el script)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE reserva_historico PURGE';
    DBMS_OUTPUT.PUT_LINE('Tabla RESERVA_HISTORICO anterior borrada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN   -- -942: la tabla no existe
            RAISE;
        END IF;
END;
/

CREATE TABLE reserva_historico
TABLESPACE ts_turismo_hist
AS
SELECT rh.id_reserva_habitacion,
       r.id_reserva,
       r.id_cliente,
       r.estado,
       rh.id_habitacion,
       h.id_alojamiento,
       rh.fecha_checkin,
       rh.fecha_checkout,
       rh.fecha_checkout - rh.fecha_checkin  AS noches,
       rh.valor_linea,
       EXTRACT(YEAR FROM r.fecha_checkout)   AS anio,
       SYSDATE                               AS fecha_archivo
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
  JOIN habitacion h          ON h.id_habitacion = rh.id_habitacion
 WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
   AND r.fecha_checkout < DATE '2026-01-01';

ALTER TABLE reserva_historico
  ADD CONSTRAINT pk_reserva_historico PRIMARY KEY (id_reserva_habitacion)
  USING INDEX TABLESPACE ts_turismo_hist;

COMMENT ON TABLE reserva_historico IS 'Archivo de reservas cerradas (COMPLETADA o CANCELADA) con salida antes de 2026. Vive en el tablespace ts_turismo_hist, separado de la operacion diaria.';

-- Verificacion: la tabla y su indice viven en el tablespace del historico
SELECT segment_name, segment_type, tablespace_name,
       ROUND(bytes / 1024 / 1024, 2) AS mb
  FROM user_segments
 WHERE segment_name IN ('RESERVA_HISTORICO', 'PK_RESERVA_HISTORICO');

-- Resultado esperado:
-- RESERVA_HISTORICO     TABLE  TS_TURISMO_HIST
-- PK_RESERVA_HISTORICO  INDEX  TS_TURISMO_HIST


-- =====================================================================================
-- 2. VISTA MATERIALIZADA DE OCUPACION MENSUAL  [USUARIO DE TRABAJO]
--
-- Que muestra: una fila por alojamiento y mes, con las noches ocupadas, las
--   noches disponibles (habitaciones x dias del mes) y el porcentaje de ocupacion.
--   Solo cuentan reservas CONFIRMADA o COMPLETADA. Cada noche se asigna al mes en
--   que ocurre (misma regla de la consulta 1 de la Entrega 1): una estadia que
--   cruza de mes se parte en dos. Las estadias duran maximo 15 noches, asi que
--   nunca tocan mas de dos meses.
--
-- Politica de refresco: COMPLETE, programada todos los dias a las 2:00 a.m.
--   hora de Colombia (07:00 del servidor, que esta en UTC).
--   - No se usa ON COMMIT FAST: la consulta reparte noches con UNION ALL y
--     funciones de fecha, y Oracle no puede refrescarla solo con los cambios
--     (ORA-12054). Ademas, recalcularla en cada reserva haria lenta la operacion.
--   - La ocupacion es un indicador de gestion: se consulta muchas veces, es
--     pesada de calcular (todas las lineas de reserva) y tolera datos de anoche.
--   - A las 2:00 a.m. no compite con las reservas del dia; a las 7:00 a.m. la
--     gerencia ya tiene el dia anterior completo.
--   - Si se necesita antes, se refresca a mano con DBMS_MVIEW.REFRESH.
-- Requiere: CREATE MATERIALIZED VIEW y CREATE JOB (refresco programado).
-- =====================================================================================
SET SERVEROUTPUT ON

-- Borrar la vista materializada si ya existe (las MV no tienen OR REPLACE)
BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ocupacion_mensual';
    DBMS_OUTPUT.PUT_LINE('Vista materializada anterior borrada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN   -- -12003: la vista materializada no existe
            RAISE;
        END IF;
END;
/

-- Refresco:
--   BUILD IMMEDIATE                      -> la primera foto se toma al crearla.
--   START WITH TRUNC(SYSDATE) + 1 + 7/24 -> el primer refresco programado es
--                                           manana a las 07:00 del servidor.
--   NEXT       TRUNC(SYSDATE) + 1 + 7/24 -> y desde ahi, todos los dias a esa hora.
-- El reloj del servidor esta en UTC (DBTIMEZONE = +00:00) y Colombia esta en UTC-5:
-- las 07:00 del servidor son las 2:00 a.m. en Colombia (America/Bogota).
-- OJO: no escribir comentarios en la misma linea del NEXT, porque Oracle guarda
-- ese texto como parte del intervalo (ORA-27465).
CREATE MATERIALIZED VIEW mv_ocupacion_mensual
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH TRUNC(SYSDATE) + 1 + 7/24
NEXT TRUNC(SYSDATE) + 1 + 7/24
AS
WITH lineas AS (                        -- lineas de reservas activas
    SELECT h.id_alojamiento, rh.fecha_checkin, rh.fecha_checkout
      FROM reserva_habitacion rh
      JOIN reserva r    ON r.id_reserva    = rh.id_reserva
      JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
     WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
),
noches AS (                             -- noches repartidas en el mes en que ocurren
    -- noches que caen en el mes del check-in
    SELECT id_alojamiento,
           TRUNC(fecha_checkin, 'MM') AS mes,
           LEAST(fecha_checkout, LAST_DAY(fecha_checkin) + 1) - fecha_checkin AS noches
      FROM lineas
    UNION ALL
    -- noches que caen en el mes siguiente (solo si la estadia cruza de mes)
    SELECT id_alojamiento,
           LAST_DAY(fecha_checkin) + 1,
           fecha_checkout - (LAST_DAY(fecha_checkin) + 1)
      FROM lineas
     WHERE fecha_checkout > LAST_DAY(fecha_checkin) + 1
),
hab AS (                                -- habitaciones de cada alojamiento
    SELECT id_alojamiento, COUNT(*) AS habitaciones
      FROM habitacion
     GROUP BY id_alojamiento
)
SELECT m.nombre                                       AS municipio,
       a.nombre_comercial                             AS alojamiento,
       TO_CHAR(n.mes, 'YYYY-MM')                      AS mes,
       SUM(n.noches)                                  AS noches_ocupadas,
       hb.habitaciones * EXTRACT(DAY FROM LAST_DAY(n.mes)) AS noches_disponibles,
       ROUND(100 * SUM(n.noches)
             / (hb.habitaciones * EXTRACT(DAY FROM LAST_DAY(n.mes))), 1) AS pct_ocupacion
  FROM noches n
  JOIN alojamiento a ON a.id_alojamiento = n.id_alojamiento
  JOIN municipio m   ON m.id_municipio   = a.id_municipio
  JOIN hab hb        ON hb.id_alojamiento = n.id_alojamiento
 GROUP BY m.nombre, a.nombre_comercial, n.mes, hb.habitaciones;

COMMENT ON MATERIALIZED VIEW mv_ocupacion_mensual IS 'Ocupacion mensual por alojamiento (noches ocupadas, disponibles y porcentaje). Refresco COMPLETE programado todos los dias a las 2:00 a.m.';

-- Verificacion: como quedo configurada
SELECT mview_name, refresh_mode, refresh_method, build_mode,
       staleness, last_refresh_date
  FROM user_mviews
 WHERE mview_name = 'MV_OCUPACION_MENSUAL';

-- Resultado esperado: REFRESH_MODE = DEMAND, REFRESH_METHOD = COMPLETE,
-- BUILD_MODE = IMMEDIATE, STALENESS = FRESH
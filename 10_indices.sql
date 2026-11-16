-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 3
-- Script 10 - INDICES Y PLANES DE EJECUCION
-- Requisito : haber ejecutado antes los scripts 01 a 07.
-- Ejecucion : conectado como TURISMO. Cada consulta por bloques con F5 (no Ctrl+Enter),
--             para que SET TIMING ON muestre el tiempo ("Transcurrido") en la salida.
--             Ejecutar cada consulta 2 o 3 veces y anotar la ULTIMA medicion (con los
--             bloques ya en memoria), antes y despues del indice.
--             Se puede re-ejecutar: los indices se borran al inicio si ya existen.
--
-- Como leer cada plan (DBMS_XPLAN.DISPLAY):
--   Operation  TABLE ACCESS FULL = recorre toda la tabla
--              INDEX RANGE SCAN / INDEX UNIQUE SCAN = entra por el indice
--   Cost       costo estimado por el optimizador (unidades relativas, menor es mejor)
--   Rows       filas que el optimizador espera en ese paso
--
-- Contenido:
--   Q1 Disponibilidad de una habitacion   -> idx_rh_hab_fechas      (COMPUESTO)
--   Q2 Reservas registradas en un dia     -> idx_reserva_dia        (BASADO EN FUNCION)
--   Q3 Pagos de una reserva               -> idx_pago_reserva       (sencillo, sobre FK)
--   Q4 Caso donde el indice NO ayuda      -> idx_reserva_estado     (baja selectividad)
-- =====================================================================================
SET SERVEROUTPUT ON
SET TIMING ON

-- 0. Borrar los indices de una corrida anterior
BEGIN
    FOR i IN (SELECT index_name FROM user_indexes
               WHERE index_name IN ('IDX_RH_HAB_FECHAS', 'IDX_RESERVA_DIA', 'IDX_RESERVA_FECHA_RES',
                                    'IDX_PAGO_RESERVA', 'IDX_RESERVA_ESTADO')) LOOP
        EXECUTE IMMEDIATE 'DROP INDEX ' || i.index_name;
        DBMS_OUTPUT.PUT_LINE('Indice borrado: ' || i.index_name);
    END LOOP;
END;
/

-- Limpiar planes de corridas anteriores
DELETE FROM plan_table;

-- Estadisticas al dia (el optimizador decide con ellas)
EXEC DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER, cascade => TRUE);

-- Indices que ya existen (solo los de PK y UNIQUE: Oracle NO indexa las FK solo)
SELECT table_name, index_name, uniqueness,
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_position) AS columnas
  FROM user_ind_columns JOIN user_indexes USING (index_name, table_name)
 WHERE table_name IN ('RESERVA', 'RESERVA_HABITACION', 'PAGO')
 GROUP BY table_name, index_name, uniqueness
 ORDER BY table_name, index_name;


-- =====================================================================================
-- Q1 - DISPONIBILIDAD DE UNA HABITACION  (indice COMPUESTO)
-- Es la consulta que corren sp_crear_reserva y trg_reserva_sin_solape en CADA reserva.
-- Sin indice, cada insercion recorre todas las lineas de reserva_habitacion.
-- =====================================================================================
-- Q1 antes
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_ANTES' FOR
SELECT COUNT(*)
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion  = 1
   AND r.estado         <> 'CANCELADA'
   AND rh.fecha_checkin  < DATE '2026-12-26'
   AND DATE '2026-12-20' < rh.fecha_checkout;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_ANTES', 'TYPICAL'));

SELECT COUNT(*)
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion  = 1
   AND r.estado         <> 'CANCELADA'
   AND rh.fecha_checkin  < DATE '2026-12-26'
   AND DATE '2026-12-20' < rh.fecha_checkout;

-- Indice: primero la columna de igualdad (habitacion), luego las de rango (fechas).
-- Asi Oracle salta directo a las lineas de ESA habitacion y filtra fechas dentro
-- del indice, sin tocar la tabla.
CREATE INDEX idx_rh_hab_fechas
    ON reserva_habitacion (id_habitacion, fecha_checkin, fecha_checkout);

-- Q1 despues
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_DESPUES' FOR
SELECT COUNT(*)
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion  = 1
   AND r.estado         <> 'CANCELADA'
   AND rh.fecha_checkin  < DATE '2026-12-26'
   AND DATE '2026-12-20' < rh.fecha_checkout;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_DESPUES', 'TYPICAL'));

SELECT COUNT(*)
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion  = 1
   AND r.estado         <> 'CANCELADA'
   AND rh.fecha_checkin  < DATE '2026-12-26'
   AND DATE '2026-12-20' < rh.fecha_checkout;


-- =====================================================================================
-- Q2 - RESERVAS REGISTRADAS EN UN DIA  (indice BASADO EN FUNCION)
-- Cuadre diario de recepcion. fecha_reserva toma SYSDATE (trae hora), por eso se
-- compara TRUNC(fecha_reserva) con el dia.
-- =====================================================================================
-- Q2 antes
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_ANTES' FOR
SELECT id_reserva, id_cliente, estado, fecha_checkin
  FROM reserva
 WHERE TRUNC(fecha_reserva) = DATE '2026-09-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_ANTES', 'TYPICAL'));

SELECT id_reserva, id_cliente, estado, fecha_checkin
  FROM reserva
 WHERE TRUNC(fecha_reserva) = DATE '2026-09-15';

-- Primer intento (parte del caso 7.4): un indice NORMAL sobre la columna.
-- El plan sigue en TABLE ACCESS FULL: la consulta aplica TRUNC a la columna y el
-- indice guarda fecha_reserva, no TRUNC(fecha_reserva).
CREATE INDEX idx_reserva_fecha_res ON reserva (fecha_reserva);

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_INDICE_NORMAL' FOR
SELECT id_reserva, id_cliente, estado, fecha_checkin
  FROM reserva
 WHERE TRUNC(fecha_reserva) = DATE '2026-09-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_INDICE_NORMAL', 'TYPICAL'));

DROP INDEX idx_reserva_fecha_res;

-- Indice basado en funcion: guarda exactamente la expresion que usa la consulta
CREATE INDEX idx_reserva_dia ON reserva (TRUNC(fecha_reserva));

-- El indice crea una columna virtual oculta: hay que darle estadisticas
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'RESERVA', method_opt => 'FOR ALL HIDDEN COLUMNS SIZE AUTO');

-- Q2 despues
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_DESPUES' FOR
SELECT id_reserva, id_cliente, estado, fecha_checkin
  FROM reserva
 WHERE TRUNC(fecha_reserva) = DATE '2026-09-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_DESPUES', 'TYPICAL'));

SELECT id_reserva, id_cliente, estado, fecha_checkin
  FROM reserva
 WHERE TRUNC(fecha_reserva) = DATE '2026-09-15';


-- =====================================================================================
-- Q3 - PAGOS DE UNA RESERVA  (indice sobre la llave foranea pago.id_reserva)
-- Se usa al liquidar, al cancelar (sp_cancelar_reserva) y al verificar si una reserva
-- quedo pagada. Oracle no crea indices para las FK.
-- =====================================================================================
-- Q3 antes
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_ANTES' FOR
SELECT id_pago, fecha_pago, monto, metodo_pago, estado_pago
  FROM pago
 WHERE id_reserva = 6821;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q3_ANTES', 'TYPICAL'));

SELECT id_pago, fecha_pago, monto, metodo_pago, estado_pago
  FROM pago
 WHERE id_reserva = 6821;

CREATE INDEX idx_pago_reserva ON pago (id_reserva);

-- Q3 despues
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_DESPUES' FOR
SELECT id_pago, fecha_pago, monto, metodo_pago, estado_pago
  FROM pago
 WHERE id_reserva = 6821;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q3_DESPUES', 'TYPICAL'));

SELECT id_pago, fecha_pago, monto, metodo_pago, estado_pago
  FROM pago
 WHERE id_reserva = 6821;


-- =====================================================================================
-- Q4 - CASO DONDE EL INDICE NO AYUDA  (seccion 7.4)
-- reserva.estado solo tiene 4 valores y COMPLETADA es la mayoria de las filas.
-- =====================================================================================
-- Distribucion de valores: muestra por que el indice no conviene
SELECT estado, COUNT(*) AS reservas,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (), 1) AS pct
  FROM reserva
 GROUP BY estado
 ORDER BY reservas DESC;

CREATE INDEX idx_reserva_estado ON reserva (estado);
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'RESERVA', method_opt => 'FOR COLUMNS estado SIZE 254');

-- 4.1 El optimizador IGNORA el indice: sigue en TABLE ACCESS FULL
EXPLAIN PLAN SET STATEMENT_ID = 'Q4_SIN_HINT' FOR
SELECT id_reserva, id_cliente, fecha_checkin, fecha_checkout
  FROM reserva
 WHERE estado = 'COMPLETADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q4_SIN_HINT', 'TYPICAL'));

-- 4.2 Si se le obliga a usarlo (hint), el costo SUBE: confirma que no conviene
EXPLAIN PLAN SET STATEMENT_ID = 'Q4_FORZADO' FOR
SELECT /*+ INDEX(reserva idx_reserva_estado) */ id_reserva, id_cliente, fecha_checkin, fecha_checkout
  FROM reserva
 WHERE estado = 'COMPLETADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q4_FORZADO', 'TYPICAL'));

-- 4.3 Matiz: para un valor RARO (PENDIENTE) el histograma si le permite usar el indice
EXPLAIN PLAN SET STATEMENT_ID = 'Q4_PENDIENTE' FOR
SELECT id_reserva, id_cliente, fecha_checkin, fecha_checkout
  FROM reserva
 WHERE estado = 'PENDIENTE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q4_PENDIENTE', 'TYPICAL'));

-- Decision: el indice sobre estado no se deja (cuesta en cada INSERT/UPDATE y la
-- consulta frecuente, la de COMPLETADA, no lo usa).
DROP INDEX idx_reserva_estado;

-- =====================================================================================
-- Resumen: indices que quedan creados
-- =====================================================================================
SELECT index_name, table_name, index_type, status
  FROM user_indexes
 WHERE index_name IN ('IDX_RH_HAB_FECHAS', 'IDX_RESERVA_DIA', 'IDX_PAGO_RESERVA')
 ORDER BY index_name;

SET TIMING OFF

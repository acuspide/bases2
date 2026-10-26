-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 2
-- Script 07 - EVIDENCIA DE PRUEBAS
-- Requisito : haber ejecutado antes los scripts 01 a 06.
-- Ejecucion : cada prueba por separado con Ctrl + Enter, para ver el resultado en la grilla.
-- Todas las piezas se llaman a traves del paquete pkg_turismouq.
-- =====================================================================================

SET SERVEROUTPUT ON

-- =====================================================================================
-- PRUEBA 1 - 

-- Datos de referencia: precios de la habitacion 1 en cada temporada de 2026.
-- Con esta tabla se calcula a mano el valor esperado de cada prueba.
-- =====================================================================================
SELECT t.nombre, t.tipo_temporada, t.fecha_inicio, t.fecha_fin, tf.precio_noche
  FROM tarifa tf
  JOIN temporada t ON t.id_temporada = tf.id_temporada
 WHERE tf.id_habitacion = 1
   AND t.anio = 2026
 ORDER BY t.fecha_inicio;
-------------------------------------------------------------------------------
-- 1.1 Estadia dentro de una sola temporada
-- 10, 11 y 12 de noviembre -> 3 noches en "Baja 03-nov a 11-dic"
-- Esperado: 3 x 212.000 = 636.000
-------------------------------------------------------------------------------
SELECT pkg_turismouq.fn_valor_estadia(1, DATE '2026-11-10', DATE '2026-11-13') AS valor
  FROM dual;
-------------------------------------------------------------------------------
-- 1.2 Estadia que cruza DOS temporadas (BAJA hasta 11-dic, ALTA desde 12-dic)
--     10 y 11 dic: 2 x 212.000 = 424.000
--     12 y 13 dic: 2 x 232.000 = 464.000
--     Esperado: 888.000
-------------------------------------------------------------------------------
SELECT pkg_turismouq.fn_valor_estadia(1, DATE '2026-12-10', DATE '2026-12-14') AS valor
  FROM dual;
-------------------------------------------------------------------------------
-- 1.3 Estadia que cruza TRES temporadas (28-oct al 04-nov, 7 noches)
--     28 y 29 oct           : 2 x 213.000 =   426.000
--     30, 31 oct, 1 y 2 nov : 4 x 243.000 =   972.000
--     3 nov                 : 1 x 212.000 =   212.000
--     Esperado: 1.610.000
-------------------------------------------------------------------------------
SELECT pkg_turismouq.fn_valor_estadia(1, DATE '2026-10-28', DATE '2026-11-04') AS valor
  FROM dual;
-------------------------------------------------------------------------------
-- 1.4 Error controlado: una noche sin tarifa
--     Las temporadas cargadas llegan hasta el 31-dic-2026; la noche del
--     01-ene-2027 no tiene temporada, asi que la funcion debe lanzar -20104.
-------------------------------------------------------------------------------
SELECT pkg_turismouq.fn_valor_estadia(1, DATE '2026-12-30', DATE '2027-01-02') AS valor
  FROM dual;
-------------------------------------------------------------------------------
-- 1.5 Error controlado: fechas al reves (salida antes de la llegada)
--     Esperado: ORA-20101
-------------------------------------------------------------------------------
SELECT pkg_turismouq.fn_valor_estadia(1, DATE '2026-11-13', DATE '2026-11-10') AS valor
  FROM dual;
-------------------------------------------------------------------------------
-- 1.6 Validacion total: la funcion reproduce valor_linea en todas las lineas
--     Esperado: 0 diferencias
-------------------------------------------------------------------------------
SELECT COUNT(*) AS diferencias
  FROM reserva_habitacion rh
 WHERE rh.valor_linea <> pkg_turismouq.fn_valor_estadia(rh.id_habitacion,
                                                       rh.fecha_checkin,
                                                       rh.fecha_checkout);
-- =====================================================================================
-- PRUEBA 2 - pkg_turismouq.sp_crear_reserva
-- 2.0 Datos de referencia: capacidad y reservas activas de la habitacion 1
-- =====================================================================================
SELECT id_habitacion, numero, tipo_habitacion, capacidad_maxima
  FROM habitacion
 WHERE id_habitacion = 1;

SELECT r.id_reserva, r.estado, rh.fecha_checkin, rh.fecha_checkout
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1
   AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkout > DATE '2026-11-01'
 ORDER BY rh.fecha_checkin;
-------------------------------------------------------------------------------
-- 2.1 Reserva valida, pegada al final de otra
--     Llega el 20-nov, el mismo dia en que sale la reserva 6821: no se cruzan.
--     Noches 20, 21 y 22 de nov en "Baja 03-nov a 11-dic"
--     Esperado: valor 636.000
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-11-20', DATE '2026-11-23', 2, v_id);
    DBMS_OUTPUT.PUT_LINE('Numero de reserva devuelto: ' || v_id);
END;
/

SELECT r.id_reserva, r.estado, rh.id_habitacion,
       rh.fecha_checkin, rh.fecha_checkout, rh.valor_linea
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
 WHERE r.id_reserva = (SELECT MAX(id_reserva) FROM reserva);

ROLLBACK;
-------------------------------------------------------------------------------
-- 2.2 Reserva valida en el hueco entre dos reservas
--     Llega el 22-dic (cuando sale la 13825) y sale el 26-dic (cuando llega la 1138).
--     Toca las dos reservas por los bordes, pero no se cruza con ninguna.
--     Noches 22, 23, 24 y 25 de dic en "Fin de Ano - Diciembre"
--     Esperado: valor 928.000
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-12-22', DATE '2026-12-26', 2, v_id);
    DBMS_OUTPUT.PUT_LINE('Numero de reserva devuelto: ' || v_id);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- 2.3 Error: fechas al reves
--     Esperado: ORA-20101
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-11-23', DATE '2026-11-20', 2, v_id);
END;
/
-------------------------------------------------------------------------------
-- 2.4 Error: capacidad excedida
--     Fechas libres, pero 3 huespedes en una habitacion de capacidad 2.
--     Esperado: ORA-20103
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-11-20', DATE '2026-11-23', 3, v_id);
END;
/
-------------------------------------------------------------------------------
-- 2.5 Error: habitacion ocupada
--     Del 17 al 19 de nov se cruza con la 23145 (16-18) y con la 6821 (18-20).
--     Esperado: ORA-20102
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-11-17', DATE '2026-11-19', 2, v_id);
END;
/
-------------------------------------------------------------------------------
-- 2.6 Error: habitacion inexistente
--     Esperado: ORA-20106
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(1, 9999, DATE '2026-11-20', DATE '2026-11-23', 1, v_id);
END;
/
-------------------------------------------------------------------------------
-- 2.7 Verificacion final: los ROLLBACK dejaron los datos como estaban
--     Esperado: las mismas 4 reservas activas de la prueba 2.0
-------------------------------------------------------------------------------
SELECT COUNT(*) AS reservas_activas_hab1
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1
   AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkout > DATE '2026-11-01';

-- =====================================================================================
-- PRUEBA 3 - pkg_turismouq.sp_liquidacion_mensual (cursor explicito con parametros)
-- Ejecutar con F5 para ver el informe en DBMS_OUTPUT.
-- =====================================================================================
-------------------------------------------------------------------------------
-- 3.1 Liquidacion de un mes cerrado: agosto de 2026
-------------------------------------------------------------------------------
EXEC pkg_turismouq.sp_liquidacion_mensual(2026, 8);
-------------------------------------------------------------------------------
-- 3.2 Control cruzado: el total del informe debe coincidir con un calculo
--     independiente (hospedaje + servicios de las reservas COMPLETADA que
--     terminan en agosto de 2026)
-------------------------------------------------------------------------------
SELECT (SELECT SUM(rh.valor_linea)
          FROM reserva r
          JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
         WHERE r.estado = 'COMPLETADA'
           AND r.fecha_checkout >= DATE '2026-08-01'
           AND r.fecha_checkout <  DATE '2026-09-01')
     + (SELECT NVL(SUM(rs.cantidad * rs.precio_unitario), 0)
          FROM reserva r
          JOIN reserva_servicio rs ON rs.id_reserva = r.id_reserva
         WHERE r.estado = 'COMPLETADA'
           AND r.fecha_checkout >= DATE '2026-08-01'
           AND r.fecha_checkout <  DATE '2026-09-01') AS total_control
  FROM dual;
-------------------------------------------------------------------------------
-- 3.3 Mes sin estadias completadas: diciembre de 2026
--     La fecha de corte de los datos es 2026-09-29: ninguna reserva de diciembre
--     puede estar COMPLETADA todavia.
-------------------------------------------------------------------------------
EXEC pkg_turismouq.sp_liquidacion_mensual(2026, 12);
-------------------------------------------------------------------------------
-- 3.4 Error: mes invalido
--     Esperado: ORA-20107
-------------------------------------------------------------------------------
EXEC pkg_turismouq.sp_liquidacion_mensual(2026, 13);

-- =====================================================================================
-- PRUEBA 4 - Paquete pkg_turismouq
-- =====================================================================================
-------------------------------------------------------------------------------
-- 4.1 El paquete existe y esta valido; no quedan versiones sueltas
-------------------------------------------------------------------------------
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('PKG_TURISMOUQ', 'FN_VALOR_ESTADIA',
                       'SP_CREAR_RESERVA', 'SP_LIQUIDACION_MENSUAL')
 ORDER BY object_name, object_type;
-------------------------------------------------------------------------------
-- 4.2 Lo que el paquete ofrece hacia afuera (su especificacion)
-------------------------------------------------------------------------------
SELECT procedure_name
  FROM user_procedures
 WHERE object_name = 'PKG_TURISMOUQ'
   AND procedure_name IS NOT NULL
 ORDER BY procedure_name;
-------------------------------------------------------------------------------
-- 4.3 Una pieza ya no se puede llamar sin el nombre del paquete
--     Esperado: error porque fn_valor_estadia ya no existe como objeto suelto
-------------------------------------------------------------------------------
SELECT fn_valor_estadia(1, DATE '2026-11-10', DATE '2026-11-13') AS valor
  FROM dual;

--=====================================================================================
-- PRUEBA 5 - trg_auditoria_tarifa (disparador de sentencia, compound trigger)
-- Ejecutar en orden, de la 5.0 a la 5.4. Los SELECT a la auditoria van ANTES
-- del ROLLBACK, porque la auditoria se deshace junto con el cambio.
-- =====================================================================================
-------------------------------------------------------------------------------
-- 5.0 Antes del cambio: precio actual y auditoria vacia
-------------------------------------------------------------------------------
SELECT tf.id_tarifa, t.nombre, tf.precio_noche
  FROM tarifa tf
  JOIN temporada t ON t.id_temporada = tf.id_temporada
 WHERE tf.id_habitacion = 1
   AND DATE '2026-12-20' BETWEEN t.fecha_inicio AND t.fecha_fin;
 
SELECT COUNT(*) AS registros_auditoria FROM auditoria_tarifa;
-------------------------------------------------------------------------------
-- 5.1 Cambio de UNA tarifa: Fin de Ano (diciembre 2026) de la habitacion 1 sube 10.000
--     Esperado: 1 registro UPDATE, anterior 232.000, nuevo 242.000
-------------------------------------------------------------------------------
UPDATE tarifa
   SET precio_noche = precio_noche + 10000
 WHERE id_habitacion = 1
   AND id_temporada = (SELECT id_temporada FROM temporada
                        WHERE DATE '2026-12-20' BETWEEN fecha_inicio AND fecha_fin);
 
SELECT id_auditoria, id_habitacion, id_temporada, operacion,
       precio_anterior, precio_nuevo, usuario, fecha_cambio
  FROM auditoria_tarifa
 ORDER BY id_auditoria;
-------------------------------------------------------------------------------
-- 5.2 Cambio de VARIAS tarifas en una sola sentencia:
--     todas las de 2026 de la habitacion 1 suben 5 %
--     Esperado: 2 grupos -> 1 registro (la 5.1) y 15 registros con la misma
--     fecha_cambio (la 5.2: una sola sentencia, un solo instante)
-------------------------------------------------------------------------------
UPDATE tarifa
   SET precio_noche = ROUND(precio_noche * 1.05, -3)
 WHERE id_habitacion = 1
   AND id_temporada IN (SELECT id_temporada FROM temporada WHERE anio = 2026);
 
SELECT operacion, COUNT(*) AS registros, fecha_cambio
  FROM auditoria_tarifa
 GROUP BY operacion, fecha_cambio
 ORDER BY fecha_cambio;
-------------------------------------------------------------------------------
-- 5.3 DELETE de una tarifa
--     Esperado: 1 registro DELETE con precio_nuevo vacio
-------------------------------------------------------------------------------
DELETE FROM tarifa
 WHERE id_habitacion = 1
   AND id_temporada = (SELECT id_temporada FROM temporada
                        WHERE DATE '2026-12-20' BETWEEN fecha_inicio AND fecha_fin);
 
SELECT id_auditoria, operacion, precio_anterior, precio_nuevo, usuario
  FROM auditoria_tarifa
 WHERE operacion = 'DELETE';
-------------------------------------------------------------------------------
-- 5.4 Deshacer: los precios vuelven y la auditoria de la prueba desaparece
--     Esperado: precio 232.000 y 0 registros de auditoria
-------------------------------------------------------------------------------
ROLLBACK;
 
SELECT tf.precio_noche
  FROM tarifa tf
  JOIN temporada t ON t.id_temporada = tf.id_temporada
 WHERE tf.id_habitacion = 1
   AND DATE '2026-12-20' BETWEEN t.fecha_inicio AND t.fecha_fin;
 
SELECT COUNT(*) AS registros_auditoria FROM auditoria_tarifa;
-- =====================================================================================
-- PRUEBA 6 - trg_reserva_sin_solape (disparador de fila)
-- Se inserta DIRECTO en las tablas, sin pasar por sp_crear_reserva, para
-- demostrar que el disparador protege la tabla por si solo.
-- Reservas activas de la habitacion 1 (ver 2.0): 16-18 nov, 18-20 nov,
-- 20-22 dic y 26-27 dic.
-- =====================================================================================
-------------------------------------------------------------------------------
-- 6.1 INSERT directo que se cruza (17 al 19 de nov)
--     Esperado: ORA-20102, lanzado por TRG_RESERVA_SIN_SOLAPE
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado)
    VALUES (1, DATE '2026-11-17', DATE '2026-11-19', 'PENDIENTE')
    RETURNING id_reserva INTO v_id;
 
    INSERT INTO reserva_habitacion
        (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
    VALUES (v_id, 1, DATE '2026-11-17', DATE '2026-11-19', 424000);
END;
/
 
ROLLBACK;
-------------------------------------------------------------------------------
-- 6.2 INSERT directo en fechas libres (20 al 23 de nov)
--     Esperado: se guarda sin error
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado)
    VALUES (1, DATE '2026-11-20', DATE '2026-11-23', 'PENDIENTE')
    RETURNING id_reserva INTO v_id;
 
    INSERT INTO reserva_habitacion
        (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
    VALUES (v_id, 1, DATE '2026-11-20', DATE '2026-11-23', 636000);
 
    DBMS_OUTPUT.PUT_LINE('Linea insertada para la reserva ' || v_id);
END;
/
 
ROLLBACK;
-------------------------------------------------------------------------------
-- 6.3 Dos reservas nuevas en la misma transaccion que se cruzan entre si
--     (22 al 25 de dic y 24 al 26 de dic, hueco libre entre la 13825 y la 1138)
--     Esperado: la primera se guarda; la segunda da ORA-20102
-------------------------------------------------------------------------------
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado)
    VALUES (1, DATE '2026-12-22', DATE '2026-12-25', 'PENDIENTE')
    RETURNING id_reserva INTO v_id;
    INSERT INTO reserva_habitacion
        (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
    VALUES (v_id, 1, DATE '2026-12-22', DATE '2026-12-25', 696000);
    DBMS_OUTPUT.PUT_LINE('Primera linea insertada para la reserva ' || v_id);
 
    INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado)
    VALUES (2, DATE '2026-12-24', DATE '2026-12-26', 'PENDIENTE')
    RETURNING id_reserva INTO v_id;
    INSERT INTO reserva_habitacion
        (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
    VALUES (v_id, 1, DATE '2026-12-24', DATE '2026-12-26', 464000);
END;
/
 
ROLLBACK;
-------------------------------------------------------------------------------
-- 6.4 Verificacion final: los datos quedaron como estaban
--     Esperado: 4 reservas activas de la habitacion 1 desde noviembre
-------------------------------------------------------------------------------
SELECT COUNT(*) AS reservas_activas_hab1
  FROM reserva_habitacion rh
  JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1
   AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkout > DATE '2026-11-01';
 -- =====================================================================================
-- PRUEBA 7 - Tablespace ts_turismo_hist y tabla reserva_historico
-- =====================================================================================
-------------------------------------------------------------------------------
-- 7.1 [USUARIO] Donde vive cada tabla: el historico separado de la operacion
--     Esperado: RESERVA y RESERVA_HABITACION en USERS;
--               RESERVA_HISTORICO en TS_TURISMO_HIST
-------------------------------------------------------------------------------
SELECT table_name, tablespace_name
  FROM user_tables
 WHERE table_name IN ('RESERVA', 'RESERVA_HABITACION', 'RESERVA_HISTORICO')
 ORDER BY table_name;
-------------------------------------------------------------------------------
-- 7.2 [USUARIO] Que se archivo: lineas por anio y estado (solo 2024 y 2025)
-------------------------------------------------------------------------------
SELECT anio, estado, COUNT(*) AS lineas, SUM(valor_linea) AS valor
  FROM reserva_historico
 GROUP BY anio, estado
 ORDER BY anio, estado;
-------------------------------------------------------------------------------
-- 7.3 [USUARIO] Completitud: el historico tiene exactamente las lineas que
--     cumplen la regla en las tablas originales
--     Esperado: 0 filas (no falta ninguna) y el mismo conteo en las dos columnas
-------------------------------------------------------------------------------
SELECT rh.id_reserva_habitacion
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
 WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
   AND r.fecha_checkout < DATE '2026-01-01'
MINUS
SELECT id_reserva_habitacion FROM reserva_historico;
 
SELECT (SELECT COUNT(*)
          FROM reserva r
          JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
         WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
           AND r.fecha_checkout < DATE '2026-01-01') AS lineas_origen,
       (SELECT COUNT(*) FROM reserva_historico)      AS lineas_historico
  FROM dual;
 -- =====================================================================================
-- PRUEBA 8 - mv_ocupacion_mensual (vista materializada)
-- =====================================================================================
-------------------------------------------------------------------------------
-- 8.1 Configuracion: modo, metodo, estado y programacion del refresco
--     Esperado: DEMAND, COMPLETE, FRESH; proximo refresco a las 07:00 del servidor
--     (UTC), que son las 2:00 a.m. en Colombia
-------------------------------------------------------------------------------
SELECT mview_name, refresh_mode, refresh_method, staleness, last_refresh_date
  FROM user_mviews
 WHERE mview_name = 'MV_OCUPACION_MENSUAL';
 
SELECT rname, TO_CHAR(next_date, 'YYYY-MM-DD HH24:MI') AS proximo_refresco, interval
  FROM user_refresh
 WHERE rname = 'MV_OCUPACION_MENSUAL';
-------------------------------------------------------------------------------
-- 8.2 Uso: los 10 alojamientos con mayor ocupacion en agosto de 2026
-------------------------------------------------------------------------------
SELECT municipio, alojamiento, noches_ocupadas, noches_disponibles, pct_ocupacion
  FROM mv_ocupacion_mensual
 WHERE mes = '2026-08'
 ORDER BY pct_ocupacion DESC
 FETCH FIRST 10 ROWS ONLY;
-------------------------------------------------------------------------------
-- 8.3 Control cruzado: repartir noches entre meses no pierde ni duplica noches
--     Esperado: las dos columnas iguales
-------------------------------------------------------------------------------
SELECT (SELECT SUM(noches_ocupadas) FROM mv_ocupacion_mensual) AS noches_mv,
       (SELECT SUM(rh.fecha_checkout - rh.fecha_checkin)
          FROM reserva_habitacion rh
          JOIN reserva r ON r.id_reserva = rh.id_reserva
         WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA'))     AS noches_lineas
  FROM dual;
-------------------------------------------------------------------------------
-- 8.4 La foto se queda vieja hasta que se refresca
--     a) Ocupacion de noviembre 2026 del alojamiento de la habitacion 1
-------------------------------------------------------------------------------
SELECT mo.alojamiento, mo.mes, mo.noches_ocupadas
  FROM mv_ocupacion_mensual mo
  JOIN alojamiento a ON a.nombre_comercial = mo.alojamiento
  JOIN habitacion h  ON h.id_alojamiento = a.id_alojamiento
 WHERE h.id_habitacion = 1
   AND mo.mes = '2026-11';
-------------------------------------------------------------------------------
--     b) Nueva reserva CONFIRMADA de 3 noches (20 al 23 de nov) + COMMIT
-------------------------------------------------------------------------------
VARIABLE v_id NUMBER
EXEC pkg_turismouq.sp_crear_reserva(1, 1, DATE '2026-11-20', DATE '2026-11-23', 2, :v_id);
UPDATE reserva SET estado = 'CONFIRMADA' WHERE id_reserva = :v_id;
COMMIT;
-------------------------------------------------------------------------------
--     c) La MV NO cambio (mismas noches que en a) y quedo STALE
-------------------------------------------------------------------------------
SELECT mo.alojamiento, mo.mes, mo.noches_ocupadas
  FROM mv_ocupacion_mensual mo
  JOIN alojamiento a ON a.nombre_comercial = mo.alojamiento
  JOIN habitacion h  ON h.id_alojamiento = a.id_alojamiento
 WHERE h.id_habitacion = 1
   AND mo.mes = '2026-11';
 
SELECT mview_name, staleness FROM user_mviews
 WHERE mview_name = 'MV_OCUPACION_MENSUAL';
-------------------------------------------------------------------------------
--     d) Refrescar a mano: ahora si aparecen las 3 noches nuevas y queda FRESH
-------------------------------------------------------------------------------
EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
 
SELECT mo.alojamiento, mo.mes, mo.noches_ocupadas
  FROM mv_ocupacion_mensual mo
  JOIN alojamiento a ON a.nombre_comercial = mo.alojamiento
  JOIN habitacion h  ON h.id_alojamiento = a.id_alojamiento
 WHERE h.id_habitacion = 1
   AND mo.mes = '2026-11';
 
SELECT mview_name, staleness FROM user_mviews
 WHERE mview_name = 'MV_OCUPACION_MENSUAL';
-------------------------------------------------------------------------------
--     e) Deshacer la prueba: borrar la reserva de prueba y refrescar
-------------------------------------------------------------------------------
DELETE FROM reserva_habitacion WHERE id_reserva = :v_id;
DELETE FROM reserva            WHERE id_reserva = :v_id;
COMMIT;
EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');

 
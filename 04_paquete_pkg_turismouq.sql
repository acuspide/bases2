-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 2
-- Script 04 - FUNCION, PROCEDIMIENTO, CURSOR Y PAQUETE
-- Requisito : haber ejecutado antes los scripts 01 (DDL) y 02 (carga de datos).
-- Ejecucion : completo, como script (F5 en SQL Developer). Se puede ejecutar
--             varias veces: el paquete se crea con CREATE OR REPLACE.
--
-- Privilegios requeridos para el usuario de trabajo (los otorga SYSTEM):
--   CREATE PROCEDURE, CREATE TRIGGER, CREATE VIEW,
--   CREATE MATERIALIZED VIEW, CREATE JOB
--
-- Contenido del paquete pkg_turismouq:
--   fn_valor_estadia       valor de una estadia noche por noche, segun temporada
--   sp_crear_reserva       registra una reserva validando fechas, capacidad y disponibilidad
--   sp_liquidacion_mensual liquidacion de un mes por alojamiento (cursor explicito
--                          con parametros)
--
-- Codigos de error propios (RAISE_APPLICATION_ERROR):
--   -20101  la fecha de salida es igual o anterior a la de llegada
--   -20102  la habitacion no esta disponible en esas fechas
--   -20103  los huespedes superan la capacidad de la habitacion
--   -20104  una noche de la estadia no tiene tarifa (temporada sin cubrir)
--   -20106  la habitacion no existe
--   -20107  el mes no esta entre 1 y 12
-- =====================================================================================

SET SERVEROUTPUT ON

-------------------------------------------------------------------------------
-- 0. Limpieza: borrar las versiones sueltas (fuera del paquete), si existen.
--    Asi cada regla queda escrita en un solo lugar: dentro del paquete.
--    El error -4043 significa "el objeto no existe" y se ignora.
-------------------------------------------------------------------------------
BEGIN
    FOR o IN (SELECT object_name, object_type
                FROM user_objects
               WHERE object_name IN ('FN_VALOR_ESTADIA', 'SP_CREAR_RESERVA',
                                     'SP_LIQUIDACION_MENSUAL')
                 AND object_type IN ('FUNCTION', 'PROCEDURE')) LOOP
        EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
        DBMS_OUTPUT.PUT_LINE('Borrado objeto suelto: ' || o.object_name);
    END LOOP;
END;
/

-------------------------------------------------------------------------------
-- 1. ESPECIFICACION DEL PAQUETE
--    Dice QUE ofrece el paquete: nombres, parametros y tipo de retorno.
--    Todo lo que aparece aqui se puede llamar desde afuera como
--    pkg_turismouq.nombre(...).
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_turismouq AS

    -- Valor de una estadia noche por noche, segun la temporada de cada noche.
    FUNCTION fn_valor_estadia (
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER;

    -- Registra una reserva de una habitacion y devuelve su numero.
    PROCEDURE sp_crear_reserva (
        p_id_cliente    IN  cliente.id_cliente%TYPE,
        p_id_habitacion IN  habitacion.id_habitacion%TYPE,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_huespedes     IN  NUMBER,
        p_id_reserva    OUT reserva.id_reserva%TYPE
    );

    -- Imprime la liquidacion de un mes por alojamiento.
    PROCEDURE sp_liquidacion_mensual (
        p_anio IN NUMBER,
        p_mes  IN NUMBER
    );

END pkg_turismouq;
/

-------------------------------------------------------------------------------
-- 2. CUERPO DEL PAQUETE
--    Dice COMO lo hace: el codigo completo de cada pieza. Las cabeceras deben
--    coincidir exactamente con las de la especificacion.
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_turismouq AS

    ---------------------------------------------------------------------------
    -- 2.1 fn_valor_estadia
    -- Recorre la estadia noche por noche y suma la tarifa de la temporada en
    -- que cae cada noche. La noche del dia de salida no se cobra.
    ---------------------------------------------------------------------------
    FUNCTION fn_valor_estadia (
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER
    IS
        v_noches NUMBER;                       -- cuantas noches dura la estadia
        v_noche  DATE;                         -- la noche que se esta cobrando
        v_precio tarifa.precio_noche%TYPE;     -- precio de esa noche
        v_total  NUMBER(12,2) := 0;            -- acumulado
    BEGIN
        -- 1. Validar las fechas
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(-20101,
                'La fecha de salida debe ser posterior a la de llegada');
        END IF;

        -- 2. Contar las noches (restar dos fechas da el numero de dias)
        v_noches := p_fecha_out - p_fecha_in;

        -- 3. Recorrer noche por noche
        FOR i IN 0 .. v_noches - 1 LOOP
            v_noche := p_fecha_in + i;

            SELECT tf.precio_noche
              INTO v_precio
              FROM tarifa tf
              JOIN temporada t ON t.id_temporada = tf.id_temporada
             WHERE tf.id_habitacion = p_id_habitacion
               AND v_noche BETWEEN t.fecha_inicio AND t.fecha_fin;

            v_total := v_total + v_precio;
        END LOOP;

        -- 4. Devolver el total
        RETURN v_total;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20104,
                'La habitacion ' || p_id_habitacion ||
                ' no tiene tarifa para la noche del ' || TO_CHAR(v_noche, 'YYYY-MM-DD'));
    END fn_valor_estadia;

    ---------------------------------------------------------------------------
    -- 2.2 sp_crear_reserva
    -- Valida fechas, existencia, capacidad y disponibilidad; calcula el valor
    -- con fn_valor_estadia (la regla no se repite) y guarda la reserva.
    -- No hace COMMIT: quien lo llama decide si confirma o deshace.
    ---------------------------------------------------------------------------
    PROCEDURE sp_crear_reserva (
        p_id_cliente    IN  cliente.id_cliente%TYPE,
        p_id_habitacion IN  habitacion.id_habitacion%TYPE,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_huespedes     IN  NUMBER,
        p_id_reserva    OUT reserva.id_reserva%TYPE
    )
    IS
        v_capacidad habitacion.capacidad_maxima%TYPE;
        v_cruces    NUMBER;
        v_valor     reserva_habitacion.valor_linea%TYPE;
    BEGIN
        -- 1. Validar las fechas
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(-20101,
                'La fecha de salida debe ser posterior a la de llegada');
        END IF;

        -- 2. Traer la capacidad (si la habitacion no existe -> NO_DATA_FOUND)
        SELECT capacidad_maxima
          INTO v_capacidad
          FROM habitacion
         WHERE id_habitacion = p_id_habitacion;

        -- 3. Validar la capacidad
        IF p_huespedes > v_capacidad THEN
            RAISE_APPLICATION_ERROR(-20103,
                'La habitacion ' || p_id_habitacion || ' admite ' || v_capacidad ||
                ' huespedes y se solicitaron ' || p_huespedes);
        END IF;

        -- 4. Validar la disponibilidad: reservas no canceladas que se crucen
        SELECT COUNT(*)
          INTO v_cruces
          FROM reserva_habitacion rh
          JOIN reserva r ON r.id_reserva = rh.id_reserva
         WHERE rh.id_habitacion  = p_id_habitacion
           AND r.estado         <> 'CANCELADA'
           AND rh.fecha_checkin  < p_fecha_out
           AND p_fecha_in        < rh.fecha_checkout;

        IF v_cruces > 0 THEN
            RAISE_APPLICATION_ERROR(-20102,
                'La habitacion ' || p_id_habitacion ||
                ' no esta disponible entre el ' || TO_CHAR(p_fecha_in, 'YYYY-MM-DD') ||
                ' y el ' || TO_CHAR(p_fecha_out, 'YYYY-MM-DD'));
        END IF;

        -- 5. Calcular el valor con la funcion ya construida
        v_valor := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

        -- 6. Guardar la cabecera y recuperar el numero que Oracle le asigna
        INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado)
        VALUES (p_id_cliente, p_fecha_in, p_fecha_out, 'PENDIENTE')
        RETURNING id_reserva INTO p_id_reserva;

        -- 7. Guardar la linea de la habitacion con su valor
        INSERT INTO reserva_habitacion
            (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
        VALUES
            (p_id_reserva, p_id_habitacion, p_fecha_in, p_fecha_out, v_valor);

        DBMS_OUTPUT.PUT_LINE('Reserva ' || p_id_reserva || ' creada. Valor: ' || v_valor);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20106,
                'La habitacion ' || p_id_habitacion || ' no existe');
    END sp_crear_reserva;

    ---------------------------------------------------------------------------
    -- 2.3 sp_liquidacion_mensual
    -- Cursor explicito con parametros (anio y mes). Solo reservas COMPLETADA;
    -- cada reserva se liquida en el mes de su fecha de salida; el valor es
    -- hospedaje + servicios, sumados por separado para no inflar los totales.
    ---------------------------------------------------------------------------
    PROCEDURE sp_liquidacion_mensual (
        p_anio IN NUMBER,
        p_mes  IN NUMBER
    )
    IS
        -- Cursor explicito con parametros
        CURSOR c_liquidacion (c_anio NUMBER, c_mes NUMBER) IS
            WITH periodo AS (
                SELECT TO_DATE(c_anio || '-' || c_mes || '-01', 'YYYY-MM-DD') AS inicio
                  FROM dual
            ),
            hosp AS (                       -- hospedaje por alojamiento
                SELECT h.id_alojamiento,
                       COUNT(DISTINCT r.id_reserva)              AS reservas,
                       SUM(rh.fecha_checkout - rh.fecha_checkin) AS noches,
                       SUM(rh.valor_linea)                       AS hospedaje
                  FROM reserva r
                  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
                  JOIN habitacion h          ON h.id_habitacion = rh.id_habitacion
                  CROSS JOIN periodo p
                 WHERE r.estado = 'COMPLETADA'
                   AND r.fecha_checkout >= p.inicio
                   AND r.fecha_checkout <  ADD_MONTHS(p.inicio, 1)
                 GROUP BY h.id_alojamiento
            ),
            serv AS (                       -- servicios por alojamiento
                SELECT s.id_alojamiento,
                       SUM(rs.cantidad * rs.precio_unitario) AS servicios
                  FROM reserva r
                  JOIN reserva_servicio rs ON rs.id_reserva = r.id_reserva
                  JOIN servicio s          ON s.id_servicio = rs.id_servicio
                  CROSS JOIN periodo p
                 WHERE r.estado = 'COMPLETADA'
                   AND r.fecha_checkout >= p.inicio
                   AND r.fecha_checkout <  ADD_MONTHS(p.inicio, 1)
                 GROUP BY s.id_alojamiento
            )
            SELECT m.nombre                             AS municipio,
                   a.nombre_comercial                   AS alojamiento,
                   ho.reservas,
                   ho.noches,
                   ho.hospedaje,
                   NVL(se.servicios, 0)                 AS servicios,
                   ho.hospedaje + NVL(se.servicios, 0)  AS total
              FROM hosp ho
              JOIN alojamiento a ON a.id_alojamiento = ho.id_alojamiento
              JOIN municipio m   ON m.id_municipio   = a.id_municipio
              LEFT JOIN serv se  ON se.id_alojamiento = ho.id_alojamiento
             ORDER BY m.nombre, total DESC;

        r_liq       c_liquidacion%ROWTYPE;     -- una fila del cursor
        v_total_mes NUMBER := 0;
    BEGIN
        -- 1. Validar el mes
        IF p_mes NOT BETWEEN 1 AND 12 THEN
            RAISE_APPLICATION_ERROR(-20107, 'El mes debe estar entre 1 y 12');
        END IF;

        DBMS_OUTPUT.PUT_LINE('LIQUIDACION MENSUAL ' || p_anio || '-' || LPAD(p_mes, 2, '0'));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

        -- 2. Recorrer el cursor: OPEN - FETCH - EXIT - CLOSE
        OPEN c_liquidacion(p_anio, p_mes);
        LOOP
            FETCH c_liquidacion INTO r_liq;
            EXIT WHEN c_liquidacion%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(r_liq.municipio, 14)   ||
                RPAD(r_liq.alojamiento, 34) ||
                ' Res: '  || LPAD(r_liq.reservas, 3) ||
                ' Noc: '  || LPAD(r_liq.noches, 4)   ||
                ' Total: '|| TO_CHAR(r_liq.total, '999G999G999G999'));

            v_total_mes := v_total_mes + r_liq.total;
        END LOOP;

        -- 3. Cierre del informe
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        IF c_liquidacion%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No hay estadias completadas que terminen en ese mes.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Alojamientos liquidados: ' || c_liquidacion%ROWCOUNT);
            DBMS_OUTPUT.PUT_LINE('Total liquidado del mes: ' || TO_CHAR(v_total_mes, '999G999G999G999'));
        END IF;
        CLOSE c_liquidacion;
    END sp_liquidacion_mensual;

END pkg_turismouq;
/

-------------------------------------------------------------------------------
-- 3. Verificacion: deben quedar PACKAGE y PACKAGE BODY en estado VALID,
--    y ninguna funcion o procedimiento suelto con estos nombres.
-------------------------------------------------------------------------------
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('PKG_TURISMOUQ', 'FN_VALOR_ESTADIA',
                       'SP_CREAR_RESERVA', 'SP_LIQUIDACION_MENSUAL')
 ORDER BY object_name, object_type;

-- Resultado esperado:
-- PKG_TURISMOUQ  PACKAGE       VALID
-- PKG_TURISMOUQ  PACKAGE BODY  VALID

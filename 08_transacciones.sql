-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 3
-- Script 08 - TRANSACCIONES: RESERVA + PAGO CON SAVEPOINT, CANCELACION Y RESENAS
-- Requisito : haber ejecutado antes los scripts 01 a 07.
-- Ejecucion : conectado con el usuario de trabajo (TURISMO).
--             Secciones 1 y 2: completas con F5 (crean objetos).
--             Secciones 3, 4 y 5: paso a paso, con F5 sobre cada bloque, para tomar
--             la captura de cada paso. Cada prueba deja los datos como estaban.
--
-- Contenido:
--   1. Paquete pkg_operaciones
--        fn_cotizar            valor de una estadia (envuelve a fn_valor_estadia)
--        sp_reservar_y_pagar   reserva + linea + pago en UNA transaccion con SAVEPOINT
--        sp_cancelar_reserva   cancelacion con la regla de reembolso (RN1)
--   2. Disparador trg_resena_valida (RN2: solo se resena una estadia COMPLETADA)
--   3. Rollback parcial paso a paso (evidencia de la seccion 7.1 del documento)
--   4. Pruebas de sp_reservar_y_pagar y sp_cancelar_reserva
--   5. Pruebas de trg_resena_valida
--
-- Codigos de error nuevos (se suman a los del script 04):
--   -20105  la reserva no existe
--   -20108  el pago supera el valor de la reserva
--   -20109  la reserva ya esta CANCELADA o COMPLETADA y no se puede cancelar
--   -20110  la resena no corresponde a una estadia COMPLETADA del cliente en ese alojamiento
-- =====================================================================================
SET SERVEROUTPUT ON

-------------------------------------------------------------------------------
-- 1.1 ESPECIFICACION
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_operaciones AS

    -- Cotiza una estadia sin guardar nada (lo usa recepcion antes de reservar).
    FUNCTION fn_cotizar (
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER;

    -- Registra reserva, linea y pago en una sola transaccion.
    -- Si el pago falla, se deshace SOLO el pago (ROLLBACK TO SAVEPOINT) y la
    -- reserva queda PENDIENTE; si falla la reserva, se deshace todo.
    PROCEDURE sp_reservar_y_pagar (
        p_id_cliente    IN  cliente.id_cliente%TYPE,
        p_id_habitacion IN  habitacion.id_habitacion%TYPE,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_huespedes     IN  NUMBER,
        p_monto         IN  pago.monto%TYPE,
        p_metodo        IN  pago.metodo_pago%TYPE,
        p_id_reserva    OUT reserva.id_reserva%TYPE,
        p_estado        OUT reserva.estado%TYPE
    );

    -- Cancela una reserva. Con MAS de 5 dias de anticipacion al check-in se
    -- reembolsa el 80 % de lo pagado (pago REEMBOLSADO); con 5 o menos, nada.
    -- No hace COMMIT: quien la llama decide.
    PROCEDURE sp_cancelar_reserva (
        p_id_reserva        IN  reserva.id_reserva%TYPE,
        p_fecha_cancelacion IN  DATE DEFAULT TRUNC(SYSDATE),
        p_reembolso         OUT NUMBER
    );

END pkg_operaciones;
/

-------------------------------------------------------------------------------
-- 1.2 CUERPO
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_operaciones AS

    FUNCTION fn_cotizar (
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER
    IS
    BEGIN
        RETURN pkg_turismouq.fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);
    END fn_cotizar;

    ---------------------------------------------------------------------------
    PROCEDURE sp_reservar_y_pagar (
        p_id_cliente    IN  cliente.id_cliente%TYPE,
        p_id_habitacion IN  habitacion.id_habitacion%TYPE,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_huespedes     IN  NUMBER,
        p_monto         IN  pago.monto%TYPE,
        p_metodo        IN  pago.metodo_pago%TYPE,
        p_id_reserva    OUT reserva.id_reserva%TYPE,
        p_estado        OUT reserva.estado%TYPE
    )
    IS
        v_bloqueo habitacion.id_habitacion%TYPE;
        v_total   NUMBER;
    BEGIN
        -- 1. Bloquear la fila de la habitacion. Dos recepcionistas que intenten
        --    reservar la MISMA habitacion al tiempo quedan en fila: el segundo
        --    espera hasta que el primero termine y entonces ve su reserva
        --    (ver script 09_concurrencia).
        BEGIN
            SELECT id_habitacion INTO v_bloqueo
              FROM habitacion
             WHERE id_habitacion = p_id_habitacion
               FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20106,
                    'La habitacion ' || p_id_habitacion || ' no existe');
        END;

        -- 2. Reserva PENDIENTE + linea de habitacion (valida fechas, capacidad y
        --    disponibilidad; reutiliza el procedimiento de la Entrega 2).
        pkg_turismouq.sp_crear_reserva(p_id_cliente, p_id_habitacion, p_fecha_in,
                                       p_fecha_out, p_huespedes, p_id_reserva);
        p_estado := 'PENDIENTE';

        -- 3. Punto de guardado: hasta aqui la reserva es valida y se conserva.
        SAVEPOINT sp_reserva_registrada;

        -- 4. Pago. Si algo falla aqui, se vuelve al SAVEPOINT: se pierde el pago,
        --    pero la reserva sigue en pie (PENDIENTE, para pagar despues).
        BEGIN
            SELECT SUM(valor_linea) INTO v_total
              FROM reserva_habitacion
             WHERE id_reserva = p_id_reserva;

            IF p_monto > v_total THEN
                RAISE_APPLICATION_ERROR(-20108,
                    'El pago (' || p_monto || ') supera el valor de la reserva (' || v_total || ')');
            END IF;

            INSERT INTO pago (id_reserva, fecha_pago, monto, metodo_pago, estado_pago)
            VALUES (p_id_reserva, SYSDATE, p_monto, p_metodo, 'EXITOSO');

            UPDATE reserva SET estado = 'CONFIRMADA' WHERE id_reserva = p_id_reserva;
            p_estado := 'CONFIRMADA';
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK TO SAVEPOINT sp_reserva_registrada;
                DBMS_OUTPUT.PUT_LINE('Pago rechazado, se deshace solo el pago: ' || SQLERRM);
        END;

        -- 5. Confirmar todo lo que quedo en pie (reserva con o sin pago).
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Reserva ' || p_id_reserva || ' guardada en estado ' || p_estado);

    EXCEPTION
        -- Si falla la reserva (pasos 1 y 2) no hay nada que conservar.
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_reservar_y_pagar;

    ---------------------------------------------------------------------------
    PROCEDURE sp_cancelar_reserva (
        p_id_reserva        IN  reserva.id_reserva%TYPE,
        p_fecha_cancelacion IN  DATE DEFAULT TRUNC(SYSDATE),
        p_reembolso         OUT NUMBER
    )
    IS
        v_estado  reserva.estado%TYPE;
        v_checkin reserva.fecha_checkin%TYPE;
        v_pagado  NUMBER;
        v_metodo  pago.metodo_pago%TYPE;
    BEGIN
        -- 1. Traer y bloquear la reserva
        SELECT estado, fecha_checkin
          INTO v_estado, v_checkin
          FROM reserva
         WHERE id_reserva = p_id_reserva
           FOR UPDATE;

        IF v_estado IN ('CANCELADA', 'COMPLETADA') THEN
            RAISE_APPLICATION_ERROR(-20109,
                'La reserva ' || p_id_reserva || ' esta ' || v_estado || ' y no se puede cancelar');
        END IF;

        -- 2. Lo que el cliente pago de verdad
        SELECT NVL(SUM(monto), 0)
          INTO v_pagado
          FROM pago
         WHERE id_reserva = p_id_reserva
           AND estado_pago = 'EXITOSO';

        -- 3. Regla de reembolso (RN1)
        IF v_checkin - p_fecha_cancelacion > 5 AND v_pagado > 0 THEN
            p_reembolso := ROUND(v_pagado * 0.8, 2);

            SELECT metodo_pago INTO v_metodo          -- se devuelve por el mismo medio
              FROM pago
             WHERE id_reserva = p_id_reserva AND estado_pago = 'EXITOSO'
             ORDER BY fecha_pago, id_pago
             FETCH FIRST 1 ROW ONLY;

            INSERT INTO pago (id_reserva, fecha_pago, monto, metodo_pago, estado_pago)
            VALUES (p_id_reserva, p_fecha_cancelacion, p_reembolso, v_metodo, 'REEMBOLSADO');
        ELSE
            p_reembolso := 0;
        END IF;

        -- 4. Cancelar (las reservas canceladas no bloquean la habitacion)
        UPDATE reserva SET estado = 'CANCELADA' WHERE id_reserva = p_id_reserva;

        DBMS_OUTPUT.PUT_LINE('Reserva ' || p_id_reserva || ' cancelada a ' ||
                             (v_checkin - p_fecha_cancelacion) || ' dias del check-in. ' ||
                             'Pagado: ' || v_pagado || '  Reembolso: ' || p_reembolso);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20105, 'La reserva ' || p_id_reserva || ' no existe');
    END sp_cancelar_reserva;

END pkg_operaciones;
/

-------------------------------------------------------------------------------
-- 2. trg_resena_valida (RN2)
--    Una resena solo entra si su reserva esta COMPLETADA, es del mismo cliente y
--    tiene al menos una habitacion del alojamiento resenado. Consulta OTRAS
--    tablas (reserva, reserva_habitacion, habitacion), asi que no hay tabla mutante.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_resena_valida
BEFORE INSERT OR UPDATE OF id_reserva, id_cliente, id_alojamiento ON resena
FOR EACH ROW
DECLARE
    v_ok NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_ok
      FROM reserva r
     WHERE r.id_reserva = :NEW.id_reserva
       AND r.id_cliente = :NEW.id_cliente
       AND r.estado     = 'COMPLETADA'
       AND EXISTS (SELECT 1
                     FROM reserva_habitacion rh
                     JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
                    WHERE rh.id_reserva     = r.id_reserva
                      AND h.id_alojamiento = :NEW.id_alojamiento);

    IF v_ok = 0 THEN
        RAISE_APPLICATION_ERROR(-20110,
            'La reserva ' || :NEW.id_reserva || ' no es una estadia COMPLETADA del cliente ' ||
            :NEW.id_cliente || ' en el alojamiento ' || :NEW.id_alojamiento);
    END IF;
END trg_resena_valida;
/

-- Verificacion: objetos validos
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('PKG_OPERACIONES', 'TRG_RESENA_VALIDA')
 ORDER BY object_name, object_type;


-- =====================================================================================
-- 3. ROLLBACK PARCIAL PASO A PASO  (evidencia para la tabla de la seccion 7.1)
--    Habitacion 1, del 24 al 26 de noviembre de 2026 (libre; 2 noches BAJA = 424.000).
--    Ejecutar cada paso por separado y tomar la captura de su consulta.
-- =====================================================================================
VARIABLE v_res NUMBER

-- PASO 1: INSERT de la reserva y su linea (via sp_crear_reserva, sin COMMIT)
EXEC pkg_turismouq.sp_crear_reserva(5, 1, DATE '2026-11-24', DATE '2026-11-26', 2, :v_res);

SELECT r.id_reserva, r.estado, rh.id_habitacion, rh.valor_linea,
       (SELECT COUNT(*) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagos
  FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
 WHERE r.id_reserva = :v_res;
-- Se ve: 1 reserva PENDIENTE, valor 424.000, 0 pagos

-- PASO 2: SAVEPOINT
SAVEPOINT sp_reserva_registrada;

-- PASO 3: INSERT del pago y confirmacion de la reserva (cambios que luego se descartan)
INSERT INTO pago (id_reserva, fecha_pago, monto, metodo_pago, estado_pago)
VALUES (:v_res, SYSDATE, 424000, 'TARJETA_CREDITO', 'EXITOSO');
UPDATE reserva SET estado = 'CONFIRMADA' WHERE id_reserva = :v_res;

SELECT r.id_reserva, r.estado,
       (SELECT COUNT(*) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagos
  FROM reserva r WHERE r.id_reserva = :v_res;
-- Se ve: CONFIRMADA y 1 pago (todavia sin confirmar en la base)

-- PASO 4: el banco rechaza el cobro -> volver al punto de guardado
ROLLBACK TO SAVEPOINT sp_reserva_registrada;

SELECT r.id_reserva, r.estado,
       (SELECT COUNT(*) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagos
  FROM reserva r WHERE r.id_reserva = :v_res;
-- Se ve: la reserva sigue (PENDIENTE), el pago desaparecio

-- PASO 5: COMMIT de lo que quedo en pie
COMMIT;

SELECT r.id_reserva, r.estado, rh.valor_linea,
       (SELECT COUNT(*) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagos
  FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
 WHERE r.id_reserva = :v_res;
-- Se ve: reserva PENDIENTE guardada de forma permanente, 0 pagos

-- Limpieza de la demostracion
DELETE FROM reserva_habitacion WHERE id_reserva = :v_res;
DELETE FROM reserva            WHERE id_reserva = :v_res;
COMMIT;


-- =====================================================================================
-- 4. PRUEBAS DE pkg_operaciones
--    sp_reservar_y_pagar hace COMMIT, por eso al final se borran las reservas de prueba.
-- =====================================================================================
VARIABLE r1 NUMBER
VARIABLE r2 NUMBER
VARIABLE r3 NUMBER
VARIABLE r4 NUMBER
VARIABLE r5 NUMBER
VARIABLE v_estado VARCHAR2(15)
VARIABLE v_reembolso NUMBER

-- 4.0 Cotizacion (no guarda nada). Esperado: 424.000 (2 noches BAJA x 212.000)
SELECT pkg_operaciones.fn_cotizar(1, DATE '2026-11-26', DATE '2026-11-28') AS cotizacion FROM dual;

-- 4.1 Reserva + pago valido (anticipo de 200.000). Esperado: CONFIRMADA y 1 pago
EXEC pkg_operaciones.sp_reservar_y_pagar(5, 1, DATE '2026-11-26', DATE '2026-11-28', 2, 200000, 'PSE', :r1, :v_estado);
PRINT v_estado

-- 4.2 Pago con un metodo que no existe (viola ck_pago_metodo).
--     Esperado: "Pago rechazado ... ORA-02290", reserva PENDIENTE y 0 pagos
EXEC pkg_operaciones.sp_reservar_y_pagar(5, 1, DATE '2026-11-28', DATE '2026-11-30', 2, 100000, 'BITCOIN', :r2, :v_estado);
PRINT v_estado

-- 4.3 Pago mayor que el valor de la reserva. Esperado: ORA-20108 capturado,
--     reserva PENDIENTE y 0 pagos
EXEC pkg_operaciones.sp_reservar_y_pagar(5, 1, DATE '2026-12-01', DATE '2026-12-03', 2, 9999999, 'EFECTIVO', :r3, :v_estado);
PRINT v_estado

-- 4.4 Habitacion ocupada (se cruza con la 23145 y la 6821).
--     Esperado: ORA-20102 y NADA guardado (ni reserva ni pago)
EXEC pkg_operaciones.sp_reservar_y_pagar(5, 1, DATE '2026-11-17', DATE '2026-11-19', 2, 100000, 'PSE', :r4, :v_estado);

-- 4.5 Estado de las reservas de prueba
SELECT r.id_reserva, r.estado, r.fecha_checkin, rh.valor_linea,
       (SELECT COUNT(*) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagos,
       (SELECT NVL(SUM(monto), 0) FROM pago p WHERE p.id_reserva = r.id_reserva) AS pagado
  FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
 WHERE r.id_reserva IN (:r1, :r2, :r3)
 ORDER BY r.id_reserva;

-- 4.6 Cancelacion con MAS de 5 dias (check-in 26-nov, cancela 14-nov = 12 dias).
--     Esperado: reembolso 160.000 (80 % de 200.000) y pago REEMBOLSADO
EXEC pkg_operaciones.sp_cancelar_reserva(:r1, DATE '2026-11-14', :v_reembolso);
PRINT v_reembolso

-- 4.7 Cancelacion con 5 dias o menos: reserva nueva pagada y cancelada 3 dias antes.
--     Esperado: reembolso 0
EXEC pkg_operaciones.sp_reservar_y_pagar(5, 1, DATE '2026-12-05', DATE '2026-12-07', 2, 300000, 'TARJETA_DEBITO', :r5, :v_estado);
EXEC pkg_operaciones.sp_cancelar_reserva(:r5, DATE '2026-12-02', :v_reembolso);
PRINT v_reembolso

-- 4.8 Error: cancelar una reserva ya cancelada. Esperado: ORA-20109
EXEC pkg_operaciones.sp_cancelar_reserva(:r1, DATE '2026-11-14', :v_reembolso);

-- 4.9 Error: reserva inexistente. Esperado: ORA-20105
EXEC pkg_operaciones.sp_cancelar_reserva(999999, DATE '2026-11-14', :v_reembolso);

COMMIT;

SELECT p.id_reserva, p.monto, p.metodo_pago, p.estado_pago
  FROM pago p
 WHERE p.id_reserva IN (:r1, :r5)
 ORDER BY p.id_reserva, p.id_pago;

-- 4.10 Limpieza: borrar las reservas de prueba
DELETE FROM pago               WHERE id_reserva IN (:r1, :r2, :r3, :r5);
DELETE FROM reserva_habitacion WHERE id_reserva IN (:r1, :r2, :r3, :r5);
DELETE FROM reserva            WHERE id_reserva IN (:r1, :r2, :r3, :r5);
COMMIT;


-- =====================================================================================
-- 5. PRUEBAS DE trg_resena_valida
-- =====================================================================================
-- 5.1 Resena sobre una reserva CONFIRMADA (6821, aun no ocurre). Esperado: ORA-20110
INSERT INTO resena (id_cliente, id_alojamiento, id_reserva, calificacion, comentario)
SELECT r.id_cliente, h.id_alojamiento, r.id_reserva, 5, 'Prueba: aun no me he hospedado'
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
  JOIN habitacion h          ON h.id_habitacion = rh.id_habitacion
 WHERE r.id_reserva = 6821;

-- 5.2 Resena valida: una reserva COMPLETADA que todavia no tiene resena.
--     Esperado: 1 fila insertada; luego ROLLBACK
INSERT INTO resena (id_cliente, id_alojamiento, id_reserva, calificacion, comentario)
SELECT r.id_cliente, h.id_alojamiento, r.id_reserva, 4, 'Prueba: estadia completada'
  FROM reserva r
  JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
  JOIN habitacion h          ON h.id_habitacion = rh.id_habitacion
 WHERE r.estado = 'COMPLETADA'
   AND NOT EXISTS (SELECT 1 FROM resena s WHERE s.id_reserva = r.id_reserva)
 ORDER BY r.id_reserva
 FETCH FIRST 1 ROW ONLY;

ROLLBACK;

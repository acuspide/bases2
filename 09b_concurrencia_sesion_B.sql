-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 3
-- Script 09b - CONCURRENCIA: SESION B   (va junto con 09a_concurrencia_sesion_A.sql)
-- Abrir en una "Hoja de trabajo SQL no compartida" (Ctrl + Shift + N) como TURISMO.
-- Ejecutar cada bloque cuando le toque, segun la marca [Tn].
-- =====================================================================================
SET SERVEROUTPUT ON

-- =====================================================================================
-- EXPERIMENTO 1 - SIN FOR UPDATE
-- =====================================================================================

-- [T2] B: consulta disponibilidad -> 0 cruces (no ve la reserva de A: aun no existe)
SELECT COUNT(*) AS cruces
  FROM reserva_habitacion rh JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1 AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkin < DATE '2026-12-16' AND DATE '2026-12-14' < rh.fecha_checkout;

-- [T4] B: crea su reserva para las mismas fechas. A ya inserto pero SIN COMMIT:
--      por lectura consistente B no ve esa fila y la validacion pasa.
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(8, 1, DATE '2026-12-14', DATE '2026-12-16', 2, v_id);
END;
/

-- [T6] B: COMMIT -> quedan dos reservas activas para la misma habitacion y noches
COMMIT;


-- =====================================================================================
-- EXPERIMENTO 2 - CON SELECT ... FOR UPDATE
-- =====================================================================================

-- [T2] B: intenta bloquear la habitacion 1 -> queda en espera hasta que A haga COMMIT
--      (variante: FOR UPDATE WAIT 5 devuelve ORA-30006 a los 5 segundos;
--       FOR UPDATE NOWAIT devuelve ORA-00054 de inmediato)
SELECT id_habitacion, numero
  FROM habitacion
 WHERE id_habitacion = 1
   FOR UPDATE;

-- [T5] B: ya tiene el bloqueo; al validar ve la reserva de A -> ORA-20102
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(8, 1, DATE '2026-12-14', DATE '2026-12-16', 2, v_id);
END;
/

ROLLBACK;   -- libera el bloqueo de B

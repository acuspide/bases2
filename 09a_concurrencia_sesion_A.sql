-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 3
-- Script 09a - CONCURRENCIA: SESION A   (va junto con 09b_concurrencia_sesion_B.sql)
--
-- Como montar el experimento en SQL Developer:
--   1. Abrir este archivo en una hoja de trabajo conectada como TURISMO.
--   2. Abrir 09b en OTRA sesion: Herramientas > "Hoja de trabajo SQL no compartida"
--      (Ctrl + Shift + N). Si se usa la misma hoja o una compartida, las dos "sesiones"
--      serian la misma y el experimento no muestra nada.
--   3. Ejecutar los bloques en el orden T1, T2, T3... alternando entre A y B, cada uno
--      con Ctrl + Enter (o seleccionandolo y F5), y tomar captura de las dos ventanas.
--
-- Escenario: dos recepcionistas venden al mismo tiempo la habitacion 1 del 14 al 16 de
-- diciembre de 2026 (hueco libre). Cliente 7 en la sesion A, cliente 8 en la B.
-- =====================================================================================
SET SERVEROUTPUT ON

-- =====================================================================================
-- EXPERIMENTO 1 - SIN FOR UPDATE
-- =====================================================================================

-- [T1] A: consulta disponibilidad -> 0 cruces, la habitacion "esta libre"
SELECT COUNT(*) AS cruces
  FROM reserva_habitacion rh JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1 AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkin < DATE '2026-12-16' AND DATE '2026-12-14' < rh.fecha_checkout;

-- [T2] (en B: la misma consulta, tambien da 0)

-- [T3] A: crea la reserva (sp_crear_reserva y trg_reserva_sin_solape la aprueban)
--      Todavia NO hace COMMIT.
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(7, 1, DATE '2026-12-14', DATE '2026-12-16', 2, v_id);
END;
/

-- [T4] (en B: crea su reserva para las mismas fechas -> TAMBIEN la aprueban, porque
--      B no ve la fila de A, que aun no tiene COMMIT)

-- [T5] A: COMMIT
COMMIT;

-- [T6] (en B: COMMIT)

-- [T7] A: resultado -> 2 reservas activas que se cruzan: la habitacion se vendio dos veces
SELECT r.id_reserva, r.id_cliente, r.estado, rh.fecha_checkin, rh.fecha_checkout
  FROM reserva_habitacion rh JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1 AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkin < DATE '2026-12-16' AND DATE '2026-12-14' < rh.fecha_checkout;

-- Limpieza del experimento 1 (deja la base como estaba)
DELETE FROM reserva_habitacion
 WHERE id_habitacion = 1 AND fecha_checkin = DATE '2026-12-14' AND fecha_checkout = DATE '2026-12-16';
DELETE FROM reserva
 WHERE id_cliente IN (7, 8) AND fecha_checkin = DATE '2026-12-14' AND fecha_checkout = DATE '2026-12-16'
   AND NOT EXISTS (SELECT 1 FROM reserva_habitacion rh WHERE rh.id_reserva = reserva.id_reserva);
COMMIT;


-- =====================================================================================
-- EXPERIMENTO 2 - CON SELECT ... FOR UPDATE
-- Antes de validar, cada sesion bloquea la fila de la habitacion. Es lo mismo que hace
-- internamente pkg_operaciones.sp_reservar_y_pagar (script 08).
-- =====================================================================================

-- [T1] A: bloquea la habitacion 1
SELECT id_habitacion, numero
  FROM habitacion
 WHERE id_habitacion = 1
   FOR UPDATE;

-- [T2] (en B: intenta bloquear la misma fila -> SE QUEDA ESPERANDO, sin respuesta)

-- [T3] A: valida y crea la reserva mientras B espera
DECLARE
    v_id reserva.id_reserva%TYPE;
BEGIN
    pkg_turismouq.sp_crear_reserva(7, 1, DATE '2026-12-14', DATE '2026-12-16', 2, v_id);
END;
/

-- [T4] A: COMMIT -> libera el bloqueo
COMMIT;

-- [T5] (en B: su SELECT ... FOR UPDATE termina; al crear la reserva recibe ORA-20102,
--      porque ahora SI ve la reserva confirmada de A)

-- [T6] A: resultado -> 1 sola reserva activa en esas fechas
SELECT r.id_reserva, r.id_cliente, r.estado, rh.fecha_checkin, rh.fecha_checkout
  FROM reserva_habitacion rh JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.id_habitacion = 1 AND r.estado <> 'CANCELADA'
   AND rh.fecha_checkin < DATE '2026-12-16' AND DATE '2026-12-14' < rh.fecha_checkout;

-- Limpieza del experimento 2
DELETE FROM reserva_habitacion
 WHERE id_habitacion = 1 AND fecha_checkin = DATE '2026-12-14' AND fecha_checkout = DATE '2026-12-16';
DELETE FROM reserva
 WHERE id_cliente IN (7, 8) AND fecha_checkin = DATE '2026-12-14' AND fecha_checkout = DATE '2026-12-16'
   AND NOT EXISTS (SELECT 1 FROM reserva_habitacion rh WHERE rh.id_reserva = reserva.id_reserva);
COMMIT;



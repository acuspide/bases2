-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 2
-- Script 05 - DISPARADORES
-- Requisito : haber ejecutado antes los scripts 01, 02 y 04.
-- Ejecucion : completo, como script (F5 en SQL Developer). Se puede ejecutar
--             varias veces: la tabla de auditoria se crea solo si no existe y los
--             disparadores usan CREATE OR REPLACE.
--
-- Contenido:
--   1. auditoria_tarifa + trg_auditoria_tarifa   (disparador de sentencia)
--   2. trg_reserva_sin_solape                    (disparador de fila)
-- =====================================================================================

SET SERVEROUTPUT ON

-------------------------------------------------------------------------------
-- 1.1 Tabla de auditoria de TARIFA
--     Guarda quien cambio una tarifa, cuando, y el precio anterior y el nuevo.
--     Se crea solo si no existe, para no perder el historial al re-ejecutar.
-------------------------------------------------------------------------------
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
      FROM user_tables
     WHERE table_name = 'AUDITORIA_TARIFA';

    IF v_existe = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE auditoria_tarifa (
                id_auditoria    NUMBER GENERATED ALWAYS AS IDENTITY
                                CONSTRAINT pk_auditoria_tarifa PRIMARY KEY,
                id_tarifa       NUMBER        NOT NULL,
                id_habitacion   NUMBER        NOT NULL,
                id_temporada    NUMBER        NOT NULL,
                operacion       VARCHAR2(10)  NOT NULL,
                precio_anterior NUMBER(10,2),
                precio_nuevo    NUMBER(10,2),
                usuario         VARCHAR2(128) NOT NULL,
                fecha_cambio    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
                CONSTRAINT ck_auditoria_operacion
                    CHECK (operacion IN (''INSERT'', ''UPDATE'', ''DELETE''))
            )';
        DBMS_OUTPUT.PUT_LINE('Tabla AUDITORIA_TARIFA creada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tabla AUDITORIA_TARIFA ya existia: se conserva su historial.');
    END IF;
END;
/

COMMENT ON TABLE auditoria_tarifa IS 'Historial de cambios sobre TARIFA: quien, cuando, precio anterior y precio nuevo. La llena trg_auditoria_tarifa.';

-------------------------------------------------------------------------------
-- 1.2 trg_auditoria_tarifa  (disparador de SENTENCIA)
--
-- Problema: un disparador de sentencia se ejecuta una sola vez por operacion y
--   no tiene acceso a :OLD ni a :NEW, asi que por si solo no puede saber el
--   precio anterior y el nuevo de cada tarifa.
-- Decision: compound trigger.
--   - La seccion AFTER EACH ROW anota en una lista en memoria cada tarifa
--     modificada, con su precio anterior (:OLD) y su precio nuevo (:NEW).
--   - La seccion AFTER STATEMENT escribe toda la lista en auditoria_tarifa una
--     sola vez, al terminar la sentencia, con el usuario y la fecha.
-- Resultado: la auditoria se registra a nivel de sentencia y conserva el
--   detalle de cada fila. Si la transaccion se deshace (ROLLBACK), la auditoria
--   tambien se deshace: solo queda registro de cambios que realmente ocurrieron.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_tarifa
FOR INSERT OR UPDATE OF precio_noche OR DELETE ON tarifa
COMPOUND TRIGGER

    -- Lista en memoria donde se anotan los cambios de la sentencia
    TYPE t_cambio IS RECORD (
        id_tarifa     tarifa.id_tarifa%TYPE,
        id_habitacion tarifa.id_habitacion%TYPE,
        id_temporada  tarifa.id_temporada%TYPE,
        operacion     VARCHAR2(10),
        anterior      tarifa.precio_noche%TYPE,
        nuevo         tarifa.precio_noche%TYPE
    );
    TYPE t_lista IS TABLE OF t_cambio INDEX BY PLS_INTEGER;
    v_cambios t_lista;

    -- Parte de FILA: aqui si existen :OLD y :NEW
    AFTER EACH ROW IS
        v_i PLS_INTEGER := v_cambios.COUNT + 1;
    BEGIN
        v_cambios(v_i).id_tarifa     := NVL(:NEW.id_tarifa,     :OLD.id_tarifa);
        v_cambios(v_i).id_habitacion := NVL(:NEW.id_habitacion, :OLD.id_habitacion);
        v_cambios(v_i).id_temporada  := NVL(:NEW.id_temporada,  :OLD.id_temporada);
        v_cambios(v_i).operacion     := CASE WHEN INSERTING THEN 'INSERT'
                                             WHEN UPDATING  THEN 'UPDATE'
                                             ELSE 'DELETE' END;
        v_cambios(v_i).anterior      := :OLD.precio_noche;   -- vacio en un INSERT
        v_cambios(v_i).nuevo         := :NEW.precio_noche;   -- vacio en un DELETE
    END AFTER EACH ROW;

    -- Parte de SENTENCIA: escribe todo lo anotado, una sola vez al final.
    -- Toma la hora UNA vez, para que todas las filas de una misma sentencia
    -- queden registradas con exactamente el mismo instante.
    AFTER STATEMENT IS
        v_momento TIMESTAMP := SYSTIMESTAMP;
    BEGIN
        FOR i IN 1 .. v_cambios.COUNT LOOP
            INSERT INTO auditoria_tarifa
                (id_tarifa, id_habitacion, id_temporada, operacion,
                 precio_anterior, precio_nuevo, usuario, fecha_cambio)
            VALUES
                (v_cambios(i).id_tarifa, v_cambios(i).id_habitacion,
                 v_cambios(i).id_temporada, v_cambios(i).operacion,
                 v_cambios(i).anterior, v_cambios(i).nuevo, USER, v_momento);
        END LOOP;
        v_cambios.DELETE;   -- limpiar la lista para la siguiente sentencia
    END AFTER STATEMENT;

END trg_auditoria_tarifa;
/

-- Resultado esperado:
-- Tabla AUDITORIA_TARIFA creada.
-- Trigger TRG_AUDITORIA_TARIFA compilado


-------------------------------------------------------------------------------
-- 2. trg_reserva_sin_solape  (disparador de FILA)
--
-- Problema: sp_crear_reserva valida la disponibilidad, pero solo si se usa el
--   procedimiento. Un INSERT directo en RESERVA_HABITACION podria vender dos
--   veces la misma habitacion en las mismas fechas.
-- Decision: disparador BEFORE INSERT ... FOR EACH ROW sobre RESERVA_HABITACION.
--   Antes de guardar cada linea, cuenta las lineas de reservas no canceladas de
--   la misma habitacion que se cruzan con las fechas nuevas. Si hay alguna,
--   detiene la insercion con el mismo codigo del procedimiento (-20102).
--   Dos estadias se cruzan si: llegada existente < salida nueva
--                          y   llegada nueva     < salida existente
--   (si una sale el 20 y la otra llega el 20, no se cruzan).
-- Limitacion: el disparador consulta la misma tabla que vigila. Oracle lo
--   permite en un INSERT ... VALUES de una fila (el caso de sp_crear_reserva y
--   de cualquier registro normal). Un INSERT ... SELECT de varias filas daria
--   ORA-04091 (tabla mutante); por eso el disparador vigila solo INSERT.
-- Resultado: ninguna linea nueva puede solaparse con otra reserva activa de la
--   misma habitacion, sin importar desde donde se inserte.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_reserva_sin_solape
BEFORE INSERT ON reserva_habitacion
FOR EACH ROW
DECLARE
    v_cruces NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cruces
      FROM reserva_habitacion rh
      JOIN reserva r ON r.id_reserva = rh.id_reserva
     WHERE rh.id_habitacion  = :NEW.id_habitacion
       AND r.estado         <> 'CANCELADA'
       AND rh.fecha_checkin  < :NEW.fecha_checkout
       AND :NEW.fecha_checkin < rh.fecha_checkout;

    IF v_cruces > 0 THEN
        RAISE_APPLICATION_ERROR(-20102,
            'La habitacion ' || :NEW.id_habitacion ||
            ' ya tiene una reserva activa que se cruza entre el ' ||
            TO_CHAR(:NEW.fecha_checkin, 'YYYY-MM-DD') || ' y el ' ||
            TO_CHAR(:NEW.fecha_checkout, 'YYYY-MM-DD'));
    END IF;
END trg_reserva_sin_solape;
/

-- Resultado esperado:
-- Trigger TRG_RESERVA_SIN_SOLAPE compilado

-------------------------------------------------------------------------------
-- Verificacion: los dos disparadores existen y estan habilitados
-------------------------------------------------------------------------------
SELECT trigger_name, trigger_type, triggering_event, table_name, status
  FROM user_triggers
 WHERE trigger_name IN ('TRG_AUDITORIA_TARIFA', 'TRG_RESERVA_SIN_SOLAPE')
 ORDER BY trigger_name;
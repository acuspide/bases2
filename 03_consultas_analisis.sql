-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 1
-- Script 03 - CONSULTAS DE ANALISIS (7 consultas)
-- Requisito : haber ejecutado antes el script 01 (DDL) y el script 02 (carga de datos).
-- Ejecucion : de arriba hacia abajo, como script (F5 en SQL Developer).
-- Fecha de corte de los datos: 2026-09-29.
-- =====================================================================================

-- 1. OCUPACION POR MUNICIPIO, ANIO Y MES (PIVOT)
-- Las noches se cuentan en el mes en que ocurren. Una estadia que cruza de un mes a otro
-- se parte en dos: las noches del mes del check-in y las noches del mes siguiente.
-- (Las estadias de los datos duran maximo 15 noches, asi que nunca tocan mas de 2 meses.)
-- Se separa por anio porque los datos van de 2024 a 2026.
WITH lineas AS (
    SELECT m.nombre AS municipio,
           rh.fecha_checkin,
           rh.fecha_checkout
    FROM reserva_habitacion rh
    JOIN reserva r      ON r.id_reserva = rh.id_reserva
    JOIN habitacion h   ON h.id_habitacion = rh.id_habitacion
    JOIN alojamiento a  ON a.id_alojamiento = h.id_alojamiento
    JOIN municipio m    ON m.id_municipio = a.id_municipio
    WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
)
SELECT *
FROM (
    -- noches que caen en el mes del check-in
    SELECT municipio,
           TO_CHAR(fecha_checkin, 'YYYY') AS anio,
           TO_CHAR(fecha_checkin, 'MM') AS mes,
           LEAST(fecha_checkout, LAST_DAY(fecha_checkin) + 1) - fecha_checkin AS noches
    FROM lineas
    UNION ALL
    -- noches que caen en el mes siguiente (solo si la estadia cruza de mes)
    SELECT municipio,
           TO_CHAR(LAST_DAY(fecha_checkin) + 1, 'YYYY'),
           TO_CHAR(LAST_DAY(fecha_checkin) + 1, 'MM'),
           fecha_checkout - (LAST_DAY(fecha_checkin) + 1)
    FROM lineas
    WHERE fecha_checkout > LAST_DAY(fecha_checkin) + 1
)
PIVOT (
    SUM(noches)
    FOR mes IN ('01' AS ENERO, '02' AS FEBRERO, '03' AS MARZO,
                '04' AS ABRIL, '05' AS MAYO, '06' AS JUNIO,
                '07' AS JULIO, '08' AS AGOSTO, '09' AS SEPTIEMBRE,
                '10' AS OCTUBRE, '11' AS NOVIEMBRE, '12' AS DICIEMBRE)
)
ORDER BY municipio, anio;

-- 2. INGRESOS POR MUNICIPIO, TIPO DE ALOJAMIENTO Y TEMPORADA (ROLLUP + GROUPING)
-- La temporada se asigna noche por noche: cada linea se cruza con todas las temporadas que
-- toca, se cuentan las noches de la linea dentro de cada temporada y se multiplican por la
-- tarifa de esa temporada. Es la misma regla con la que se calculo valor_linea, asi que el
-- TOTAL GENERAL coincide con SUM(valor_linea) de las reservas CONFIRMADA y COMPLETADA.
-- no se usa pago porque una reserva puede tener varias habitaciones (varias filas en
-- reserva_habitacion) y varios pagos. Si se une pago con reserva_habitacion para llegar al
-- municipio, cada pago se repite por cada habitacion y el total se infla.
SELECT CASE WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL GENERAL'
            ELSE m.nombre END AS municipio,
       CASE WHEN GROUPING(m.nombre) = 1 THEN NULL
            WHEN GROUPING(ta.nombre) = 1 THEN 'SUBTOTAL MUNICIPIO'
            ELSE ta.nombre END AS tipo_alojamiento,
       CASE WHEN GROUPING(m.nombre) = 1 THEN NULL
            WHEN GROUPING(ta.nombre) = 1 THEN NULL
            WHEN GROUPING(t.tipo_temporada) = 1 THEN 'SUBTOTAL TIPO ALOJAMIENTO'
            ELSE t.tipo_temporada END AS temporada,
       SUM((LEAST(rh.fecha_checkout, t.fecha_fin + 1)
            - GREATEST(rh.fecha_checkin, t.fecha_inicio)) * tf.precio_noche) AS ingresos
FROM reserva_habitacion rh
JOIN reserva r          ON r.id_reserva = rh.id_reserva
JOIN habitacion h       ON h.id_habitacion = rh.id_habitacion
JOIN alojamiento a      ON a.id_alojamiento = h.id_alojamiento
JOIN municipio m        ON m.id_municipio = a.id_municipio
JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN temporada t        ON rh.fecha_checkin <= t.fecha_fin
                       AND rh.fecha_checkout > t.fecha_inicio
JOIN tarifa tf          ON tf.id_habitacion = rh.id_habitacion
                       AND tf.id_temporada = t.id_temporada
WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
GROUP BY ROLLUP (m.nombre, ta.nombre, t.tipo_temporada)
ORDER BY GROUPING(m.nombre), m.nombre,
         GROUPING(ta.nombre), ta.nombre,
         GROUPING(t.tipo_temporada), t.tipo_temporada;

-- 3. LOS 3 ALOJAMIENTOS DE MAYOR INGRESO DENTRO DE CADA MUNICIPIO (RANK + PARTITION BY)
-- se realiza con confirmada o completada, porque de esa forma se tienen los ingresos de la completada y la proyeccion de ingresos de la confirmada
SELECT municipio, alojamiento, ingresos, posicion
FROM (
    SELECT m.nombre AS municipio,
           a.nombre_comercial AS alojamiento,
           SUM(rh.valor_linea) AS ingresos,
           RANK() OVER (PARTITION BY m.nombre
                        ORDER BY SUM(rh.valor_linea) DESC) AS posicion
    FROM reserva_habitacion rh
    JOIN reserva r      ON r.id_reserva = rh.id_reserva
    JOIN habitacion h   ON h.id_habitacion = rh.id_habitacion
    JOIN alojamiento a  ON a.id_alojamiento = h.id_alojamiento
    JOIN municipio m    ON m.id_municipio = a.id_municipio
    WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
    GROUP BY m.nombre, a.id_alojamiento, a.nombre_comercial
)
WHERE posicion <= 3
ORDER BY municipio, posicion;

-- 4. VARIACION DE INGRESOS MES CONTRA MES (LAG)
-- Los datos llegan hasta diciembre de 2026, pero la fecha de corte es 2026-09-29.
-- tipo_periodo marca los meses: REAL (cerrados), PARCIAL (el mes del corte) y
-- PROYECCION (meses posteriores al corte, solo con reservas futuras).
SELECT periodo,
       CASE WHEN periodo > '2026-09' THEN 'PROYECCION'
            WHEN periodo = '2026-09' THEN 'PARCIAL'
            ELSE 'REAL' END AS tipo_periodo,
       ingresos,
       ingreso_anterior,
       ingresos - ingreso_anterior AS variacion,
       ROUND((ingresos - ingreso_anterior) / ingreso_anterior * 100, 2) AS variacion_pct
FROM (
    SELECT TO_CHAR(rh.fecha_checkin, 'YYYY-MM') AS periodo,
           SUM(rh.valor_linea) AS ingresos,
           LAG(SUM(rh.valor_linea), 1) OVER (ORDER BY TO_CHAR(rh.fecha_checkin, 'YYYY-MM')) AS ingreso_anterior
    FROM reserva_habitacion rh
    JOIN reserva r ON r.id_reserva = rh.id_reserva
    WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
    GROUP BY TO_CHAR(rh.fecha_checkin, 'YYYY-MM')
)
ORDER BY periodo;

-- 5. CONSULTA PARAMETRIZADA CON VARIABLES DE ENLACE (rango de fechas)
-- ingresos por fechas y cantidad de reservas
-- Las variables se declaran y se les da un valor de ejemplo para que el script corra
-- completo sin pedir datos. Para otro rango, cambie las dos lineas EXEC (formato AAAA-MM-DD).
VARIABLE fecha_inicio VARCHAR2(10)
VARIABLE fecha_fin VARCHAR2(10)
EXEC :fecha_inicio := '2025-01-01'
EXEC :fecha_fin := '2025-06-30'

SELECT m.nombre AS municipio,
       COUNT(DISTINCT r.id_reserva) AS reservas,
       SUM(rh.valor_linea) AS ingresos
FROM reserva_habitacion rh
JOIN reserva r      ON r.id_reserva = rh.id_reserva
JOIN habitacion h   ON h.id_habitacion = rh.id_habitacion
JOIN alojamiento a  ON a.id_alojamiento = h.id_alojamiento
JOIN municipio m    ON m.id_municipio = a.id_municipio
WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
  AND rh.fecha_checkin BETWEEN TO_DATE(:fecha_inicio, 'YYYY-MM-DD')
                           AND TO_DATE(:fecha_fin, 'YYYY-MM-DD')
GROUP BY m.nombre
ORDER BY ingresos DESC;

-- 6. UNPIVOT: en que meses hay mas llegadas y mas salidas
SELECT TO_CHAR(fecha, 'YYYY-MM') AS periodo,
       evento,
       COUNT(*) AS cantidad
FROM (
    SELECT id_reserva, fecha_checkin, fecha_checkout
    FROM reserva
    WHERE estado IN ('CONFIRMADA', 'COMPLETADA')
)
UNPIVOT (
    fecha FOR evento IN (fecha_checkin  AS 'LLEGADAS',
                         fecha_checkout AS 'SALIDAS')
)
GROUP BY TO_CHAR(fecha, 'YYYY-MM'), evento
ORDER BY periodo, evento;

-- 7. CONSULTA LIBRE: que metodos de pago concentran el dinero que realmente se cobra, y como cambia cada anio?
-- Solo cuentan los pagos EXITOSO.
SELECT CASE WHEN GROUPING(anio) = 1 THEN 'TOTAL GENERAL'
            ELSE anio END AS anio_pago,
       CASE WHEN GROUPING(anio) = 1 THEN NULL
            WHEN GROUPING(metodo) = 1 THEN 'SUBTOTAL ANIO'
            ELSE metodo END AS metodo_pago,
       COUNT(*) AS num_pagos,
       SUM(monto) AS recaudo
FROM (
    SELECT TO_CHAR(fecha_pago, 'YYYY') AS anio,
           metodo_pago AS metodo,
           monto
    FROM pago
    WHERE estado_pago = 'EXITOSO'
)
GROUP BY ROLLUP (anio, metodo)
ORDER BY GROUPING(anio), anio,
         GROUPING(metodo), recaudo DESC;

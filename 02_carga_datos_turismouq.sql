-- =====================================================================================
-- TurismoUQ - Proyecto integrador BD II - Entrega 1
-- Script 02 - CARGA DE DATOS (semilla asimetrica)
-- -------------------------------------------------------------------------------------
-- Requisito : haber ejecutado antes el script 01 (DDL) sobre una base LIMPIA (14 tablas vacias).
-- Motor     : Oracle Database XE 21c.  Ejecutar completo (F5 en SQL Developer / @archivo en SQL*Plus).
-- Duracion  : entre 1 y 4 minutos, casi todo en la seccion 4 (generacion de reservas).
-- Semilla   : la variable de sustitucion "semilla" (mas abajo) alimenta DBMS_RANDOM.SEED. Misma
--             semilla = mismos datos; cambien el texto para obtener una carga distinta.
-- Fecha de corte de la simulacion: 2026-09-29 ("hoy" para decidir que reservas ya se completaron).
-- Nota      : los nombres de alojamientos, personas y correos son ficticios. Sin tildes ni enie a
--             proposito, para que el archivo cargue igual en cualquier configuracion de caracteres.
--
-- Contenido
--   0. Guarda de seguridad (aborta si las tablas ya tienen datos)
--   1. Catalogos y datos maestros: municipio, tipo_alojamiento, temporada, alojamiento,
--      habitacion, servicio, usuario_sistema           (datos escritos, no aleatorios)
--   2. TARIFA  : una fila por cada cruce habitacion x temporada (aleatoria, distinta por alojamiento)
--   3. CLIENTE : 3.200 clientes con ciudades de origen variadas
--   4. RESERVA + RESERVA_HABITACION + RESERVA_SERVICIO + PAGO + RESENA (25.000 reservas)
--   5. Ajustes finales, estadisticas y consultas de verificacion
-- =====================================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE ON
DEFINE semilla = 'TurismoUQ-2026-equipo01'

-- =====================================================================================
-- 0. GUARDA DE SEGURIDAD
-- =====================================================================================
DECLARE
  v_filas NUMBER;
BEGIN
  SELECT (SELECT COUNT(*) FROM municipio) + (SELECT COUNT(*) FROM cliente) + (SELECT COUNT(*) FROM reserva)
    INTO v_filas FROM dual;
  IF v_filas > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Las tablas ya contienen datos. Recree el esquema con el script 01 antes de cargar.');
  END IF;
END;
/

-- =====================================================================================
-- 1. CATALOGOS Y DATOS MAESTROS
-- =====================================================================================
-- 1.1 MUNICIPIO (los 12 municipios del Quindio)
INSERT INTO municipio (nombre) VALUES ('Armenia');
INSERT INTO municipio (nombre) VALUES ('Buenavista');
INSERT INTO municipio (nombre) VALUES ('Calarca');
INSERT INTO municipio (nombre) VALUES ('Circasia');
INSERT INTO municipio (nombre) VALUES ('Cordoba');
INSERT INTO municipio (nombre) VALUES ('Filandia');
INSERT INTO municipio (nombre) VALUES ('Genova');
INSERT INTO municipio (nombre) VALUES ('La Tebaida');
INSERT INTO municipio (nombre) VALUES ('Montenegro');
INSERT INTO municipio (nombre) VALUES ('Pijao');
INSERT INTO municipio (nombre) VALUES ('Quimbaya');
INSERT INTO municipio (nombre) VALUES ('Salento');

-- 1.2 TIPO_ALOJAMIENTO (4 obligatorios + Apartahotel como tipo adicional sustentado)
INSERT INTO tipo_alojamiento (nombre) VALUES ('Finca cafetera');
INSERT INTO tipo_alojamiento (nombre) VALUES ('Hotel');
INSERT INTO tipo_alojamiento (nombre) VALUES ('Glamping');
INSERT INTO tipo_alojamiento (nombre) VALUES ('Hostal');
INSERT INTO tipo_alojamiento (nombre) VALUES ('Apartahotel');

-- 1.3 TEMPORADA (2024-2026: cada anio cubierto dia por dia, sin huecos ni traslapes)
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Enero', 'ALTA', 2024, DATE '2024-01-01', DATE '2024-01-08');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 09-ene a 22-mar', 'BAJA', 2024, DATE '2024-01-09', DATE '2024-03-22');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Semana Santa', 'ALTA', 2024, DATE '2024-03-23', DATE '2024-03-31');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 01-abr a 09-may', 'MEDIA', 2024, DATE '2024-04-01', DATE '2024-05-09');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente de Mayo', 'ALTA', 2024, DATE '2024-05-10', DATE '2024-05-13');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 14-may a 14-jun', 'MEDIA', 2024, DATE '2024-05-14', DATE '2024-06-14');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Mitad de Ano', 'ALTA', 2024, DATE '2024-06-15', DATE '2024-07-21');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 22-jul a 15-ago', 'MEDIA', 2024, DATE '2024-07-22', DATE '2024-08-15');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Asuncion', 'ALTA', 2024, DATE '2024-08-16', DATE '2024-08-19');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 20-ago a 10-oct', 'BAJA', 2024, DATE '2024-08-20', DATE '2024-10-10');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Dia de la Raza', 'ALTA', 2024, DATE '2024-10-11', DATE '2024-10-14');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 15-oct a 31-oct', 'BAJA', 2024, DATE '2024-10-15', DATE '2024-10-31');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Todos los Santos', 'ALTA', 2024, DATE '2024-11-01', DATE '2024-11-04');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 05-nov a 13-dic', 'BAJA', 2024, DATE '2024-11-05', DATE '2024-12-13');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Diciembre', 'ALTA', 2024, DATE '2024-12-14', DATE '2024-12-31');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Enero', 'ALTA', 2025, DATE '2025-01-01', DATE '2025-01-06');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 07-ene a 11-abr', 'BAJA', 2025, DATE '2025-01-07', DATE '2025-04-11');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Semana Santa', 'ALTA', 2025, DATE '2025-04-12', DATE '2025-04-20');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 21-abr a 30-abr', 'MEDIA', 2025, DATE '2025-04-21', DATE '2025-04-30');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente de Mayo', 'ALTA', 2025, DATE '2025-05-01', DATE '2025-05-04');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 05-may a 13-jun', 'MEDIA', 2025, DATE '2025-05-05', DATE '2025-06-13');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Mitad de Ano', 'ALTA', 2025, DATE '2025-06-14', DATE '2025-07-20');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 21-jul a 14-ago', 'MEDIA', 2025, DATE '2025-07-21', DATE '2025-08-14');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Asuncion', 'ALTA', 2025, DATE '2025-08-15', DATE '2025-08-18');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 19-ago a 09-oct', 'BAJA', 2025, DATE '2025-08-19', DATE '2025-10-09');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Dia de la Raza', 'ALTA', 2025, DATE '2025-10-10', DATE '2025-10-13');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 14-oct a 30-oct', 'BAJA', 2025, DATE '2025-10-14', DATE '2025-10-30');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Todos los Santos', 'ALTA', 2025, DATE '2025-10-31', DATE '2025-11-03');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 04-nov a 12-dic', 'BAJA', 2025, DATE '2025-11-04', DATE '2025-12-12');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Diciembre', 'ALTA', 2025, DATE '2025-12-13', DATE '2025-12-31');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Enero', 'ALTA', 2026, DATE '2026-01-01', DATE '2026-01-12');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 13-ene a 27-mar', 'BAJA', 2026, DATE '2026-01-13', DATE '2026-03-27');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Semana Santa', 'ALTA', 2026, DATE '2026-03-28', DATE '2026-04-05');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 06-abr a 30-abr', 'MEDIA', 2026, DATE '2026-04-06', DATE '2026-04-30');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente de Mayo', 'ALTA', 2026, DATE '2026-05-01', DATE '2026-05-03');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 04-may a 12-jun', 'MEDIA', 2026, DATE '2026-05-04', DATE '2026-06-12');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Mitad de Ano', 'ALTA', 2026, DATE '2026-06-13', DATE '2026-07-20');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Media 21-jul a 13-ago', 'MEDIA', 2026, DATE '2026-07-21', DATE '2026-08-13');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Asuncion', 'ALTA', 2026, DATE '2026-08-14', DATE '2026-08-17');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 18-ago a 08-oct', 'BAJA', 2026, DATE '2026-08-18', DATE '2026-10-08');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Dia de la Raza', 'ALTA', 2026, DATE '2026-10-09', DATE '2026-10-12');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 13-oct a 29-oct', 'BAJA', 2026, DATE '2026-10-13', DATE '2026-10-29');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Puente Todos los Santos', 'ALTA', 2026, DATE '2026-10-30', DATE '2026-11-02');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Baja 03-nov a 11-dic', 'BAJA', 2026, DATE '2026-11-03', DATE '2026-12-11');
INSERT INTO temporada (nombre, tipo_temporada, anio, fecha_inicio, fecha_fin) VALUES ('Fin de Ano - Diciembre', 'ALTA', 2026, DATE '2026-12-12', DATE '2026-12-31');

-- 1.4 ALOJAMIENTO (64 alojamientos repartidos de forma desigual: Armenia 11 ... Cordoba 2)
--     fecha_registro: casi todos anteriores a 2024; unos pocos entran en 2024-2025 (no reciben
--     reservas antes de registrarse).
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Gran Centro Armenia', 'Avenida 17 # 1-40, Avenida Bolivar', 5, '6067726395', 'reservas@hotelgrancentro.co', DATE '2022-01-27');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Portal del Eje', 'Calle 9 # 41-41, Granada', 4, '6067872027', 'reservas@hotelportaleje.co', DATE '2022-08-30');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Casa Real Quindio', 'Avenida 14 # 17-98, Avenida Bolivar', 4, '3135436730', 'reservas@hotelcasareal.com.co', DATE '2021-01-10');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Plaza Bolivar Inn', 'Carrera 15 # 5-8, La Castellana', 3, '3233022292', 'reservas@hotelplazabolivar.com', DATE '2023-08-09');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Boutique La Castellana', 'Avenida 1 # 7-89, Ciudad Dorada', 4, '3012468849', 'reservas@hotelboutiquecastellana.com.co', DATE '2022-06-11');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Torre Cafetera', 'Avenida 8 # 8-94, Ciudad Dorada', 4, '6067881902', 'reservas@apartahoteltorrecafetera.com', DATE '2024-11-13');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Mirador del Norte', 'Calle 25 # 16-69, Centro', 4, '6067527161', NULL, DATE '2023-07-09');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Los Almendros', 'Calle 5 # 28-37, Granada', 3, NULL, 'reservas@apartahotelalmendros.co', DATE '2025-03-19');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Residencias El Bosque', 'Carrera 21 # 12-38, Granada', 3, '6067900652', 'reservas@apartahotelresidenciasbosque.com', DATE '2022-11-04');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Mochileros del Quindio', 'Avenida 15 # 5-20, Ciudad Dorada', 3, '3002343013', 'reservas@hostalmochilerosquindio.com', DATE '2022-12-16');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Armenia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal La Carrera 14', 'Calle 11 # 23-73, Ciudad Dorada', 2, '3038321743', 'reservas@hostalcarrera14.com.co', DATE '2021-10-02');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera El Cafetal Dorado', 'Vereda Valle de Cocora, km 1 via Salento', 4, '3101421808', NULL, DATE '2021-09-20');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca La Esmeralda de Boquia', 'Vereda Valle de Cocora, km 7 via Salento', 4, '3247788739', 'reservas@fincaesmeraldaboquia.com', DATE '2024-09-17');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera Alto Cocora', 'Vereda La Nubia, km 10 via Salento', 3, '3211049247', 'reservas@fincacafeteraalto.com.co', DATE '2021-11-18');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Hacienda Los Nogales', 'Vereda Palestina, km 2 via Salento', 5, NULL, 'reservas@fincahaciendanogales.co', DATE '2023-07-02');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Bosque de Niebla', 'Vereda La Nubia, km 11 via Salento', 5, '3124364043', 'reservas@glampingbosqueniebla.com', DATE '2023-05-19');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Palmas de Cera', 'Vereda Valle de Cocora, km 12 via Salento', 5, '3143447104', 'reservas@glampingpalmascera.co', DATE '2023-06-26');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Cielo Abierto Cocora', 'Vereda La Nubia, km 12 via Salento', 4, '3227066298', NULL, DATE '2023-11-05');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Casa Callejera Salento', 'Avenida 7 # 44-77, Parque Principal', 3, '3235580100', 'reservas@hostalcasacallejera.co', DATE '2021-03-03');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal El Trapiche', 'Carrera 19 # 43-69, Centro', 2, '3042550232', 'reservas@hostaltrapiche.com.co', DATE '2021-07-11');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Salento'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Boutique Balcones de Salento', 'Calle 14 # 56-17, Parque Principal', 4, '6067767152', 'reservas@hotelboutiquebalcones.com.co', DATE '2022-05-11');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca El Mirador de Filandia', 'Vereda Bambuco, km 2 via Filandia', 4, '3227070666', 'reservas@fincamiradorfilandia.co', DATE '2022-07-19');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera La Aurora', 'Vereda Bambuco, km 10 via Filandia', 3, '3002180428', 'reservas@fincacafeteraaurora.com.co', DATE '2023-04-25');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Villa Amparo', 'Vereda Fachadas, km 12 via Filandia', 0, '3214338829', 'reservas@fincavillaamparo.com.co', DATE '2023-01-23');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Colibri Encantado', 'Vereda La Julia, km 6 via Filandia', 4, '3030672517', 'reservas@glampingcolibriencantado.com.co', DATE '2022-11-26');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal La Cima Filandia', 'Avenida 9 # 19-79, Parque Principal', 3, '3132123882', 'reservas@hostalcimafilandia.com', DATE '2023-07-21');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Filandia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Casa Campesina Filandia', 'Avenida 22 # 53-91, Parque Principal', 3, '3229628284', 'reservas@hotelcasacampesina.co', DATE '2023-02-27');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Campestre Pueblo Tapao', 'Carrera 11 # 27-71, Centro', 4, '3024449273', NULL, DATE '2022-11-28');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera Las Acacias', 'Vereda Pueblo Tapao, km 8 via Montenegro', 4, '3117227401', 'reservas@fincacafeteraacacias.com.co', DATE '2023-07-28');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Hotel El Recuerdo', 'Vereda Jazmin, km 5 via Montenegro', 4, '3239313808', 'reservas@fincahotelrecuerdo.com.co', DATE '2023-10-08');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca La Primavera', 'Vereda Jazmin, km 3 via Montenegro', 3, '3215176378', 'reservas@fincaprimavera.com', DATE '2025-04-30');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Valles del Quindio', 'Calle 7 # 34-16, Centro', 3, '6067736258', 'reservas@apartahotelvallesquindio.com', DATE '2021-03-02');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Montenegro'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Jazmin del Bosque', 'Vereda Jazmin, km 6 via Montenegro', 4, '3048018557', 'reservas@glampingjazminbosque.co', DATE '2021-10-09');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Los Arrieros Calarca', 'Avenida 9 # 43-58, Centro', 4, '3002250249', 'reservas@hotelarrieroscalarca.com', DATE '2023-04-26');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera Barcelona Alta', 'Vereda La Bella, km 12 via Calarca', 3, '3038191597', 'reservas@fincacafeterabarcelona.com', DATE '2023-11-20');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca La Bella Vista', 'Vereda La Bella, km 8 via Calarca', 4, '3141201535', NULL, DATE '2021-07-22');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Central Calarca', 'Calle 1 # 51-73, Parque Principal', 2, '3131530817', 'reservas@hostalcentralcalarca.com.co', DATE '2021-12-01');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Calarca Suites', 'Calle 22 # 40-47, Centro', 3, '3143498776', 'reservas@apartahotelcalarcasuites.com', DATE '2023-07-12');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Calarca'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Lomas del Cafe', 'Vereda Quebrada Negra, km 7 via Calarca', 4, '3219161459', 'reservas@glampinglomascafe.co', DATE '2023-09-23');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Quimbaya'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Parque Panaca Plaza', 'Carrera 14 # 1-57, Parque Principal', 4, '3034703221', 'reservas@hotelparquepanaca.com', DATE '2021-03-09');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Quimbaya'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Hotel Los Guaduales', 'Vereda Alejandria, km 9 via Quimbaya', 4, '3049293046', NULL, DATE '2021-10-02');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Quimbaya'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca El Descanso de Quimbaya', 'Vereda Membrillal, km 6 via Quimbaya', 3, '3115323272', 'reservas@fincadescansoquimbaya.com.co', DATE '2023-04-22');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Quimbaya'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Guadua y Estrellas', 'Vereda La Cuchilla, km 10 via Quimbaya', 5, '3030785293', 'reservas@glampingguaduaestrellas.co', DATE '2023-12-24');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Quimbaya'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Villa Quimbaya', 'Avenida 10 # 28-22, Centro', 3, '3200827291', 'reservas@hostalvillaquimbaya.co', DATE '2024-10-15');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'La Tebaida'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Aeropuerto El Eden', 'Avenida 8 # 4-20, Parque Principal', 3, '6067240177', 'reservas@hotelaeropuertoeden.com.co', DATE '2022-09-14');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'La Tebaida'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Apartahotel'), 'Apartahotel Tebaida Inn', 'Avenida 3 # 37-68, Parque Principal', 3, '6067805038', NULL, DATE '2022-09-05');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'La Tebaida'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Recreativa Las Palmas', 'Vereda Padilla, km 6 via La Tebaida', 3, '3213432260', 'reservas@fincarecreativapalmas.com', DATE '2022-06-29');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'La Tebaida'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Hotel Rio Verde', 'Vereda Padilla, km 4 via La Tebaida', 4, '3125374577', 'reservas@fincahotelrio.com', DATE '2021-11-27');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'La Tebaida'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Brisas del Quindio', 'Avenida 22 # 39-18, Centro', 2, '3229405169', 'reservas@hostalbrisasquindio.com', DATE '2023-02-16');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Circasia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera La Siria', 'Vereda La Siria, km 6 via Circasia', 4, '3114766882', NULL, DATE '2022-04-28');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Circasia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Membrillal Alto', 'Vereda La Siria, km 7 via Circasia', 3, '3143965970', 'reservas@fincamembrillalalto.co', DATE '2021-06-04');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Circasia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca El Ocaso', 'Vereda Hojas Anchas, km 6 via Circasia', 0, '3127560007', 'reservas@fincaocaso.com', DATE '2022-01-28');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Circasia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Nido del Condor', 'Vereda La Siria, km 1 via Circasia', 4, '3015606929', 'reservas@glampingnidocondor.co', DATE '2022-02-25');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Circasia'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hotel'), 'Hotel Boutique Portal de Circasia', 'Carrera 8 # 35-35, Centro', 3, '6067673637', 'reservas@hotelboutiqueportal.com', DATE '2023-06-18');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Pijao'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Pijao Cittaslow', 'Calle 6 # 44-81, Centro', 3, '3149075112', 'reservas@hostalpijaocittaslow.com.co', DATE '2023-10-09');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Pijao'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera Los Andes', 'Vereda Berlin, km 5 via Pijao', 3, '3238012319', 'reservas@fincacafeteraandes.com.co', DATE '2022-08-31');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Pijao'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Glamping'), 'Glamping Refugio del Rio', 'Vereda Rio Lejos, km 5 via Pijao', 4, '3023067988', 'reservas@glampingrefugiorio.co', DATE '2023-09-19');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Buenavista'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Mirador de Buenavista', 'Vereda La Cima, km 3 via Buenavista', 3, '3141313213', 'reservas@fincamiradorbuenavista.co', DATE '2022-10-25');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Buenavista'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca La Pradera', 'Vereda Santa Rita, km 10 via Buenavista', 3, '3020611123', 'reservas@fincapradera.com.co', DATE '2023-10-14');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Buenavista'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Vista al Valle', 'Carrera 19 # 45-32, Centro', 2, NULL, 'reservas@hostalvistavalle.com', DATE '2023-08-24');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Genova'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Cafetera Rio Rojo', 'Vereda Cumbarco, km 7 via Genova', 3, '3237320914', 'reservas@fincacafeterario.co', DATE '2023-10-08');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Genova'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Genoveses', 'Avenida 17 # 60-2, Parque Principal', 2, '3137542931', NULL, DATE '2021-12-30');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Cordoba'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Finca cafetera'), 'Finca Los Pinos de Cordoba', 'Vereda Los Pinos, km 11 via Cordoba', 3, '3144637896', 'reservas@fincapinoscordoba.com.co', DATE '2024-03-08');
INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, calificacion_estrellas, telefono_contacto, correo_contacto, fecha_registro) VALUES ((SELECT id_municipio FROM municipio WHERE nombre = 'Cordoba'), (SELECT id_tipo_alojamiento FROM tipo_alojamiento WHERE nombre = 'Hostal'), 'Hostal Puerta del Quindio', 'Carrera 9 # 50-52, Centro', 2, '3210181295', 'reservas@hostalpuertaquindio.co', DATE '2023-10-03');

-- 1.5 HABITACION (504 habitaciones; hoteles grandes de 30-40, fincas pequenas de 3-6)
--     El identificador del alojamiento se resuelve por nombre comercial, no por numero fijo.
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 4, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 3, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 5, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '301', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '302', 3, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '303', 4, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '304', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '305', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '306', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '307', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '308', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '309', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '310', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '401', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '402', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '403', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '404', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '405', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '406', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '407', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '408', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '409', 4, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '410', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 4, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 4, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '301', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '302', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '303', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '304', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '305', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '306', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '307', 4, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '308', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '309', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '310', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '401', 5, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '402', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '403', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '404', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '301', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '302', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '303', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '304', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 3, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 4, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 4, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 5, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 5, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 5, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 5, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 4, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 4, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 4, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 6, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 5, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 4, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 8, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '6', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '7', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '8', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '9', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '10', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '6', 5, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '7', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 8, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 6, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 8, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 4, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 4, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 6, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 7, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H6', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D5', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 2, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D5', 2, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D6', 3, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 2, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '6', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '7', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '8', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 4, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 7, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 7, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 5, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H4', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 4, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C3', 7, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 4, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '6', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '7', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 5, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 4, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H4', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 5, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 5, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 3, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 3, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 5, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 2, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 4, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 7, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 4, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 8, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C3', 8, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 6, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 5, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 6, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 5, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 4, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 3, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D5', 2, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 3, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '301', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '302', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '303', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '304', 3, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '305', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '306', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '307', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '308', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '309', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '310', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 6, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C3', 4, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C4', 7, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H6', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 7, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 3, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 2, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D5', 2, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D6', 2, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 5, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 8, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '6', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 1, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '109', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '110', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '201', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '202', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '203', 4, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '204', 4, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '205', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '206', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '207', 4, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '208', 3, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '209', 3, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '210', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '301', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '302', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 5, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 5, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 5, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 4, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '107', 5, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '108', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C3', 8, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H4', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H4', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H5', 3, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H6', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 7, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'SUITE', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H4', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 7, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 4, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 5, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 3, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 2, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D4', 3, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '101', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '102', 5, 'SUITE', 'Suite con sala, jacuzzi y vista panoramica' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '103', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '104', 2, 'SENCILLA', 'Habitacion sencilla con bano privado y TV' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '105', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '106', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '5', 2, 'DOBLE', 'Habitacion doble con vista al paisaje cafetero' FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 8, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H2', 2, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C3', 5, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D1', 2, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D2', 2, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'D3', 3, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C1', 8, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 6, 'CABANA', 'Cabana familiar con dos habitaciones y zona BBQ' FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 4, 'CABANA', 'Cabana independiente con cocineta y terraza' FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'SUITE', 'Suite familiar con dos ambientes y bano amplio' FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 4, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'SUITE', 'Suite con terraza privada y desayuno incluido' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 7, 'CABANA', 'Cabana rustica en guadua con chimenea' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 2, 'DOBLE', NULL FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H1', 3, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'C2', 6, 'CABANA', NULL FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, 'H3', 3, 'DOBLE', 'Habitacion doble con aire acondicionado y minibar' FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '1', 1, 'SENCILLA', 'Habitacion individual con escritorio y wifi' FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '2', 1, 'SENCILLA', 'Habitacion sencilla con ventilador y agua caliente' FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '3', 6, 'DOBLE', 'Habitacion compartida con literas, bano compartido' FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO habitacion (id_alojamiento, numero, capacidad_maxima, tipo_habitacion, descripcion) SELECT id_alojamiento, '4', 2, 'DOBLE', 'Habitacion doble con bano privado y balcon' FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';

-- 1.5b SERVICIO (408 servicios; cada alojamiento tiene su propia oferta, minimo 4)
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 76000 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 111500 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 152500 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 187500 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 35000 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 129000 FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 34000 FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 78500 FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 114500 FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 193000 FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 36000 FROM alojamiento WHERE nombre_comercial = 'Hotel Portal del Eje';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 38500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 66000 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 96000 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 30500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 111500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Real Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 24000 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 56000 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 81500 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 30000 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 112000 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 26000 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 15500 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 94500 FROM alojamiento WHERE nombre_comercial = 'Hotel Plaza Bolivar Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 34500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 47000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 80500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 118000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 43500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 93000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 37000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 22500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique La Castellana';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 62500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 91000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 33500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 124500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 28500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 17000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 86000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 24000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 55500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 81000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 25500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 15500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 94000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Mirador del Norte';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 31500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 107500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 34000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 20500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 124500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Los Almendros';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 134500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 31000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 18500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Residencias El Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29500 FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 68000 FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36500 FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 42000 FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 55500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 30000 FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 25500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 15500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Carrera 14';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 37000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 50000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 125000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 46000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 98500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 112000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 144500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 52500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29500 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 39500 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 68000 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36500 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 89000 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 42000 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 94000 FROM alojamiento WHERE nombre_comercial = 'Finca La Esmeralda de Boquia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 77000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 112500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 101000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 189500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 47500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Alto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 32000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 43500 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 74000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 51000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 40000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 85500 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 97000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 182000 FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 39500 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 68000 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36500 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 136000 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 78500 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 89000 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 167500 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 42000 FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29000 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 39000 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 67000 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 46500 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36000 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 133500 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 77000 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 87500 FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45500 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 78000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 156000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 90000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 102000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 192000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 132000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 48000 FROM alojamiento WHERE nombre_comercial = 'Glamping Cielo Abierto Cocora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 36000 FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 45000 FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 109000 FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 38500 FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 36500 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 85000 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 45500 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 111000 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 39000 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 143500 FROM alojamiento WHERE nombre_comercial = 'Hostal El Trapiche';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 32500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 110000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 150500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Caminata Valle de Cocora', 'Caminata guiada con transporte en Willys hasta el Valle de Cocora', 98500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 185500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 34500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 21000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 127500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Balcones de Salento';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 30500 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 70500 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 49000 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 103500 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 43500 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 98000 FROM alojamiento WHERE nombre_comercial = 'Finca El Mirador de Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 31500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 42500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 72500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 50500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 39000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 84000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 179000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 44500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Aurora';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 28500 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 38500 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 66000 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 45500 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 96500 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 112000 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 91500 FROM alojamiento WHERE nombre_comercial = 'Finca Villa Amparo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 35500 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 48000 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 82500 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 57000 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 165000 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 95000 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 203000 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 50500 FROM alojamiento WHERE nombre_comercial = 'Glamping Colibri Encantado';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 66000 FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 35500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 162500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 40500 FROM alojamiento WHERE nombre_comercial = 'Hostal La Cima Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45000 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 53500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 112500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 89000 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 35500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 21500 FROM alojamiento WHERE nombre_comercial = 'Hotel Casa Campesina Filandia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 32000 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 43500 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 74000 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 108500 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 40000 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 148500 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 85500 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 34000 FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 30500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 71000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 49000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 141500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 120000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 43500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Las Acacias';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 78000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 42000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 90000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 48000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel El Recuerdo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 34000 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 46000 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 79000 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 115500 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 42500 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 91000 FROM alojamiento WHERE nombre_comercial = 'Finca La Primavera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 99000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 135500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 19000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Valles del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 27000 FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 72500 FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 155000 FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 17500 FROM alojamiento WHERE nombre_comercial = 'Glamping Jazmin del Bosque';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 28000 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 38000 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 45500 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 95500 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 35000 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 161000 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 30000 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 90500 FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 27000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 63000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 43500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 72500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 154500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Barcelona Alta';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45000 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 77000 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 53000 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41500 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 154000 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 88500 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 189500 FROM alojamiento WHERE nombre_comercial = 'Finca La Bella Vista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 26000 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 35500 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 42000 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 88000 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 32500 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 28000 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 16500 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 37000 FROM alojamiento WHERE nombre_comercial = 'Hostal Central Calarca';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 34000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 79500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 116000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 36500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 22000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Calarca Suites';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 34000 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 46500 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 79000 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 158500 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 91500 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 195000 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 48500 FROM alojamiento WHERE nombre_comercial = 'Glamping Lomas del Cafe';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29500 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 69000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 101000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 37000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 138000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 32000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 19000 FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 26000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 35500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 60500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 149500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 37500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Los Guaduales';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 25500 FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 60000 FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 101000 FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 32000 FROM alojamiento WHERE nombre_comercial = 'Finca El Descanso de Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 26500 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 36000 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 61500 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 42500 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 123000 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 71000 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 38000 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 85000 FROM alojamiento WHERE nombre_comercial = 'Glamping Guadua y Estrellas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 32000 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 43500 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 74500 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 109000 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 40000 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 34500 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 46000 FROM alojamiento WHERE nombre_comercial = 'Hostal Villa Quimbaya';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29000 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 67500 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 99000 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36500 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 135500 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 78000 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 166500 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 31000 FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 68500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 37000 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 31500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 116500 FROM alojamiento WHERE nombre_comercial = 'Apartahotel Tebaida Inn';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 26500 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 36000 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 62000 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 43000 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 38000 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 86000 FROM alojamiento WHERE nombre_comercial = 'Finca Recreativa Las Palmas';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 40000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 68500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 47500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 79000 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 31500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 42500 FROM alojamiento WHERE nombre_comercial = 'Finca Hotel Rio Verde';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 47000 FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 43500 FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 93000 FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 117500 FROM alojamiento WHERE nombre_comercial = 'Hostal Brisas del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 44000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 75500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 52500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 46500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera La Siria';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 29000 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 39000 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 67000 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 36000 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 77500 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 113500 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 41500 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 93000 FROM alojamiento WHERE nombre_comercial = 'Finca Membrillal Alto';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33500 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45000 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 77500 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 53500 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 113000 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41500 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 89000 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 107000 FROM alojamiento WHERE nombre_comercial = 'Finca El Ocaso';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 25500 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 34500 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 59500 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 87000 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 119000 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 68500 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 36500 FROM alojamiento WHERE nombre_comercial = 'Glamping Nido del Condor';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 28500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 66500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 97000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 163000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 30500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 18500 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 41000 FROM alojamiento WHERE nombre_comercial = 'Hotel Boutique Portal de Circasia';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33500 FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 77500 FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 53500 FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 35500 FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 21500 FROM alojamiento WHERE nombre_comercial = 'Hostal Pijao Cittaslow';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 24500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 57000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 39500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 114500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 66000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 141000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Los Andes';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 25000 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 34000 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 31500 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 116500 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cena romantica', 'Cena para dos con decoracion y musica', 143500 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Parqueadero cubierto', 'Parqueadero cubierto por noche', 16000 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 36000 FROM alojamiento WHERE nombre_comercial = 'Glamping Refugio del Rio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 31000 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 42000 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 71500 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 49500 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 104500 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 82500 FROM alojamiento WHERE nombre_comercial = 'Finca Mirador de Buenavista';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45000 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 77000 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 112500 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41500 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 89000 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 35500 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 107000 FROM alojamiento WHERE nombre_comercial = 'Finca La Pradera';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 35000 FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 93500 FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 37500 FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Excursion a parques tematicos', 'Transporte y acompanamiento a Panaca o al Parque del Cafe', 137000 FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 50000 FROM alojamiento WHERE nombre_comercial = 'Hostal Vista al Valle';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 45500 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 78000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 114000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 90000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 48000 FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera Rio Rojo';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 33000 FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Transporte aeropuerto El Eden', 'Traslado privado desde o hacia el aeropuerto El Eden', 111500 FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 41000 FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 47000 FROM alojamiento WHERE nombre_comercial = 'Hostal Genoveses';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 30500 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 70500 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 49000 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 38000 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Spa y masajes', 'Masaje relajante de 60 minutos', 141000 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Cabalgata guiada', 'Paseo a caballo por senderos cafeteros de 2 horas', 81500 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Fogata y malvaviscos', 'Noche de fogata con malvaviscos y chocolate caliente', 43500 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Avistamiento de aves', 'Recorrido de observacion de aves con guia local', 97500 FROM alojamiento WHERE nombre_comercial = 'Finca Los Pinos de Cordoba';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Desayuno tipico', 'Desayuno con arepa, huevos pericos, chocolate y cafe de la region', 27500 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Almuerzo campesino', 'Bandeja paisa o sancocho de gallina servido en el comedor', 37000 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Tour guiado por cafetal', 'Recorrido guiado por el cultivo, beneficio y secado del cafe', 63500 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Degustacion de cafes especiales', 'Cata guiada de cafes de origen con barista', 44000 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Alquiler de bicicletas', 'Bicicleta de montana por dia con casco', 34000 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';
INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio) SELECT id_alojamiento, 'Lavanderia', 'Servicio de lavado y planchado por bolsa', 29500 FROM alojamiento WHERE nombre_comercial = 'Hostal Puerta del Quindio';

-- 1.6 USUARIO_SISTEMA (2 administradores globales + encargados: 1 por cada tipo de alojamiento, mas otros)
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES (NULL, 'Carolina Restrepo Giraldo', 'crestrepo@turismouq.com', 'ADMINISTRADOR', DATE '2023-11-06');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES (NULL, 'Andres Felipe Ospina Cardona', 'aospina@turismouq.com', 'ADMINISTRADOR', DATE '2023-11-06');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hotel Gran Centro Armenia'), 'Luz Marina Salazar', 'luz.salazar@hotelgrancentro.com', 'ENCARGADO', DATE '2023-12-04');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Apartahotel Torre Cafetera'), 'Jhon Fredy Marin', 'jhon.marin@apartahoteltorrecafetera.com', 'ENCARGADO', DATE '2024-01-15');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Finca Cafetera El Cafetal Dorado'), 'Gloria Patricia Zapata', 'gloria.zapata@fincacafeteracafetal.com', 'ENCARGADO', DATE '2024-01-22');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Glamping Bosque de Niebla'), 'Santiago Botero Duque', 'santiago.duque@glampingbosqueniebla.com', 'ENCARGADO', DATE '2024-02-12');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hostal Mochileros del Quindio'), 'Yesenia Cano Henao', 'yesenia.henao@hostalmochilerosquindio.com', 'ENCARGADO', DATE '2024-02-19');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hotel Parque Panaca Plaza'), 'Hernan Dario Trujillo', 'hernan.trujillo@hotelparquepanaca.com', 'ENCARGADO', DATE '2024-03-11');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hotel Aeropuerto El Eden'), 'Paola Andrea Idarraga', 'paola.idarraga@hotelaeropuertoeden.com', 'ENCARGADO', DATE '2024-05-06');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hotel Los Arrieros Calarca'), 'Mauricio Naranjo Rios', 'mauricio.rios@hotelarrieroscalarca.com', 'ENCARGADO', DATE '2024-06-17');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Finca Hacienda Los Nogales'), 'Diana Carolina Vargas', 'diana.vargas@fincahaciendanogales.com', 'ENCARGADO', DATE '2024-09-02');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Glamping Palmas de Cera'), 'Fabian Alzate Correa', 'fabian.correa@glampingpalmascera.com', 'ENCARGADO', DATE '2025-01-13');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hostal Casa Callejera Salento'), 'Sandra Milena Orozco', 'sandra.orozco@hostalcasacallejera.com', 'ENCARGADO', DATE '2025-03-24');
INSERT INTO usuario_sistema (id_alojamiento, nombre, correo, rol, fecha_creacion) VALUES ((SELECT id_alojamiento FROM alojamiento WHERE nombre_comercial = 'Hotel Campestre Pueblo Tapao'), 'Cristian Camilo Uribe', 'cristian.uribe@hotelcampestrepueblo.com', 'ENCARGADO', DATE '2025-08-04');

COMMIT;

-- =====================================================================================
-- 2. TARIFA  (una fila por habitacion x temporada = cruce completo)
--    Precio base segun tipo de habitacion y capacidad, ajustado por tipo de alojamiento,
--    estrellas y municipio. Cada alojamiento define su propio recargo de temporada alta
--    (entre +10 % y +65 %) y de temporada media (entre 0 % y +20 %): NO es un porcentaje fijo.
--    Los precios crecen con los anios (2024 -12 %, 2025 -6 % respecto a 2026: inflacion).
-- =====================================================================================
DECLARE
  v_mult_tipo NUMBER; v_mult_est NUMBER; v_mult_muni NUMBER;
  v_fac_aloj  NUMBER; v_f_alta NUMBER; v_f_media NUMBER;
BEGIN
  DBMS_RANDOM.SEED('&semilla');
  FOR a IN (SELECT al.id_alojamiento, al.calificacion_estrellas AS est, ta.nombre AS tipo, mu.nombre AS muni
              FROM alojamiento al
              JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = al.id_tipo_alojamiento
              JOIN municipio mu ON mu.id_municipio = al.id_municipio
             ORDER BY al.id_alojamiento) LOOP
    v_mult_tipo := CASE a.tipo WHEN 'Hotel' THEN 1.0 WHEN 'Finca cafetera' THEN 1.15
                               WHEN 'Glamping' THEN 1.9 WHEN 'Hostal' THEN 0.55 ELSE 1.05 END;
    v_mult_est  := CASE a.est WHEN 0 THEN 0.85 WHEN 1 THEN 0.7 WHEN 2 THEN 0.85
                              WHEN 3 THEN 1.0 WHEN 4 THEN 1.25 ELSE 1.6 END;
    v_mult_muni := CASE a.muni WHEN 'Salento' THEN 1.25 WHEN 'Filandia' THEN 1.15 WHEN 'Circasia' THEN 0.95
                               WHEN 'Calarca' THEN 0.95 WHEN 'La Tebaida' THEN 0.9 WHEN 'Pijao' THEN 1.05
                               WHEN 'Genova' THEN 0.85 WHEN 'Cordoba' THEN 0.85 ELSE 1.0 END;
    v_fac_aloj  := DBMS_RANDOM.VALUE(0.90, 1.15);
    v_f_alta    := DBMS_RANDOM.VALUE(1.10, 1.65);
    v_f_media   := DBMS_RANDOM.VALUE(1.00, 1.20);

    INSERT INTO tarifa (id_habitacion, id_temporada, precio_noche)
    SELECT h.id_habitacion, t.id_temporada,
           GREATEST(35000, ROUND(
             (CASE h.tipo_habitacion WHEN 'SENCILLA' THEN 90000 WHEN 'DOBLE' THEN 140000
                                     WHEN 'SUITE' THEN 240000 ELSE 220000 END)
             * (0.85 + 0.075 * LEAST(h.capacidad_maxima, 8))
             * v_mult_tipo * v_mult_est * v_mult_muni * v_fac_aloj
             * (CASE t.tipo_temporada WHEN 'ALTA' THEN v_f_alta WHEN 'MEDIA' THEN v_f_media ELSE 1 END)
             * (CASE t.anio WHEN 2024 THEN 0.88 WHEN 2025 THEN 0.94 ELSE 1 END)
             * DBMS_RANDOM.VALUE(0.96, 1.04), -3))
      FROM habitacion h CROSS JOIN temporada t
     WHERE h.id_alojamiento = a.id_alojamiento;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('TARIFA cargada.');
END;
/

-- =====================================================================================
-- 3. CLIENTE  (3.200 clientes)
--    Documento unico por construccion (i * 9973 + ruido < 9973). Correo unico porque incluye i.
--    fecha_registro se ajusta en la seccion 5 a la fecha de su primera reserva.
-- =====================================================================================
DECLARE
  c_clientes CONSTANT PLS_INTEGER := 3200;
  l_hom SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Juan','Carlos','Andres','Camilo','Santiago','Felipe','Sebastian','Daniel',
      'Julian','Mateo','Alejandro','Jorge','Luis','Diego','David','Nicolas','Miguel','Oscar','Jairo','Fabian','Cristian',
      'Esteban','Hernan','Ricardo','Mauricio','Jhon','Wilson','Alvaro','Edwin','Sergio');
  l_muj SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Maria','Laura','Camila','Valentina','Sofia','Daniela','Paula','Natalia',
      'Andrea','Carolina','Juliana','Manuela','Luisa','Diana','Angela','Claudia','Paola','Katherine','Viviana','Lina',
      'Sandra','Marcela','Isabella','Lucia','Gloria','Yesenia','Johana','Alejandra','Monica','Liliana');
  l_ape SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Garcia','Rodriguez','Martinez','Lopez','Gonzalez','Hernandez','Ramirez',
      'Torres','Ospina','Giraldo','Restrepo','Zapata','Salazar','Cardona','Marin','Vargas','Castano','Jimenez','Gomez','Arias',
      'Botero','Duque','Franco','Henao','Londono','Montoya','Orozco','Patino','Quintero','Rios','Suarez','Trujillo','Valencia',
      'Velez','Aristizabal','Buitrago','Cano','Echeverri','Grisales','Idarraga','Naranjo','Osorio','Parra','Rojas','Sanchez',
      'Uribe','Cortes','Diaz','Moreno','Pineda','Ruiz','Mejia','Aguirre','Bedoya','Correa','Alzate','Ceballos','Tabares');
  l_dom SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('gmail.com','gmail.com','gmail.com','gmail.com','hotmail.com','hotmail.com',
      'outlook.com','yahoo.es','icloud.com','unal.edu.co','uniquindio.edu.co','empresa.com.co');
  l_ciu SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Bogota','Medellin','Cali','Pereira','Armenia','Manizales','Barranquilla',
      'Bucaramanga','Cartagena','Ibague','Cucuta','Pasto','Neiva','Villavicencio','Tulua','Palmira','Popayan','Santa Marta',
      'Miami, EEUU','Madrid, Espana','Buenos Aires, Argentina','Ciudad de Mexico, Mexico','Quito, Ecuador','Lima, Peru',
      'Nueva York, EEUU','Santiago, Chile','Paris, Francia');
  l_pes SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(24,14,12,8,6,5,4,3,2,3,1,1,1,1,1,1,1,1,
      1,1,0.6,0.6,0.5,0.5,0.5,0.4,0.3);
  v_pn VARCHAR2(30); v_a1 VARCHAR2(30); v_a2 VARCHAR2(30); v_nombre VARCHAR2(150);
  v_doc VARCHAR2(20); v_ciudad VARCHAR2(100); v_tel VARCHAR2(20); v_correo VARCHAR2(100);

  FUNCTION pick(l SYS.ODCIVARCHAR2LIST) RETURN VARCHAR2 IS
  BEGIN
    RETURN l(TRUNC(DBMS_RANDOM.VALUE(1, l.COUNT + 1)));
  END;

  FUNCTION pick_w(l SYS.ODCIVARCHAR2LIST, w SYS.ODCINUMBERLIST) RETURN VARCHAR2 IS
    v_tot NUMBER := 0; v_r NUMBER; v_acc NUMBER := 0;
  BEGIN
    FOR k IN 1 .. w.COUNT LOOP v_tot := v_tot + w(k); END LOOP;
    v_r := DBMS_RANDOM.VALUE * v_tot;
    FOR k IN 1 .. w.COUNT LOOP
      v_acc := v_acc + w(k);
      IF v_r <= v_acc THEN RETURN l(k); END IF;
    END LOOP;
    RETURN l(l.COUNT);
  END;
BEGIN
  DBMS_RANDOM.SEED('&semilla' || '-clientes');
  FOR i IN 1 .. c_clientes LOOP
    IF DBMS_RANDOM.VALUE < 0.5 THEN v_pn := pick(l_hom); ELSE v_pn := pick(l_muj); END IF;
    v_a1 := pick(l_ape);
    v_a2 := pick(l_ape);
    v_nombre := v_pn;
    IF DBMS_RANDOM.VALUE < 0.25 THEN
      v_nombre := v_nombre || ' ' || CASE WHEN DBMS_RANDOM.VALUE < 0.5 THEN pick(l_hom) ELSE pick(l_muj) END;
    END IF;
    v_nombre := v_nombre || ' ' || v_a1 || ' ' || v_a2;

    v_ciudad := pick_w(l_ciu, l_pes);
    IF INSTR(v_ciudad, ',') > 0 THEN
      v_doc := 'PA' || LPAD(i, 4, '0') || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100, 1000)));   -- pasaporte
    ELSE
      v_doc := TO_CHAR(20000000 + i * 9973 + TRUNC(DBMS_RANDOM.VALUE(0, 9000)));            -- cedula
    END IF;
    IF DBMS_RANDOM.VALUE < 0.05 THEN v_ciudad := NULL; END IF;
    IF DBMS_RANDOM.VALUE < 0.08 THEN
      v_tel := NULL;
    ELSE
      v_tel := '3' || LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 25)), 2, '0') || LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 10000000)), 7, '0');
    END IF;
    v_correo := LOWER(v_pn) || '.' || LOWER(v_a1) || i || '@' || pick(l_dom);

    INSERT INTO cliente (nombre, documento_identidad, correo, telefono, ciudad_origen, fecha_registro)
    VALUES (v_nombre, v_doc, v_correo, v_tel, v_ciudad, DATE '2023-06-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1200)));
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('CLIENTE cargado: ' || c_clientes);
END;
/

-- =====================================================================================
-- 4. RESERVAS, LINEAS DE HABITACION, SERVICIOS, PAGOS Y RESENAS
-- -------------------------------------------------------------------------------------
-- Idea general (cada reserva se genera de una vez con todos sus hijos):
--   1) Fecha de check-in por "rechazo ponderado": cada dia tiene un peso (temporada alta x3.2,
--      media x1.5, baja x0.9; viernes/sabado mas fuertes, domingo debil; 2024 crece a 2026;
--      las fechas futuras pesan menos porque aun no se han reservado). Asi hay estacionalidad real.
--   2) Alojamiento por sorteo ponderado por popularidad (tamano^0.7 x municipio x azar): Armenia y
--      Salento concentran demanda, Cordoba y Genova casi nada.
--   3) Habitaciones libres: un mapa en memoria marca (habitacion, noche) ocupadas por reservas NO
--      canceladas, de modo que no haya solapes. Las canceladas no bloquean la habitacion.
--   4) valor_linea = suma noche por noche de la tarifa vigente ese dia (misma regla que en la
--      Entrega 2 debera calcular fn_valor_estadia; sirve para validarla).
--   5) Estado segun la fecha de corte; servicios, pagos y resenas coherentes con el estado.
-- =====================================================================================
DECLARE
  c_objetivo CONSTANT PLS_INTEGER := 25000;        -- reservas a generar
  c_hoy      CONSTANT DATE := DATE '2026-09-29';   -- fecha de corte
  c_inicio   CONSTANT DATE := DATE '2024-01-01';   -- primer dia con check-in posible
  c_fin      CONSTANT DATE := DATE '2027-01-01';   -- ultimo check-out posible
  c_ndias    CONSTANT PLS_INTEGER := 1096;         -- dias entre c_inicio y c_fin

  TYPE t_num  IS TABLE OF NUMBER        INDEX BY PLS_INTEGER;
  TYPE t_dat  IS TABLE OF DATE          INDEX BY PLS_INTEGER;
  TYPE t_vc   IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  TYPE t_bool IS TABLE OF BOOLEAN       INDEX BY PLS_INTEGER;

  -- alojamientos (posicion 1..v_na)
  a_id t_num; a_reg t_dat; a_est t_num; a_muni t_vc; a_pop t_num; a_q t_num;
  a_first t_num; a_n t_num; a_sfirst t_num; a_sn t_num;
  ord_aloj t_num;                                  -- id_alojamiento -> posicion
  -- habitaciones (posicion 1..v_nh, contiguas por alojamiento)
  h_id t_num; h_ord t_num;                         -- h_ord: id_habitacion -> posicion
  -- servicios (posicion 1..v_ns, contiguos por alojamiento)
  s_id t_num; s_prec t_num; s_nom t_vc;
  -- temporadas y calendario
  t_ord t_num; t_tipo t_vc;                        -- t_ord: id_temporada -> posicion
  d_ord t_num; d_w t_num;                          -- por dia (0..c_ndias-1): posicion de temporada / peso
  tar t_num;                                       -- (pos_habitacion*100 + pos_temporada) -> precio_noche
  occ t_bool;                                      -- (pos_habitacion*2000 + dia) -> ocupada
  c_id t_num;                                      -- clientes
  l_ho t_num;                                      -- habitaciones elegidas para la reserva en curso

  v_na PLS_INTEGER := 0; v_nh PLS_INTEGER := 0; v_ns PLS_INTEGER := 0; v_nt PLS_INTEGER := 0; v_ncli PLS_INTEGER := 0;
  v_o PLS_INTEGER; v_len PLS_INTEGER; v_dia PLS_INTEGER; v_d1 PLS_INTEGER; v_d2 PLS_INTEGER;
  v_f DATE; v_w NUMBER; v_wmax NUMBER := 0; v_k NUMBER; v_totpop NUMBER := 0;

  v_n PLS_INTEGER := 0; v_it PLS_INTEGER := 0; v_d PLS_INTEGER; v_noc PLS_INTEGER;
  v_cin DATE; v_cout DATE; v_fres DATE; v_est VARCHAR2(15); v_r NUMBER; v_acc NUMBER;
  v_a PLS_INTEGER; v_k_hab PLS_INTEGER; v_off PLS_INTEGER; v_ho PLS_INTEGER; v_nl PLS_INTEGER; v_libre BOOLEAN;
  v_cli NUMBER; v_idr NUMBER; v_lcin DATE; v_lcout DATE; v_val NUMBER; v_tot_hab NUMBER; v_tot_srv NUMBER; v_total NUMBER;
  v_m PLS_INTEGER; v_soff PLS_INTEGER; v_so PLS_INTEGER; v_cant NUMBER; v_pu NUMBER;
  v_a1 NUMBER; v_paid NUMBER; v_met VARCHAR2(20); v_dias NUMBER; v_fcan DATE;
  v_cal NUMBER; v_com VARCHAR2(1000); v_fres2 DATE;
  v_npag PLS_INTEGER := 0; v_nlin PLS_INTEGER := 0; v_nsrv PLS_INTEGER := 0; v_nrev PLS_INTEGER := 0;

  ---------------------------------------------------------------- funciones de sorteo
  FUNCTION f_noches RETURN PLS_INTEGER IS
    r NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    RETURN CASE WHEN r < 0.12 THEN 1 WHEN r < 0.42 THEN 2 WHEN r < 0.70 THEN 3 WHEN r < 0.82 THEN 4
                WHEN r < 0.89 THEN 5 WHEN r < 0.93 THEN 6 WHEN r < 0.96 THEN 7
                ELSE 8 + TRUNC(DBMS_RANDOM.VALUE(0, 7)) END;
  END;

  FUNCTION f_habs RETURN PLS_INTEGER IS
    r NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    RETURN CASE WHEN r < 0.80 THEN 1 WHEN r < 0.93 THEN 2 WHEN r < 0.97 THEN 3 WHEN r < 0.99 THEN 4
                ELSE 5 + TRUNC(DBMS_RANDOM.VALUE(0, 4)) END;
  END;

  FUNCTION f_anticipacion RETURN PLS_INTEGER IS
    r NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    RETURN CASE WHEN r < 0.25 THEN 1 + TRUNC(DBMS_RANDOM.VALUE(0, 7))
                WHEN r < 0.60 THEN 8 + TRUNC(DBMS_RANDOM.VALUE(0, 23))
                WHEN r < 0.90 THEN 31 + TRUNC(DBMS_RANDOM.VALUE(0, 45))
                ELSE 76 + TRUNC(DBMS_RANDOM.VALUE(0, 75)) END;
  END;

  FUNCTION f_nserv RETURN PLS_INTEGER IS
    r NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    RETURN CASE WHEN r < 0.25 THEN 1 WHEN r < 0.50 THEN 2 WHEN r < 0.72 THEN 3 WHEN r < 0.87 THEN 4
                WHEN r < 0.95 THEN 5 ELSE 6 END;
  END;

  FUNCTION f_metodo(p_saldo BOOLEAN) RETURN VARCHAR2 IS
    r NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    IF p_saldo THEN   -- el saldo se paga mas en efectivo/transferencia al llegar
      RETURN CASE WHEN r < 0.30 THEN 'EFECTIVO' WHEN r < 0.55 THEN 'TRANSFERENCIA' WHEN r < 0.75 THEN 'TARJETA_DEBITO'
                  WHEN r < 0.90 THEN 'PSE' ELSE 'TARJETA_CREDITO' END;
    END IF;
    RETURN CASE WHEN r < 0.38 THEN 'TARJETA_CREDITO' WHEN r < 0.62 THEN 'PSE' WHEN r < 0.80 THEN 'TRANSFERENCIA'
                WHEN r < 0.94 THEN 'TARJETA_DEBITO' ELSE 'EFECTIVO' END;
  END;

  FUNCTION f_comentario(p_cal NUMBER) RETURN VARCHAR2 IS
    i PLS_INTEGER := 1 + TRUNC(DBMS_RANDOM.VALUE(0, 6));
  BEGIN
    IF p_cal = 5 THEN
      RETURN CASE i WHEN 1 THEN 'Excelente atencion y un paisaje cafetero inolvidable. Volveremos.'
        WHEN 2 THEN 'Todo impecable, el personal fue muy amable y el desayuno delicioso.'
        WHEN 3 THEN 'Un lugar hermoso y tranquilo, perfecto para descansar en pareja.'
        WHEN 4 THEN 'Supero nuestras expectativas, la habitacion limpia y con una vista espectacular.'
        WHEN 5 THEN 'Recomendado al 100 %, muy buena relacion calidad precio.'
        ELSE 'Fuimos en familia y los ninos la pasaron increible. Gracias por todo.' END;
    ELSIF p_cal = 4 THEN
      RETURN CASE i WHEN 1 THEN 'Muy buena estadia, solo mejoraria el wifi.'
        WHEN 2 THEN 'Bonito lugar y buena atencion, la ducha tardaba en calentar.'
        WHEN 3 THEN 'Cumplio con lo prometido, ubicacion excelente.'
        WHEN 4 THEN 'Habitaciones comodas y personal atento, el parqueadero es algo pequeno.'
        WHEN 5 THEN 'Buena experiencia en general, repetiriamos en temporada baja.'
        ELSE 'Todo bien, el desayuno podria tener mas variedad.' END;
    ELSIF p_cal = 3 THEN
      RETURN CASE i WHEN 1 THEN 'Estuvo bien pero esperaba un poco mas por el precio.'
        WHEN 2 THEN 'La ubicacion es buena, aunque hubo ruido en la noche.'
        WHEN 3 THEN 'Aceptable, la habitacion algo desgastada.'
        WHEN 4 THEN 'Atencion regular, el lugar es bonito.'
        WHEN 5 THEN 'Cumple para una noche, no para una estadia larga.'
        ELSE 'El paisaje es lindo pero los servicios son basicos.' END;
    ELSIF p_cal = 2 THEN
      RETURN CASE i WHEN 1 THEN 'La habitacion no correspondia con las fotos.'
        WHEN 2 THEN 'Demoraron mucho en el check-in y el agua caliente fallo.'
        WHEN 3 THEN 'Mucho ruido y poca limpieza en areas comunes.'
        WHEN 4 THEN 'No lo recomendaria por el precio que cobran.'
        WHEN 5 THEN 'El acceso es complicado y no nos avisaron.'
        ELSE 'Esperaba mejor servicio, el personal poco atento.' END;
    END IF;
    RETURN CASE i WHEN 1 THEN 'Mala experiencia, la habitacion estaba sucia.'
      WHEN 2 THEN 'No volveria, cobraron servicios que no usamos.'
      WHEN 3 THEN 'Muy decepcionante, nada que ver con lo ofrecido.'
      WHEN 4 THEN 'Pesima atencion y la reserva no fue respetada.'
      WHEN 5 THEN 'Instalaciones en mal estado y sin respuesta a los reclamos.'
      ELSE 'Fue un desastre, pedimos reembolso y no respondieron.' END;
  END;

  ---------------------------------------------------------------- pagos
  PROCEDURE p_pago(p_res NUMBER, p_fec DATE, p_monto NUMBER, p_met VARCHAR2, p_est VARCHAR2) IS
  BEGIN
    INSERT INTO pago (id_reserva, fecha_pago, monto, metodo_pago, estado_pago)
    VALUES (p_res, p_fec, p_monto, p_met, p_est);
    v_npag := v_npag + 1;
  END;

  -- Reserva pagada por completo: pago unico (55 %), anticipo + saldo (35 %) o tres abonos (10 %).
  -- El 5 % de los pagos unicos tuvo antes un intento FALLIDO (tarjeta rechazada).
  PROCEDURE p_plan_completo(p_res NUMBER, p_tot NUMBER, p_fres DATE, p_cin DATE) IS
    r NUMBER := DBMS_RANDOM.VALUE; x1 NUMBER; x2 NUMBER; f1 DATE; f2 DATE; f3 DATE; m VARCHAR2(20) := f_metodo(FALSE);
  BEGIN
    IF r < 0.55 THEN
      f1 := LEAST(p_fres + TRUNC(DBMS_RANDOM.VALUE(0, 3)), p_cin);
      IF DBMS_RANDOM.VALUE < 0.05 THEN p_pago(p_res, p_fres, p_tot, f_metodo(FALSE), 'FALLIDO'); END IF;
      p_pago(p_res, f1, p_tot, m, 'EXITOSO');
    ELSIF r < 0.90 THEN
      x1 := ROUND(p_tot * DBMS_RANDOM.VALUE(0.30, 0.50), -3);
      f2 := GREATEST(p_fres, p_cin - TRUNC(DBMS_RANDOM.VALUE(0, 3)));
      p_pago(p_res, p_fres, x1, m, 'EXITOSO');
      p_pago(p_res, f2, p_tot - x1, f_metodo(TRUE), 'EXITOSO');
    ELSE
      x1 := ROUND(p_tot * 0.30, -3);
      x2 := ROUND(p_tot * 0.30, -3);
      f2 := p_fres + TRUNC((p_cin - p_fres) / 2);
      f3 := GREATEST(f2, p_cin - TRUNC(DBMS_RANDOM.VALUE(0, 3)));
      p_pago(p_res, p_fres, x1, m, 'EXITOSO');
      p_pago(p_res, f2, x2, f_metodo(FALSE), 'EXITOSO');
      p_pago(p_res, f3, p_tot - x1 - x2, f_metodo(TRUE), 'EXITOSO');
    END IF;
  END;

BEGIN
  DBMS_RANDOM.SEED('&semilla' || '-reservas');

  ------------------------------------------------------------ carga de catalogos en memoria
  FOR r IN (SELECT a.id_alojamiento, a.fecha_registro, a.calificacion_estrellas AS est, m.nombre AS muni
              FROM alojamiento a JOIN municipio m ON m.id_municipio = a.id_municipio
             ORDER BY a.id_alojamiento) LOOP
    v_na := v_na + 1;
    a_id(v_na) := r.id_alojamiento; a_reg(v_na) := r.fecha_registro; a_est(v_na) := r.est; a_muni(v_na) := r.muni;
    ord_aloj(r.id_alojamiento) := v_na;
  END LOOP;

  FOR r IN (SELECT id_habitacion, id_alojamiento FROM habitacion ORDER BY id_alojamiento, id_habitacion) LOOP
    v_nh := v_nh + 1;
    h_id(v_nh) := r.id_habitacion; h_ord(r.id_habitacion) := v_nh;
    v_o := ord_aloj(r.id_alojamiento);
    IF NOT a_first.EXISTS(v_o) THEN a_first(v_o) := v_nh; a_n(v_o) := 0; END IF;
    a_n(v_o) := a_n(v_o) + 1;
  END LOOP;

  FOR r IN (SELECT id_servicio, id_alojamiento, nombre, precio FROM servicio ORDER BY id_alojamiento, id_servicio) LOOP
    v_ns := v_ns + 1;
    s_id(v_ns) := r.id_servicio; s_prec(v_ns) := r.precio; s_nom(v_ns) := r.nombre;
    v_o := ord_aloj(r.id_alojamiento);
    IF NOT a_sfirst.EXISTS(v_o) THEN a_sfirst(v_o) := v_ns; a_sn(v_o) := 0; END IF;
    a_sn(v_o) := a_sn(v_o) + 1;
  END LOOP;

  FOR r IN (SELECT id_cliente FROM cliente ORDER BY id_cliente) LOOP
    v_ncli := v_ncli + 1; c_id(v_ncli) := r.id_cliente;
  END LOOP;

  -- calendario: a cada dia le corresponde una temporada
  FOR r IN (SELECT id_temporada, tipo_temporada, fecha_inicio, fecha_fin FROM temporada ORDER BY fecha_inicio) LOOP
    v_nt := v_nt + 1;
    t_ord(r.id_temporada) := v_nt; t_tipo(v_nt) := r.tipo_temporada;
    v_len := r.fecha_fin - r.fecha_inicio;
    v_d1  := r.fecha_inicio - c_inicio;
    FOR x IN 0 .. v_len LOOP
      d_ord(v_d1 + x) := v_nt;
    END LOOP;
  END LOOP;

  -- tarifas: (habitacion, temporada) -> precio por noche
  FOR r IN (SELECT id_habitacion, id_temporada, precio_noche FROM tarifa) LOOP
    tar(h_ord(r.id_habitacion) * 100 + t_ord(r.id_temporada)) := r.precio_noche;
  END LOOP;

  -- peso de cada dia como fecha de check-in
  FOR d IN 0 .. c_ndias - 1 LOOP
    v_f := c_inicio + d;
    v_w := CASE t_tipo(d_ord(d)) WHEN 'ALTA' THEN 3.2 WHEN 'MEDIA' THEN 1.5 ELSE 0.9 END;
    -- MOD(dias desde 1900-01-01, 7): 0 lunes ... 4 viernes, 5 sabado, 6 domingo (1900-01-01 fue lunes)
    v_w := v_w * CASE MOD(v_f - DATE '1900-01-01', 7) WHEN 4 THEN 1.9 WHEN 5 THEN 1.6 WHEN 3 THEN 1.2 WHEN 6 THEN 0.6 ELSE 0.9 END;
    v_w := v_w * CASE EXTRACT(YEAR FROM v_f) WHEN 2024 THEN 0.75 WHEN 2025 THEN 1.0 ELSE 1.1 END;
    IF v_f > c_hoy THEN
      v_k := v_f - c_hoy;
      v_w := v_w * CASE WHEN v_k <= 30 THEN 0.6 WHEN v_k <= 90 THEN 0.35 ELSE 0.12 END;
    END IF;
    d_w(d) := v_w;
    IF v_w > v_wmax THEN v_wmax := v_w; END IF;
  END LOOP;

  -- popularidad y calidad real de cada alojamiento (la calidad percibida NO es igual a las estrellas)
  FOR i IN 1 .. v_na LOOP
    a_pop(i) := POWER(a_n(i), 0.7)
              * CASE a_muni(i) WHEN 'Salento' THEN 1.5 WHEN 'Filandia' THEN 1.3 WHEN 'Armenia' THEN 1.2
                               WHEN 'Quimbaya' THEN 1.1 WHEN 'Montenegro' THEN 1.1 WHEN 'Circasia' THEN 1.0
                               WHEN 'Calarca' THEN 0.9 WHEN 'La Tebaida' THEN 0.9 WHEN 'Pijao' THEN 0.8
                               WHEN 'Buenavista' THEN 0.7 ELSE 0.5 END
              * DBMS_RANDOM.VALUE(0.5, 1.6);
    a_q(i)   := LEAST(4.9, GREATEST(2.6, 3.2 + 0.2 * a_est(i) + DBMS_RANDOM.NORMAL * 0.45));
    v_totpop := v_totpop + a_pop(i);
  END LOOP;

  ------------------------------------------------------------ generacion de reservas
  WHILE v_n < c_objetivo LOOP
    v_it := v_it + 1;
    IF v_it > 400000 THEN
      RAISE_APPLICATION_ERROR(-20010, 'Demasiados intentos: revise los parametros de demanda.');
    END IF;

    -- (1) fecha de check-in por rechazo ponderado
    LOOP
      v_d := TRUNC(DBMS_RANDOM.VALUE(0, c_ndias));
      EXIT WHEN DBMS_RANDOM.VALUE * v_wmax <= d_w(v_d);
    END LOOP;
    v_cin := c_inicio + v_d;
    v_noc := f_noches;
    IF t_tipo(d_ord(v_d)) = 'ALTA' AND DBMS_RANDOM.VALUE < 0.30 THEN v_noc := v_noc + 1; END IF;
    v_cout := v_cin + v_noc;
    CONTINUE WHEN v_cout > c_fin;

    -- (2) estado segun la fecha de corte
    IF v_cout <= c_hoy THEN
      v_est := CASE WHEN DBMS_RANDOM.VALUE < 0.87 THEN 'COMPLETADA' ELSE 'CANCELADA' END;
    ELSIF v_cin <= c_hoy THEN
      v_est := 'CONFIRMADA';                                  -- huesped actualmente hospedado
    ELSE
      v_r := DBMS_RANDOM.VALUE;
      v_est := CASE WHEN v_r < 0.66 THEN 'CONFIRMADA' WHEN v_r < 0.86 THEN 'PENDIENTE' ELSE 'CANCELADA' END;
    END IF;

    -- (3) fecha en que se hizo la reserva
    v_fres := v_cin - f_anticipacion;
    IF v_fres < c_inicio THEN
      v_fres := c_inicio + TRUNC(DBMS_RANDOM.VALUE(0, (v_cin - c_inicio) + 1));
    END IF;
    IF v_cin > c_hoy THEN
      v_fres := LEAST(v_fres, c_hoy - TRUNC(DBMS_RANDOM.VALUE(0, 15)));
    END IF;

    -- (4) alojamiento por sorteo ponderado (debe estar registrado a esa fecha)
    v_r := DBMS_RANDOM.VALUE * v_totpop; v_acc := 0; v_a := v_na;
    FOR i IN 1 .. v_na LOOP
      v_acc := v_acc + a_pop(i);
      IF v_r <= v_acc THEN v_a := i; EXIT; END IF;
    END LOOP;
    CONTINUE WHEN v_fres < a_reg(v_a);

    -- (5) habitaciones libres (las reservas canceladas no ocupan)
    v_k_hab := LEAST(f_habs, a_n(v_a));
    v_off := TRUNC(DBMS_RANDOM.VALUE(0, a_n(v_a)));
    v_nl := 0;
    FOR j IN 0 .. a_n(v_a) - 1 LOOP
      v_ho := a_first(v_a) + MOD(v_off + j, a_n(v_a));
      v_libre := TRUE;
      IF v_est <> 'CANCELADA' THEN
        FOR x IN 0 .. v_noc - 1 LOOP
          IF occ.EXISTS(v_ho * 2000 + v_d + x) THEN v_libre := FALSE; EXIT; END IF;
        END LOOP;
      END IF;
      IF v_libre THEN
        v_nl := v_nl + 1; l_ho(v_nl) := v_ho;
        EXIT WHEN v_nl = v_k_hab;
      END IF;
    END LOOP;
    CONTINUE WHEN v_nl = 0;

    -- (6) cabecera de la reserva (cliente con distribucion sesgada: pocos clientes muy frecuentes)
    v_cli := c_id(1 + TRUNC(v_ncli * POWER(DBMS_RANDOM.VALUE, 1.5)));
    INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, estado, fecha_reserva)
    VALUES (v_cli, v_cin, v_cout, v_est, v_fres)
    RETURNING id_reserva INTO v_idr;

    -- (7) lineas de habitacion; en las lineas 2..n alguien puede llegar un dia despues o irse un dia antes
    v_tot_hab := 0;
    FOR j IN 1 .. v_nl LOOP
      v_lcin := v_cin; v_lcout := v_cout;
      IF j > 1 THEN
        IF v_noc >= 2 AND DBMS_RANDOM.VALUE < 0.12 THEN v_lcin := v_cin + 1; END IF;
        IF (v_lcout - v_lcin) >= 2 AND DBMS_RANDOM.VALUE < 0.10 THEN v_lcout := v_cout - 1; END IF;
      END IF;
      v_d1 := v_lcin - c_inicio;
      v_d2 := v_lcout - c_inicio - 1;
      v_val := 0;
      FOR dd IN v_d1 .. v_d2 LOOP
        v_val := v_val + tar(l_ho(j) * 100 + d_ord(dd));      -- tarifa vigente esa noche
        IF v_est <> 'CANCELADA' THEN occ(l_ho(j) * 2000 + dd) := TRUE; END IF;
      END LOOP;
      INSERT INTO reserva_habitacion (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, valor_linea)
      VALUES (v_idr, h_id(l_ho(j)), v_lcin, v_lcout, v_val);
      v_tot_hab := v_tot_hab + v_val;
      v_nlin := v_nlin + 1;
    END LOOP;

    -- (8) servicios del mismo alojamiento; precio_unitario congelado al valor de la epoca
    v_tot_srv := 0;
    IF v_est <> 'CANCELADA' AND DBMS_RANDOM.VALUE < CASE v_est WHEN 'PENDIENTE' THEN 0.40 ELSE 0.82 END THEN
      v_m := LEAST(f_nserv, a_sn(v_a));
      v_soff := TRUNC(DBMS_RANDOM.VALUE(0, a_sn(v_a)));
      FOR j IN 0 .. v_m - 1 LOOP
        v_so := a_sfirst(v_a) + MOD(v_soff + j, a_sn(v_a));
        IF s_nom(v_so) LIKE 'Desayuno%' OR s_nom(v_so) LIKE 'Almuerzo%' THEN
          v_cant := 2 + TRUNC(DBMS_RANDOM.VALUE(0, 8));
        ELSE
          v_cant := 1 + TRUNC(DBMS_RANDOM.VALUE(0, 4));
        END IF;
        v_pu := ROUND(s_prec(v_so) * CASE EXTRACT(YEAR FROM v_cin) WHEN 2024 THEN 0.90 WHEN 2025 THEN 0.95 ELSE 1 END, -2);
        INSERT INTO reserva_servicio (id_reserva, id_servicio, cantidad, precio_unitario)
        VALUES (v_idr, s_id(v_so), v_cant, v_pu);
        v_tot_srv := v_tot_srv + v_cant * v_pu;
        v_nsrv := v_nsrv + 1;
      END LOOP;
    END IF;
    v_total := v_tot_hab + v_tot_srv;

    -- (9) pagos coherentes con el estado
    IF v_est = 'COMPLETADA' OR (v_est = 'CONFIRMADA' AND v_cin <= c_hoy) THEN
      p_plan_completo(v_idr, v_total, v_fres, v_cin);
    ELSIF v_est = 'CONFIRMADA' THEN                            -- futura: pago total o anticipo + saldo pendiente
      IF DBMS_RANDOM.VALUE < 0.35 THEN
        p_pago(v_idr, v_fres, v_total, f_metodo(FALSE), 'EXITOSO');
      ELSE
        v_a1 := ROUND(v_total * DBMS_RANDOM.VALUE(0.30, 0.50), -3);
        p_pago(v_idr, v_fres, v_a1, f_metodo(FALSE), 'EXITOSO');
        p_pago(v_idr, v_cin - 1, v_total - v_a1, f_metodo(TRUE), 'PENDIENTE');
      END IF;
    ELSIF v_est = 'PENDIENTE' THEN                             -- 55 % sin pago, 30 % pago en verificacion, 15 % fallido
      v_r := DBMS_RANDOM.VALUE;
      IF v_r >= 0.55 THEN
        v_a1 := ROUND(v_total * DBMS_RANDOM.VALUE(0.30, 0.50), -3);
        p_pago(v_idr, v_fres, v_a1, f_metodo(FALSE), CASE WHEN v_r < 0.85 THEN 'PENDIENTE' ELSE 'FALLIDO' END);
      END IF;
    ELSE                                                       -- CANCELADA
      IF DBMS_RANDOM.VALUE >= 0.30 THEN                        -- 70 % habia pagado algo
        IF DBMS_RANDOM.VALUE < 0.70 THEN
          v_paid := ROUND(v_total * DBMS_RANDOM.VALUE(0.30, 0.50), -3);   -- solo anticipo
        ELSE
          v_paid := v_total;                                              -- pago total
        END IF;
        v_met := f_metodo(FALSE);
        p_pago(v_idr, v_fres, v_paid, v_met, 'EXITOSO');
        -- la fecha de cancelacion se deduce de la fecha del reembolso (no hay columna propia)
        v_r := DBMS_RANDOM.VALUE;
        v_dias := CASE WHEN v_r < 0.25 THEN TRUNC(DBMS_RANDOM.VALUE(0, 4))
                       WHEN v_r < 0.45 THEN 4 + TRUNC(DBMS_RANDOM.VALUE(0, 7))
                       ELSE 11 + TRUNC(DBMS_RANDOM.VALUE(0, 30)) END;
        v_fcan := LEAST(GREATEST(v_fres, v_cin - v_dias), c_hoy);
        -- regla de reembolso: MAS de 5 dias de anticipacion -> 80 %; 5 dias o menos -> nada
        IF (v_cin - v_fcan) > 5 THEN
          p_pago(v_idr, LEAST(v_fcan + TRUNC(DBMS_RANDOM.VALUE(0, 3)), c_hoy), ROUND(v_paid * 0.8, 2), v_met, 'REEMBOLSADO');
        END IF;
      END IF;
    END IF;

    -- (10) resena: ~50 % de las reservas completadas; la nota depende de la calidad real del alojamiento
    IF v_est = 'COMPLETADA' AND DBMS_RANDOM.VALUE < 0.50 THEN
      v_cal := GREATEST(1, LEAST(5, ROUND(a_q(v_a) + DBMS_RANDOM.NORMAL * 0.9)));
      v_fres2 := LEAST(v_cout + TRUNC(DBMS_RANDOM.VALUE(0, 22)), c_hoy);
      IF DBMS_RANDOM.VALUE < 0.65 THEN v_com := f_comentario(v_cal); ELSE v_com := NULL; END IF;   -- comentario opcional
      INSERT INTO resena (id_cliente, id_alojamiento, id_reserva, calificacion, comentario, fecha_resena)
      VALUES (v_cli, a_id(v_a), v_idr, v_cal, v_com, v_fres2);
      v_nrev := v_nrev + 1;
    END IF;

    v_n := v_n + 1;
    IF MOD(v_n, 2500) = 0 THEN COMMIT; END IF;
  END LOOP;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('RESERVA             : ' || v_n || ' (intentos: ' || v_it || ')');
  DBMS_OUTPUT.PUT_LINE('RESERVA_HABITACION  : ' || v_nlin);
  DBMS_OUTPUT.PUT_LINE('RESERVA_SERVICIO    : ' || v_nsrv);
  DBMS_OUTPUT.PUT_LINE('PAGO                : ' || v_npag);
  DBMS_OUTPUT.PUT_LINE('RESENA              : ' || v_nrev);
END;
/

-- =====================================================================================
-- 5. AJUSTES FINALES Y VERIFICACION
-- =====================================================================================
-- 5.1 Un cliente no puede haberse registrado despues de su primera reserva: se lleva
--     fecha_registro a la fecha de su primera reserva (los que nunca reservaron conservan la suya).
MERGE INTO cliente c
USING (SELECT id_cliente, MIN(fecha_reserva) AS primera FROM reserva GROUP BY id_cliente) r
   ON (c.id_cliente = r.id_cliente)
 WHEN MATCHED THEN UPDATE SET c.fecha_registro = r.primera;
COMMIT;

-- 5.2 Estadisticas para que el optimizador (y los planes de la Entrega 3) vean el volumen real.
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/

-- 5.3 Conteo por tabla contra el minimo exigido en la seccion 3 del enunciado.
SELECT 'MUNICIPIO' AS tabla, COUNT(*) AS filas, 12 AS minimo FROM municipio UNION ALL
SELECT 'TIPO_ALOJAMIENTO', COUNT(*), 4 FROM tipo_alojamiento UNION ALL
SELECT 'ALOJAMIENTO', COUNT(*), 60 FROM alojamiento UNION ALL
SELECT 'HABITACION', COUNT(*), 400 FROM habitacion UNION ALL
SELECT 'TEMPORADA', COUNT(*), 6 FROM temporada UNION ALL
SELECT 'TARIFA (habitacion x temporada)', COUNT(*), (SELECT COUNT(*) FROM habitacion) * (SELECT COUNT(*) FROM temporada) FROM tarifa UNION ALL
SELECT 'CLIENTE', COUNT(*), 3000 FROM cliente UNION ALL
SELECT 'RESERVA', COUNT(*), 25000 FROM reserva UNION ALL
SELECT 'RESERVA_HABITACION', COUNT(*), 25000 FROM reserva_habitacion UNION ALL
SELECT 'PAGO', COUNT(*), 25000 FROM pago UNION ALL
SELECT 'SERVICIO', COUNT(*), 30 FROM servicio UNION ALL
SELECT 'RESERVA_SERVICIO', COUNT(*), 40000 FROM reserva_servicio UNION ALL
SELECT 'RESENA', COUNT(*), CEIL(0.4 * (SELECT COUNT(*) FROM reserva WHERE estado = 'COMPLETADA')) FROM resena UNION ALL
SELECT 'USUARIO_SISTEMA', COUNT(*), 10 FROM usuario_sistema;

-- 5.4 Evidencia de asimetria: reservas y alojamientos por municipio (deben ser muy distintos).
SELECT m.nombre AS municipio, COUNT(DISTINCT a.id_alojamiento) AS alojamientos, COUNT(DISTINCT h.id_habitacion) AS habitaciones
  FROM municipio m JOIN alojamiento a ON a.id_municipio = m.id_municipio
                   JOIN habitacion h ON h.id_alojamiento = a.id_alojamiento
 GROUP BY m.nombre ORDER BY habitaciones DESC;

SELECT TO_CHAR(fecha_checkin, 'YYYY-MM') AS mes, COUNT(*) AS reservas
  FROM reserva GROUP BY TO_CHAR(fecha_checkin, 'YYYY-MM') ORDER BY 1;

-- 5.5 Controles de integridad de negocio (todos deben devolver 0).
-- (a) solapes: misma habitacion, dos reservas no canceladas con noches en comun
SELECT COUNT(*) AS solapes
  FROM reserva_habitacion a
  JOIN reserva ra ON ra.id_reserva = a.id_reserva AND ra.estado <> 'CANCELADA'
  JOIN reserva_habitacion b ON b.id_habitacion = a.id_habitacion AND b.id_reserva_habitacion > a.id_reserva_habitacion
       AND a.fecha_checkin < b.fecha_checkout AND b.fecha_checkin < a.fecha_checkout
  JOIN reserva rb ON rb.id_reserva = b.id_reserva AND rb.estado <> 'CANCELADA';

-- (b) lineas cuyas fechas se salen del rango general de su reserva
SELECT COUNT(*) AS lineas_fuera_de_rango
  FROM reserva_habitacion rh JOIN reserva r ON r.id_reserva = rh.id_reserva
 WHERE rh.fecha_checkin < r.fecha_checkin OR rh.fecha_checkout > r.fecha_checkout;

-- (c) reservas con habitaciones de mas de un alojamiento
SELECT COUNT(*) AS reservas_multi_alojamiento
  FROM (SELECT rh.id_reserva FROM reserva_habitacion rh JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
         GROUP BY rh.id_reserva HAVING COUNT(DISTINCT h.id_alojamiento) > 1);

-- (d) reservas COMPLETADAS que no quedaron pagadas (suma EXITOSO < estadia + servicios)
WITH p AS (SELECT id_reserva, SUM(monto) AS s FROM pago WHERE estado_pago = 'EXITOSO' GROUP BY id_reserva),
     h AS (SELECT id_reserva, SUM(valor_linea) AS s FROM reserva_habitacion GROUP BY id_reserva),
     v AS (SELECT id_reserva, SUM(cantidad * precio_unitario) AS s FROM reserva_servicio GROUP BY id_reserva)
SELECT COUNT(*) AS completadas_sin_pagar
  FROM reserva r LEFT JOIN p ON p.id_reserva = r.id_reserva LEFT JOIN h ON h.id_reserva = r.id_reserva LEFT JOIN v ON v.id_reserva = r.id_reserva
 WHERE r.estado = 'COMPLETADA' AND NVL(p.s, 0) < NVL(h.s, 0) + NVL(v.s, 0);

-- (e) resenas cuya reserva no esta COMPLETADA, de otro cliente, o de un alojamiento distinto al de la reserva
SELECT (SELECT COUNT(*) FROM resena rs JOIN reserva r ON r.id_reserva = rs.id_reserva
         WHERE r.estado <> 'COMPLETADA' OR r.id_cliente <> rs.id_cliente)
     + (SELECT COUNT(*) FROM resena rs
         WHERE NOT EXISTS (SELECT 1 FROM reserva_habitacion rh JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
                            WHERE rh.id_reserva = rs.id_reserva AND h.id_alojamiento = rs.id_alojamiento)) AS resenas_invalidas
  FROM dual;

-- (f) lineas de habitacion sin valor calculado
SELECT COUNT(*) AS lineas_sin_valor FROM reserva_habitacion WHERE valor_linea IS NULL OR valor_linea <= 0;

-- (g) las temporadas de un mismo anio no se traslapan ni dejan dias sin cubrir (esperado: 0 filas)
SELECT anio, nombre AS temporada, fecha_fin, siguiente, inicio_siguiente
  FROM (SELECT anio, nombre, fecha_fin,
               LEAD(nombre)       OVER (PARTITION BY anio ORDER BY fecha_inicio) AS siguiente,
               LEAD(fecha_inicio) OVER (PARTITION BY anio ORDER BY fecha_inicio) AS inicio_siguiente
          FROM temporada)
 WHERE inicio_siguiente IS NOT NULL AND inicio_siguiente <> fecha_fin + 1;

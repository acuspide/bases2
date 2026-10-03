/* ============================================================================
   TurismoUQ - Plataforma de reservas turisticas del Quindio
   Script DDL - Modelo relacional para Oracle XE 21c
   Universidad del Quindio - Bases de Datos II - codigo 12338 - periodo 2026-2
   Entrega 1 - Modelo de datos
   ============================================================================
   Crea las 14 tablas del modelo minimo exigido, con PK, FK, CHECK, NOT NULL
   y UNIQUE donde corresponde. Pensado para correr de arriba a abajo en un
   esquema limpio de Oracle XE 21c.

   Decisiones de diseno que se resuelven en este script:

   1) Una reserva puede tomar varias habitaciones (seccion 1.3 del enunciado):
      se modela con la tabla puente RESERVA_HABITACION, que ademas guarda
      fecha_checkin/fecha_checkout PROPIAS de cada linea, porque el enunciado
      aclara que cada habitacion del grupo puede tener fechas ligeramente
      distintas dentro del rango general de la reserva.

   2) Una estadia puede cruzar dos temporadas con tarifas distintas
      (seccion 1.2): se modela con TARIFA como el cruce HABITACION x
      TEMPORADA (una fila por cada combinacion vigente, con precio propio,
      no un porcentaje sobre un precio base). El calculo noche por noche
      para una estadia que atraviesa temporadas lo resuelve la funcion
      fn_valor_estadia en la Entrega 2, recorriendo TARIFA dia a dia; por
      eso RESERVA_HABITACION.valor_linea queda nulo hasta que esa funcion
      exista y se ejecute.
   ============================================================================ */

-- ============================================================================
-- (Opcional) Bloque de limpieza para reejecutar el script sobre el mismo
-- esquema. En una base limpia NO es necesario y debe permanecer comentado.
-- ============================================================================
/*
BEGIN
   FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
      'RESENA','RESERVA_SERVICIO','SERVICIO','PAGO','RESERVA_HABITACION',
      'RESERVA','CLIENTE','TARIFA','TEMPORADA','HABITACION',
      'USUARIO_SISTEMA','ALOJAMIENTO','TIPO_ALOJAMIENTO','MUNICIPIO'))
   LOOP
      EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS';
   END LOOP;
END;
/
*/

-- ============================================================================
-- 1. MUNICIPIO
-- ============================================================================
CREATE TABLE municipio (
    id_municipio     NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    nombre           VARCHAR2(100)   NOT NULL,
    CONSTRAINT pk_municipio PRIMARY KEY (id_municipio),
    CONSTRAINT uq_municipio_nombre UNIQUE (nombre)
);

COMMENT ON TABLE municipio IS 'Los 12 municipios del Quindio donde puede ubicarse un alojamiento.';
COMMENT ON COLUMN municipio.nombre IS 'Nombre del municipio, unico (ej. Armenia, Salento, Calarca).';

-- ============================================================================
-- 2. TIPO_ALOJAMIENTO
-- ============================================================================
CREATE TABLE tipo_alojamiento (
    id_tipo_alojamiento  NUMBER        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    nombre               VARCHAR2(50)  NOT NULL,
    CONSTRAINT pk_tipo_alojamiento PRIMARY KEY (id_tipo_alojamiento),
    CONSTRAINT uq_tipo_alojamiento_nombre UNIQUE (nombre)
);

COMMENT ON TABLE tipo_alojamiento IS 'Catalogo de tipos de alojamiento: finca cafetera, hotel, glamping, hostal, u otros que el grupo sustente.';

-- ============================================================================
-- 3. ALOJAMIENTO
-- ============================================================================
CREATE TABLE alojamiento (
    id_alojamiento          NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_municipio            NUMBER          NOT NULL,
    id_tipo_alojamiento     NUMBER          NOT NULL,
    nombre_comercial        VARCHAR2(150)   NOT NULL,
    direccion               VARCHAR2(200)   NOT NULL,
    calificacion_estrellas  NUMBER(1)       DEFAULT 0 NOT NULL,
    telefono_contacto       VARCHAR2(20),
    correo_contacto         VARCHAR2(100),
    fecha_registro          DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_alojamiento PRIMARY KEY (id_alojamiento),
    CONSTRAINT fk_alojamiento_municipio FOREIGN KEY (id_municipio)
        REFERENCES municipio (id_municipio),
    CONSTRAINT fk_alojamiento_tipo FOREIGN KEY (id_tipo_alojamiento)
        REFERENCES tipo_alojamiento (id_tipo_alojamiento),
    CONSTRAINT ck_alojamiento_estrellas CHECK (calificacion_estrellas BETWEEN 0 AND 5)
);

COMMENT ON TABLE alojamiento IS 'Fincas cafeteras, hoteles, glampings y hostales que ofrecen habitaciones en un municipio del Quindio.';
COMMENT ON COLUMN alojamiento.calificacion_estrellas IS 'Calificacion en estrellas que el propio alojamiento se autoasigna (0-5), no una calificacion calculada de resenas.';

-- ============================================================================
-- 4. HABITACION
-- ============================================================================
CREATE TABLE habitacion (
    id_habitacion     NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_alojamiento    NUMBER          NOT NULL,
    numero            VARCHAR2(10)    NOT NULL,
    capacidad_maxima  NUMBER(3)       NOT NULL,
    tipo_habitacion   VARCHAR2(20)    NOT NULL,
    descripcion       VARCHAR2(500),
    CONSTRAINT pk_habitacion PRIMARY KEY (id_habitacion),
    CONSTRAINT fk_habitacion_alojamiento FOREIGN KEY (id_alojamiento)
        REFERENCES alojamiento (id_alojamiento),
    CONSTRAINT uq_habitacion_numero UNIQUE (id_alojamiento, numero),
    CONSTRAINT ck_habitacion_capacidad CHECK (capacidad_maxima > 0),
    CONSTRAINT ck_habitacion_tipo CHECK (tipo_habitacion IN ('SENCILLA','DOBLE','SUITE','CABANA'))
);

COMMENT ON TABLE habitacion IS 'Habitaciones ofrecidas por cada alojamiento. El numero es unico dentro de un mismo alojamiento (uq_habitacion_numero), no de forma global: dos alojamientos distintos si pueden tener ambos una habitacion "101".';

-- ============================================================================
-- 5. TEMPORADA
-- ============================================================================
CREATE TABLE temporada (
    id_temporada   NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    nombre         VARCHAR2(50)    NOT NULL,
    tipo_temporada VARCHAR2(10)    NOT NULL,
    anio           NUMBER(4)       NOT NULL,
    fecha_inicio   DATE            NOT NULL,
    fecha_fin      DATE            NOT NULL,
    CONSTRAINT pk_temporada PRIMARY KEY (id_temporada),
    CONSTRAINT uq_temporada_nombre_anio UNIQUE (nombre, anio),
    CONSTRAINT ck_temporada_tipo CHECK (tipo_temporada IN ('ALTA','MEDIA','BAJA')),
    CONSTRAINT ck_temporada_fechas CHECK (fecha_fin >= fecha_inicio)
);

COMMENT ON TABLE temporada IS 'Temporadas (alta, media, baja) definidas por anio, con su rango de fechas. Semana Santa 2025 y Semana Santa 2026 son filas distintas, con fechas distintas.';

-- ============================================================================
-- 6. TARIFA  (resuelve la decision de diseno #2: cruce de temporadas)
-- ============================================================================
CREATE TABLE tarifa (
    id_tarifa      NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_habitacion  NUMBER          NOT NULL,
    id_temporada   NUMBER          NOT NULL,
    precio_noche   NUMBER(10,2)    NOT NULL,
    CONSTRAINT pk_tarifa PRIMARY KEY (id_tarifa),
    CONSTRAINT fk_tarifa_habitacion FOREIGN KEY (id_habitacion)
        REFERENCES habitacion (id_habitacion),
    CONSTRAINT fk_tarifa_temporada FOREIGN KEY (id_temporada)
        REFERENCES temporada (id_temporada),
    CONSTRAINT uq_tarifa_habitacion_temporada UNIQUE (id_habitacion, id_temporada),
    CONSTRAINT ck_tarifa_precio CHECK (precio_noche > 0)
);

COMMENT ON TABLE tarifa IS 'Precio por noche de cada habitacion en cada temporada: una fila por cada combinacion habitacion x temporada vigente, no un porcentaje fijo sobre un precio base. fn_valor_estadia (Entrega 2) recorre esta tabla noche por noche para calcular estadias que cruzan de una temporada a otra.';

-- ============================================================================
-- 7. CLIENTE
-- ============================================================================
CREATE TABLE cliente (
    id_cliente           NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    nombre               VARCHAR2(150)   NOT NULL,
    documento_identidad  VARCHAR2(20)    NOT NULL,
    correo               VARCHAR2(100)   NOT NULL,
    telefono             VARCHAR2(20),
    ciudad_origen        VARCHAR2(100),
    fecha_registro       DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_documento UNIQUE (documento_identidad),
    CONSTRAINT uq_cliente_correo UNIQUE (correo)
);

COMMENT ON TABLE cliente IS 'Clientes registrados en la plataforma. Un cliente puede tener muchas reservas a lo largo del tiempo.';

-- ============================================================================
-- 8. RESERVA
-- ============================================================================
CREATE TABLE reserva (
    id_reserva        NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_cliente        NUMBER          NOT NULL,
    fecha_checkin     DATE            NOT NULL,
    fecha_checkout    DATE            NOT NULL,
    estado            VARCHAR2(15)    DEFAULT 'PENDIENTE' NOT NULL,
    fecha_reserva     DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_reserva PRIMARY KEY (id_reserva),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente),
    CONSTRAINT ck_reserva_estado CHECK (estado IN ('PENDIENTE','CONFIRMADA','CANCELADA','COMPLETADA')),
    CONSTRAINT ck_reserva_fechas CHECK (fecha_checkout > fecha_checkin)
);

COMMENT ON TABLE reserva IS 'Reserva hecha por un cliente. fecha_checkin/fecha_checkout representan el rango general del grupo; el detalle real por habitacion (que puede variar un poco) vive en RESERVA_HABITACION.';

-- ============================================================================
-- 9. RESERVA_HABITACION  (resuelve la decision de diseno #1: multi-habitacion)
-- ============================================================================
CREATE TABLE reserva_habitacion (
    id_reserva_habitacion  NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_reserva             NUMBER          NOT NULL,
    id_habitacion          NUMBER          NOT NULL,
    fecha_checkin          DATE            NOT NULL,
    fecha_checkout         DATE            NOT NULL,
    valor_linea            NUMBER(10,2),
    CONSTRAINT pk_reserva_habitacion PRIMARY KEY (id_reserva_habitacion),
    CONSTRAINT fk_res_hab_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva),
    CONSTRAINT fk_res_hab_habitacion FOREIGN KEY (id_habitacion)
        REFERENCES habitacion (id_habitacion),
    CONSTRAINT ck_res_hab_fechas CHECK (fecha_checkout > fecha_checkin)
);

COMMENT ON TABLE reserva_habitacion IS 'Tabla puente que permite que una reserva incluya varias habitaciones del mismo alojamiento, cada una con sus propias fechas dentro del rango general de la reserva (seccion 1.3 del enunciado). La regla de no solape con otra reserva CONFIRMADA para la misma habitacion se valida con un trigger de fila en la Entrega 2, porque requiere comparar contra otras filas de esta misma tabla.';
COMMENT ON COLUMN reserva_habitacion.valor_linea IS 'Valor de la estadia de esta linea, calculado noche por noche segun TARIFA. Queda nulo hasta que se ejecute fn_valor_estadia (Entrega 2).';

-- ============================================================================
-- 10. PAGO
-- ============================================================================
CREATE TABLE pago (
    id_pago       NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_reserva    NUMBER          NOT NULL,
    fecha_pago    DATE            DEFAULT SYSDATE NOT NULL,
    monto         NUMBER(10,2)    NOT NULL,
    metodo_pago   VARCHAR2(20)    NOT NULL,
    estado_pago   VARCHAR2(15)    DEFAULT 'PENDIENTE' NOT NULL,
    CONSTRAINT pk_pago PRIMARY KEY (id_pago),
    CONSTRAINT fk_pago_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva),
    CONSTRAINT ck_pago_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_metodo CHECK (metodo_pago IN ('TARJETA_CREDITO','TARJETA_DEBITO','PSE','TRANSFERENCIA','EFECTIVO')),
    CONSTRAINT ck_pago_estado CHECK (estado_pago IN ('EXITOSO','FALLIDO','PENDIENTE','REEMBOLSADO'))
);

COMMENT ON TABLE pago IS 'Pagos o abonos de una reserva (una reserva puede tener varios: anticipo + saldo). Una reserva se considera pagada cuando la suma de sus pagos EXITOSO cubre el valor total de la estadia mas los servicios.';

-- ============================================================================
-- 11. SERVICIO
-- ============================================================================
CREATE TABLE servicio (
    id_servicio     NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_alojamiento  NUMBER          NOT NULL,
    nombre          VARCHAR2(100)   NOT NULL,
    descripcion     VARCHAR2(500),
    precio          NUMBER(10,2)    NOT NULL,
    CONSTRAINT pk_servicio PRIMARY KEY (id_servicio),
    CONSTRAINT fk_servicio_alojamiento FOREIGN KEY (id_alojamiento)
        REFERENCES alojamiento (id_alojamiento),
    CONSTRAINT uq_servicio_alojamiento_nombre UNIQUE (id_alojamiento, nombre),
    CONSTRAINT ck_servicio_precio CHECK (precio >= 0)
);

COMMENT ON TABLE servicio IS 'Servicios complementarios (desayuno, tour, transporte, bicicletas, spa, etc.) que pertenecen a un alojamiento especifico: el desayuno del Hotel X y el del Hotel Y son filas distintas aunque se llamen igual.';

-- ============================================================================
-- 12. RESERVA_SERVICIO
-- ============================================================================
CREATE TABLE reserva_servicio (
    id_reserva_servicio  NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_reserva           NUMBER          NOT NULL,
    id_servicio          NUMBER          NOT NULL,
    cantidad             NUMBER(4)       DEFAULT 1 NOT NULL,
    precio_unitario      NUMBER(10,2)    NOT NULL,
    CONSTRAINT pk_reserva_servicio PRIMARY KEY (id_reserva_servicio),
    CONSTRAINT fk_res_serv_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva),
    CONSTRAINT fk_res_serv_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio),
    CONSTRAINT ck_res_serv_cantidad CHECK (cantidad > 0)
);

COMMENT ON TABLE reserva_servicio IS 'Servicios contratados dentro de una reserva, con cantidad (ej. 2 tours guiados para 2 personas del grupo). precio_unitario guarda el precio vigente al momento de reservar, para que no cambie si SERVICIO.precio cambia despues.';

-- ============================================================================
-- 13. RESENA
-- ============================================================================
CREATE TABLE resena (
    id_resena       NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_cliente      NUMBER          NOT NULL,
    id_alojamiento  NUMBER          NOT NULL,
    id_reserva      NUMBER          NOT NULL,
    calificacion    NUMBER(1)       NOT NULL,
    comentario      VARCHAR2(1000),
    fecha_resena    DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_resena PRIMARY KEY (id_resena),
    CONSTRAINT fk_resena_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente),
    CONSTRAINT fk_resena_alojamiento FOREIGN KEY (id_alojamiento)
        REFERENCES alojamiento (id_alojamiento),
    CONSTRAINT fk_resena_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva),
    CONSTRAINT uq_resena_reserva UNIQUE (id_reserva),
    CONSTRAINT ck_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5)
);

COMMENT ON TABLE resena IS 'Resena de un cliente sobre un alojamiento, ligada a la reserva puntual que la origina. uq_resena_reserva impide mas de una resena por la misma reserva. Que esa reserva este en estado COMPLETADA (regla implicita de la seccion 1.6) se valida con un trigger en la Entrega 2, porque un CHECK de Oracle no puede consultar otra tabla.';

-- ============================================================================
-- 14. USUARIO_SISTEMA
-- ============================================================================
CREATE TABLE usuario_sistema (
    id_usuario      NUMBER          GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    id_alojamiento  NUMBER,
    nombre          VARCHAR2(150)   NOT NULL,
    correo          VARCHAR2(100)   NOT NULL,
    rol             VARCHAR2(20)    NOT NULL,
    fecha_creacion  DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_usuario_sistema PRIMARY KEY (id_usuario),
    CONSTRAINT fk_usuario_alojamiento FOREIGN KEY (id_alojamiento)
        REFERENCES alojamiento (id_alojamiento),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('ADMINISTRADOR','ENCARGADO')),
    CONSTRAINT ck_usuario_rol_alojamiento CHECK (
        (rol = 'ADMINISTRADOR' AND id_alojamiento IS NULL) OR
        (rol = 'ENCARGADO' AND id_alojamiento IS NOT NULL)
    )
);

COMMENT ON TABLE usuario_sistema IS 'Usuarios internos de la plataforma: administradores (rol global, sin alojamiento) y encargados de alojamiento (atados a un id_alojamiento). Base para los roles y privilegios de la Entrega 3.';

COMMIT;

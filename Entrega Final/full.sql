-- Creación de la base de datos.
CREATE DATABASE administracion_consorcios;

-- Selección de la base de datos.
USE administracion_consorcios;

-- Creación de la tabla Administradores.
CREATE TABLE Administradores (
    id_administrador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    CUIT VARCHAR(13) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL
);

-- Creación de la tabla Encargados.
CREATE TABLE Encargados (
    id_encargado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    CUIL VARCHAR(13) NOT NULL,
    salario DECIMAL(10,2) NOT NULL
);

-- Creación de la tabla Consorcios.
CREATE TABLE Consorcios (
    id_consorcio INT AUTO_INCREMENT PRIMARY KEY,
    CUIT VARCHAR(13) NOT NULL,
    direccion VARCHAR(75) NOT NULL,
    unidades_funcionales INT NOT NULL,
    id_administrador INT NOT NULL,
    id_encargado INT NOT NULL,
    FOREIGN KEY (id_administrador) REFERENCES Administradores(id_administrador),
    FOREIGN KEY (id_encargado) REFERENCES Encargados(id_encargado)
);

-- Creación de la tabla Proveedores.
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(75) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL,
    descripcion_servicio VARCHAR(100) NOT NULL
);

-- Creación de la tabla Propietarios con referencia a Hechos_Expensas.
CREATE TABLE Propietarios (
    id_propietario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL,
    departamento VARCHAR(3) NOT NULL,
    id_consorcio INT NOT NULL,
    unidad_funcional INT NOT NULL,
    porcentaje_fiscal DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Tablas de Hechos.
-- Creación de la tabla de hechos de Reclamos.
CREATE TABLE h_Reclamos (
	id_reclamo INT AUTO_INCREMENT PRIMARY KEY,
    id_propietario INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_administrador INT NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    fecha DATE NOT NULL,
    FOREIGN KEY (id_propietario) REFERENCES Propietarios(id_propietario),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio),
	FOREIGN KEY (id_administrador) REFERENCES Administradores(id_administrador)
);

-- Creación tabla de Pagos por Período (asociados a un consorcio en un PERIODO).
CREATE TABLE h_Pagos_Periodo (
	id_pagos_periodo INT AUTO_INCREMENT PRIMARY KEY,
    id_consorcio INT NOT NULL,
	periodo VARCHAR(20) NOT NULL,
    monto_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de la tabla de hechos de Gastos.
CREATE TABLE h_Gastos (
    id_gasto INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_pagos_periodo INT NOT NULL DEFAULT 0,
    costo_total DECIMAL(10,2) NOT NULL,
    fecha DATE NOT NULL,
    concepto VARCHAR(200) NOT NULL,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio),
    FOREIGN KEY (id_pagos_periodo) REFERENCES h_Pagos_Periodo(id_pagos_periodo)
);

-- Creacion de la tabla de Expensas a pagar por cada propietario.
CREATE TABLE h_Expensas (
	id_expensa INT AUTO_INCREMENT PRIMARY KEY,
    id_propietario INT NOT NULL,
    id_pagos_periodo INT NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    pagado BOOL NOT NULL DEFAULT FALSE,
    monto DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_propietario) REFERENCES Propietarios(id_propietario),
    FOREIGN KEY (id_pagos_periodo) REFERENCES h_Pagos_Periodo(id_pagos_periodo)
);

-- Creación de Funciones
DELIMITER //

-- Función para calcular las expensas de un propietario, multiplicando el monto_total por el porcentaje_fiscal brindado y dividirlo por 100.
CREATE FUNCTION funcion_calcular_expensas_propietario(
    monto_total DECIMAL(10,2),
    porcentaje_fiscal DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN (monto_total * porcentaje_fiscal / 100);
END //

-- Función para obtener el período de un pago por período en varchar(20) con formato Mes-XXXX (con XXXX siendo el anio).
CREATE FUNCTION funcion_obtener_periodo_reciente(id_consorcio_pasado INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo_buscado VARCHAR(20);

    SELECT periodo
    INTO periodo_buscado
    FROM h_Pagos_Periodo
    WHERE id_consorcio = id_consorcio_pasado
    ORDER BY STR_TO_DATE(periodo, '%M-%Y') DESC
    LIMIT 1;

    RETURN periodo_buscado;
END //


-- Función para calcular el total de gastos desde una fecha específica de un consorcio (REVISAR POSIBLE USO DE h_Pagos_Periodo).
CREATE FUNCTION funcion_obtener_total_gastos_consorcio_desde_fecha(consorcio_id INT, fecha_inicio DATE) RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Selecciona la suma de los gastos totales para el consorcio especificado desde una fecha específica.
    SELECT SUM(costo_total) INTO total
    FROM h_Gastos
    WHERE id_consorcio = consorcio_id
    AND fecha >= fecha_inicio;
    
    -- Si el total es NULL, establece total a 0.
    IF total IS NULL THEN
        SET total = 0;
    END IF;
    
    -- Retorna el total de gastos desde la fecha específica.
    RETURN total;
END //

-- Función para obtener el período de un pago por período en varchar(20) con formato Mes-XXXX (con XXXX siendo el anio).
CREATE FUNCTION funcion_obtener_periodo(id_pagos_periodo_nuevo INT) 
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo_nuevo VARCHAR(20);
    
    SELECT periodo
    INTO periodo_nuevo
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;

    RETURN periodo_nuevo;
END //

-- Funcion que en base a una fecha devuelve un período. El punto de corte es el 25 de cada mes, a partir del 26 es el próximo mes.
CREATE FUNCTION funcion_obtener_periodo_por_fecha(fecha DATE)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE periodo VARCHAR(20);
    DECLARE mes_actual VARCHAR(20);
    DECLARE anio_actual INT;
    DECLARE mes INT;
    DECLARE anio INT;

    -- Obtener el mes y el año de la fecha proporcionada.
    SET mes = MONTH(fecha);
    SET anio = YEAR(fecha);
    
    SET anio_actual = anio;

    -- Ajustar el mes y el año según la lógica de los períodos.
    IF DAY(fecha) >= 26 THEN
        SET mes = mes + 1;        
        IF mes = 13 THEN
            SET mes = 1;
            SET anio_actual = anio + 1;
        END IF;
    END IF;

    -- Formatear el mes al nombre en español.
    CASE mes
        WHEN 1 THEN SET mes_actual = 'Enero';
        WHEN 2 THEN SET mes_actual = 'Febrero';
        WHEN 3 THEN SET mes_actual = 'Marzo';
        WHEN 4 THEN SET mes_actual = 'Abril';
        WHEN 5 THEN SET mes_actual = 'Mayo';
        WHEN 6 THEN SET mes_actual = 'Junio';
        WHEN 7 THEN SET mes_actual = 'Julio';
        WHEN 8 THEN SET mes_actual = 'Agosto';
        WHEN 9 THEN SET mes_actual = 'Septiembre';
        WHEN 10 THEN SET mes_actual = 'Octubre';
        WHEN 11 THEN SET mes_actual = 'Noviembre';
        WHEN 12 THEN SET mes_actual = 'Diciembre';
    END CASE;

    -- Formatear el resultado en el formato "Mes-año".
    SET periodo = CONCAT(mes_actual, '-', anio_actual);

    RETURN periodo;
END //

-- Función para obtener la fecha de vencimiento en base a un ID de h_pagos_periodo.
CREATE FUNCTION funcion_obtener_fecha_vencimiento_por_id(id_pagos_periodo_nuevo INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_vencimiento_nuevo DATE;
    DECLARE periodo_nuevo VARCHAR(20);
    
	DECLARE mes_nuevo ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');
    DECLARE anio_nuevo YEAR;
    
	SELECT periodo INTO periodo_nuevo
    FROM h_Pagos_periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;
    
	SET mes_nuevo = SUBSTRING_INDEX(periodo_nuevo, '-', 1);
    SET anio_nuevo = CAST(SUBSTRING_INDEX(periodo_nuevo, '-', -1) AS UNSIGNED);

    -- Asignar la fecha de vencimiento basada en el mes y año
    CASE mes_nuevo
        WHEN 'Enero' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-02-10');
        WHEN 'Febrero' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-03-10');
        WHEN 'Marzo' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-04-10');
        WHEN 'Abril' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-05-10');
        WHEN 'Mayo' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-06-10');
        WHEN 'Junio' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-07-10');
        WHEN 'Julio' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-08-10');
        WHEN 'Agosto' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-09-10');
        WHEN 'Septiembre' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-10-10');
        WHEN 'Octubre' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-11-10');
        WHEN 'Noviembre' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo, '-12-10');
        WHEN 'Diciembre' THEN SET fecha_vencimiento_nuevo = CONCAT(anio_nuevo + 1, '-01-10');
    END CASE;

    RETURN fecha_vencimiento_nuevo;
END //

-- Función para obtener la última expensa de un propietario.
CREATE FUNCTION funcion_obtener_ultima_expensa(id_propietario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE ultima_expensa_id INT;
    
    SELECT id_expensa
    INTO ultima_expensa_id
    FROM h_Expensas
    WHERE id_propietario = id_propietario
    ORDER BY id_pagos_periodo DESC
    LIMIT 1;
    
    RETURN ultima_expensa_id;
END //

DELIMITER ;

-- Creación de Vistas
-- Vista que brinda información general de los propietarios de un consorcio.
CREATE VIEW vista_general_propietarios_consorcios AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    c.direccion AS consorcio
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;
    
-- Vista que muestra el histórico de expensas de un propietario de un consorcio para cada período contabilizado.
CREATE VIEW vista_historico_expensas_propietario AS
SELECT 
    p.id_propietario,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
    c.id_consorcio,
    c.direccion AS consorcio,
    funcion_obtener_periodo(e.id_pagos_periodo) AS periodo,
    e.monto,
    e.fecha_vencimiento,
    e.pagado
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    p.id_propietario, c.id_consorcio, e.id_pagos_periodo;

-- Vista para obtener las expensas de todos los propietarios de un consorcio en un período dado.
CREATE VIEW vista_expensas_consorcio_periodo AS
SELECT 
    c.direccion AS consorcio,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
    funcion_obtener_periodo(e.id_pagos_periodo) AS periodo,
    e.monto,
    e.pagado
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    c.id_consorcio, e.id_pagos_periodo;
    
-- Vista para ver el salario de los encargados de cada consorcio.
CREATE VIEW vista_salarios_encargados_consorcio AS
SELECT
    c.id_consorcio,
    c.direccion,
    e.id_encargado,
    e.nombre AS nombre_encargado,
    e.apellido,
    e.salario
FROM
    Consorcios c
JOIN
    Encargados e ON c.id_encargado = e.id_encargado;
    
-- Vista que muestra el histórico de reclamos de un consorcio.
CREATE VIEW vista_historico_reclamos_consorcio AS
SELECT 
    hr.id_reclamo,
    hr.descripcion,
    hr.fecha,
    c.id_consorcio,
    c.direccion AS consorcio,
    a.id_administrador,
    a.nombre AS nombre_administrador
FROM 
    h_Reclamos hr
JOIN 
    Consorcios c ON hr.id_consorcio = c.id_consorcio
JOIN 
    Administradores a ON hr.id_administrador = a.id_administrador
ORDER BY 
    hr.fecha DESC;
    
-- Vista que muestre el historíco de reclamos de los consorcios de un administrador.
CREATE VIEW vista_historico_reclamos_administrador AS
SELECT 
    hr.id_reclamo,
    hr.descripcion,
    hr.fecha,
    c.direccion AS consorcio
FROM 
    h_Reclamos hr
JOIN 
    Consorcios c ON hr.id_consorcio = c.id_consorcio
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador
ORDER BY 
    hr.fecha DESC;

-- Vista para obtener la última expensa de cada propietario.
CREATE VIEW vista_ultima_expensa_propietarios AS
SELECT 
    e.id_propietario,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
    c.direccion AS consorcio,
    funcion_obtener_periodo(e.id_pagos_periodo) AS periodo,
    e.monto,
    e.fecha_vencimiento,
    e.pagado
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
WHERE 
    e.id_expensa = funcion_obtener_ultima_expensa(e.id_propietario);

-- Vista que brinda información general de los propietarios morosos (aquellos que tienen expensas sin pagar).
CREATE VIEW vista_propietarios_morosos AS
SELECT 
    e.id_propietario,
    p.nombre,
    p.apellido,
    e.monto,
    e.fecha_vencimiento,
    c.id_consorcio,
    c.direccion AS consorcio,
    e.id_pagos_periodo
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
WHERE 
    e.pagado = FALSE
ORDER BY 
    e.fecha_vencimiento DESC;

-- Vista que muestra el pago por período (h_Pagos_Periodo) más reciente asociado a cada consorcio.    
CREATE VIEW vista_pago_periodo_reciente AS
SELECT 
    c.id_consorcio,
    c.direccion AS consorcio,
    pp.id_pagos_periodo,
    pp.periodo,
    pp.monto_total
FROM 
    Consorcios c
JOIN 
    h_Pagos_Periodo pp ON c.id_consorcio = pp.id_consorcio
WHERE 
    pp.periodo = funcion_obtener_periodo_reciente(c.id_consorcio);

-- Vista que muestra los últimos 100 gastos (h_Gastos) para cada consorcio, ordenados por sus períodos.
CREATE VIEW vista_ultimos_100_gastos_consorcio AS
SELECT 
    g.id_gasto,
    g.id_proveedor,
    g.id_consorcio,
    c.direccion AS consorcio,
    g.id_pagos_periodo,
    g.costo_total,
    g.fecha,
    g.concepto
FROM 
    h_Gastos g
JOIN 
    Consorcios c ON g.id_consorcio = c.id_consorcio
ORDER BY 
    g.id_consorcio, g.fecha DESC
LIMIT 100;

-- Creacion de SPs.

DELIMITER  //

-- SP para crear y actualizar las expensas de los propietarios asociados a un consorcio en base a un id_pagos_periodo y id_consorcio.
CREATE PROCEDURE sp_crear_actualizar_expensas_propietarios(
    IN id_consorcio_nuevo INT,
    IN id_pagos_periodo_nuevo INT
)
BEGIN
    DECLARE monto_total_nuevo DECIMAL(10,2);

    -- Obtener el monto total del periodo de pagos.
    SELECT monto_total INTO monto_total_nuevo
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;

    -- Actualizar las expensas existentes para cada propietario.
    UPDATE h_Expensas e
    JOIN propietarios p ON e.id_propietario = p.id_propietario
    SET e.monto = funcion_calcular_expensas_propietario(monto_total_nuevo, p.porcentaje_fiscal)
    WHERE e.id_pagos_periodo = id_pagos_periodo_nuevo AND p.id_consorcio = id_consorcio_nuevo;

    -- Insertar expensas para los propietarios que no tienen una entrada para el periodo.
    INSERT INTO h_Expensas (id_propietario, id_pagos_periodo, fecha_vencimiento, pagado, monto)
    SELECT p.id_propietario, id_pagos_periodo_nuevo, funcion_obtener_fecha_vencimiento_por_id(id_pagos_periodo_nuevo), FALSE, funcion_calcular_expensas_propietario(monto_total_nuevo, p.porcentaje_fiscal)
    FROM Propietarios p
    WHERE p.id_consorcio = id_consorcio_nuevo
      AND NOT EXISTS (
          SELECT 1
          FROM h_Expensas e
          WHERE e.id_propietario = p.id_propietario AND e.id_pagos_periodo = id_pagos_periodo_nuevo
      );
END //

DELIMITER ;

-- Creacion de Triggers.
DELIMITER  //

-- Trigger que verifica si ya existe una entrada de h_Pagos_Periodo para el consorcio y el período de un nuevo gasto. Si encuentra uno apropiado, se le modifica el monto_total y
-- se asigna a este nuevo gasto. Si no existe un h_Pagos_Periodo adecuado al gasto, crea una nueva entrada con el costo del gasto. 
-- Además, llama a sp_crear_actualizar_expensas_propietarios
CREATE TRIGGER trigger_antes_insertar_gasto
BEFORE INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE id_pago_periodo_existente INT;
    DECLARE nuevo_periodo VARCHAR(20);

    -- Obtener el período basado en la fecha del nuevo gasto.
    SET nuevo_periodo = funcion_obtener_periodo_por_fecha(NEW.fecha);

    -- Verificar si ya existe un registro en h_Pagos_Periodo para el consorcio y el período.
    SELECT id_pagos_periodo INTO id_pago_periodo_existente
    FROM h_Pagos_Periodo
    WHERE id_consorcio = NEW.id_consorcio AND periodo = nuevo_periodo
	LIMIT 1;

    -- Si existe un registro, actualizar id_pagos_periodo del nuevo gasto y el monto total del período.
    IF id_pago_periodo_existente IS NOT NULL THEN
        SET NEW.id_pagos_periodo = id_pago_periodo_existente;
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total + NEW.costo_total
        WHERE id_pagos_periodo = id_pago_periodo_existente;
    ELSE
        -- Si no existe un registro, crear una nueva entrada en h_Pagos_Periodo.
        INSERT INTO h_Pagos_Periodo (id_consorcio, periodo, monto_total)
        VALUES (NEW.id_consorcio, nuevo_periodo, NEW.costo_total);
        
        -- Obtener el id_pagos_periodo recién creado.
        SET NEW.id_pagos_periodo = LAST_INSERT_ID();
    END IF;

    -- Llamar al stored procedure para actualizar o crear las expensas de los propietarios.
    CALL sp_crear_actualizar_expensas_propietarios(NEW.id_consorcio, NEW.id_pagos_periodo);
END //

-- Trigger para actualizar el monto_total del pago período y expensas al actualizar un gasto.
CREATE TRIGGER trigger_actualizacion_gasto
AFTER UPDATE ON h_Gastos
FOR EACH ROW
BEGIN
    -- Verificar si el costo_total ha cambiado.
    IF OLD.costo_total != NEW.costo_total THEN
        -- Actualizar el monto total en la tabla h_Pagos_Periodo.
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total - OLD.costo_total + NEW.costo_total
        WHERE id_pagos_periodo = OLD.id_pagos_periodo;

        -- Llamar al procedimiento para actualizar las expensas de los propietarios.
        CALL sp_crear_actualizar_expensas_propietarios(OLD.id_consorcio, OLD.id_pagos_periodo);
    END IF;
END //

DELIMITER  ;

-- Inserción de datos
-- Insertar Administradores (10)
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (1, 'Ankunding-Marquardt', '33-77179407-1', '1100656503', 'bbrewitt0@huffingtonpost.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (2, 'Oberbrunner-Jacobi', '23-36919033-1', '1134185143', 'kruzic1@dmoz.org');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (3, 'Schmidt-Jacobi', '20-18851079-0', '1168450779', 'cfausset2@surveymonkey.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (4, 'Fadel-Lowe', '27-46109228-2', '1100651188', 'ltester3@cnbc.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (5, 'Sipes-Jenkins', '20-66066120-3', '1193127790', 'jives4@oaic.gov.au');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (6, 'Renner, Boyle and Tillman', '33-35290917-1', '1172853216', 'dcoggon5@time.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (7, 'Stanton-Kunze', '23-83924505-3', '1174660157', 'oolpin6@tripadvisor.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (8, 'Zboncak Group', '30-75414810-0', '1156895922', 'gmackimm7@hc360.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (9, 'Hills-Casper', '20-34015163-3', '1161001442', 'khaggett8@wordpress.org');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (10, 'Rath Group', '30-21187055-2', '1192933846', 'hvolet9@admin.ch');
-- Insertar Encargados (10)
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (1, 'Garvin', 'Lambole', '20-05785675-6', '505954');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (2, 'Jefferey', 'Haxby', '99-94897644-8', '472932.6');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (3, 'Blane', 'Follis', '23-34982506-6', '368668');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (4, 'Barbara', 'Lynde', '99-40578871-3', '540302.2');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (5, 'Dani', 'Arnholdt', '30-86175972-0', '605277.96');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (6, 'Lorene', 'Crookes', '50-06780797-1', '1413595');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (7, 'Bil', 'McGonigal', '34-30686084-7', '1684194.6');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (8, 'Gretchen', 'Syce', '50-32403123-0', '2534242.1');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (9, 'Theodore', 'Mobley', '50-35057518-5', '669224.1');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (10, 'Aurea', 'Bartoshevich', '50-05062107-9', '1440707');
-- Insertar Consorcios (10)
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (1, '33-75759115-3', '66 Walton Crossing', 572, 10, 1);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (2, '30-78335263-3', '857 Muir Trail', 483, 9, 2);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (3, '30-54927417-1', '35 Lake View Pass', 598, 2, 3);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (4, '30-32286770-1', '11330 Johnson Street', 539, 1, 4);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (5, '23-13590496-2', '2 Nobel Place', 390, 2, 5);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (6, '20-65346667-0', '28 Anniversary Terrace', 648, 3, 6);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (7, '20-26751285-1', '59 Mifflin Hill', 496, 8, 7);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (8, '30-50642535-2', '83 Haas Trail', 380, 3, 8);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (9, '20-08965651-3', '73 Lindbergh Drive', 626, 2, 9);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (10, '23-78074622-1', '678 Thackeray Terrace', 641, 3, 10);
-- Insertar Proveedores (12)
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (1, 'Wilkinson-Bins', '1190313781', 'jmeeking0@cnn.com', 'Painter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (2, 'Kuhlman, Kulas and Bayer', '1103701294', 'medleston1@uiuc.edu', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (3, 'Breitenberg, McClure and Moore', '1198791801', 'aeberz2@pagesperso-orange.fr', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (4, 'Hammes, Beatty and Hodkiewicz', '1189837366', 'enorree3@blogger.com', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (5, 'Purdy and Sons', '1125650971', 'mavraham4@fotki.com', 'Plumber');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (6, 'Carroll-Hermiston', '1199579134', 'nmccumesky5@ibm.com', 'Plumber');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (7, 'Harris Inc', '1141568649', 'dsturte6@taobao.com', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (8, 'Wunsch Group', '1162550807', 'crymell7@booking.com', 'Electrician');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (9, 'Blanda LLC', '1197744988', 'hmarke8@baidu.com', 'Landscaper');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (10, 'Wisozk-Denesik', '1164383567', 'hgriffiths9@meetup.com', 'Landscaper');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (11, 'Proveedor A', '1156781234', 'proveedora@example.com', 'Limpieza');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (12, 'Proveedor B', '1156785678', 'proveedorb@example.com', 'Mantenimiento');
-- Insertar Propietarios(500)
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (1, 'Ag', 'Juzek', '1186472205', 'ajuzek0@nps.gov', '9F', 7, 41, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (2, 'Baudoin', 'Bosence', '1163919089', 'bbosence1@phoca.cz', '23F', 4, 82, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (3, 'Pacorro', 'Delue', '1110957398', 'pdelue2@com.com', '24F', 8, 84, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (4, 'Buiron', 'Hymus', '1130761579', 'bhymus3@biblegateway.com', '16B', 8, 103, '2.28');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (5, 'Odilia', 'Gavriel', '1128367625', 'ogavriel4@geocities.jp', '6A', 6, 14, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (6, 'Syman', 'Livett', '1112902716', 'slivett5@com.com', '1B', 4, 86, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (7, 'Griz', 'Mingard', '1165678929', 'gmingard6@dell.com', '17A', 7, 31, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (8, 'Jeannie', 'Tindley', '1147472362', 'jtindley7@gov.uk', '28A', 2, 66, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (9, 'Murry', 'Rubra', '1194602703', 'mrubra8@engadget.com', '19E', 4, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (10, 'Berk', 'Baggett', '1117093986', 'bbaggett9@tamu.edu', '1A', 10, 72, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (11, 'Vannie', 'Keeting', '1162597211', 'vkeetinga@ca.gov', '2D', 4, 2, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (12, 'Normand', 'Atteridge', '1107338601', 'natteridgeb@epa.gov', '8A', 8, 42, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (13, 'Ginny', 'Eisig', '1150482127', 'geisigc@ebay.com', '5F', 8, 46, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (14, 'Chrissie', 'Blunkett', '1197741471', 'cblunkettd@booking.com', '24E', 8, 93, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (15, 'Swen', 'Allworthy', '1172895096', 'sallworthye@va.gov', '5B', 5, 117, '1.94');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (16, 'Delmore', 'Heimes', '1137713773', 'dheimesf@uiuc.edu', '2F', 8, 10, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (17, 'Sharleen', 'Wyard', '1177950512', 'swyardg@va.gov', '3A', 7, 102, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (18, 'Anderea', 'Dainty', '1197613628', 'adaintyh@nifty.com', '6C', 7, 77, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (19, 'Lorianna', 'Lebbon', '1146860260', 'llebboni@soundcloud.com', '8C', 1, 56, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (20, 'Bonny', 'Quan', '1162850087', 'bquanj@cnet.com', '13C', 5, 60, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (21, 'Florencia', 'Edling', '1101451013', 'fedlingk@pcworld.com', '28C', 7, 102, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (22, 'Ricardo', 'Parnham', '1120489467', 'rparnhaml@hexun.com', '18F', 5, 23, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (23, 'Brynn', 'Lenihan', '1119698842', 'blenihanm@amazon.co.uk', '18E', 2, 119, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (24, 'Trefor', 'Haggus', '1111866082', 'thaggusn@java.com', '26E', 7, 10, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (25, 'Sonnie', 'Everitt', '1119532085', 'severitto@technorati.com', '19B', 5, 51, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (26, 'Vaughn', 'Armitage', '1178905935', 'varmitagep@telegraph.co.uk', '13F', 8, 29, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (27, 'Lucias', 'Fonso', '1156899014', 'lfonsoq@hao123.com', '5C', 6, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (28, 'Harriot', 'Pitrelli', '1184626546', 'hpitrellir@kickstarter.com', '8D', 8, 89, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (29, 'Aubine', 'Tire', '1199640926', 'atires@github.io', '15A', 2, 108, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (30, 'Papagena', 'Minihane', '1184372773', 'pminihanet@hatena.ne.jp', '15E', 2, 119, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (31, 'Marlyn', 'Stollenhof', '1112527717', 'mstollenhofu@scientificamerican.com', '2F', 10, 112, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (32, 'Ariadne', 'Stennine', '1192451634', 'astenninev@desdev.cn', '27E', 9, 6, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (33, 'Gwenora', 'Kintish', '1126120723', 'gkintishw@last.fm', '29D', 3, 60, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (34, 'Katuscha', 'Nials', '1193071630', 'knialsx@patch.com', '14D', 4, 88, '1.71');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (35, 'Veronica', 'Ingamells', '1165707264', 'vingamellsy@squidoo.com', '21A', 2, 42, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (36, 'Kevin', 'Pavolini', '1144597201', 'kpavoliniz@sina.com.cn', '22D', 3, 53, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (37, 'Kinny', 'Hampshire', '1111794046', 'khampshire10@scientificamerican.com', '9B', 9, 65, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (38, 'Giustino', 'Jent', '1122070173', 'gjent11@boston.com', '29A', 10, 101, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (39, 'Leone', 'Wraighte', '1135531473', 'lwraighte12@reuters.com', '7C', 8, 98, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (40, 'Robert', 'Strangeway', '1169229642', 'rstrangeway13@nps.gov', '3D', 5, 119, '2.11');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (41, 'Langsdon', 'Regis', '1181555859', 'lregis14@over-blog.com', '23C', 7, 35, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (42, 'Thor', 'Costi', '1128447296', 'tcosti15@odnoklassniki.ru', '11B', 9, 58, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (43, 'Aila', 'Bridgland', '1108028722', 'abridgland16@taobao.com', '24B', 3, 94, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (44, 'Dido', 'Gadaud', '1192141029', 'dgadaud17@cbc.ca', '27A', 7, 10, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (45, 'Hendrick', 'Fossord', '1192979403', 'hfossord18@comsenz.com', '26D', 2, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (46, 'Alicia', 'Baldcock', '1145420731', 'abaldcock19@auda.org.au', '11E', 2, 38, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (47, 'Gannie', 'Heugel', '1118137145', 'gheugel1a@barnesandnoble.com', '4E', 6, 79, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (48, 'Alberto', 'Tremellier', '1134096932', 'atremellier1b@topsy.com', '21B', 9, 46, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (49, 'Winna', 'Livingston', '1146962828', 'wlivingston1c@sitemeter.com', '9C', 7, 41, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (50, 'Frederique', 'Maffia', '1183716869', 'fmaffia1d@ovh.net', '7D', 1, 87, '1.61');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (51, 'Bathsheba', 'Learned', '1119576035', 'blearned1e@mac.com', '27C', 5, 29, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (52, 'Jonah', 'Freestone', '1188296865', 'jfreestone1f@independent.co.uk', '11B', 2, 117, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (53, 'Vivyan', 'O''Cahill', '1134570903', 'vocahill1g@tinyurl.com', '2B', 6, 64, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (54, 'Valentino', 'O''Leary', '1127436654', 'voleary1h@nps.gov', '3A', 10, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (55, 'Lexis', 'Yerson', '1152602451', 'lyerson1i@ox.ac.uk', '9D', 7, 15, '2.10');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (56, 'Sol', 'Bummfrey', '1167422543', 'sbummfrey1j@acquirethisname.com', '17C', 10, 56, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (57, 'Lotti', 'Luten', '1194457874', 'lluten1k@live.com', '21A', 9, 116, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (58, 'Petronella', 'Eyckelberg', '1159199169', 'peyckelberg1l@xing.com', '27C', 3, 100, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (59, 'Linet', 'Lally', '1106931483', 'llally1m@desdev.cn', '14B', 6, 77, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (60, 'Burton', 'Britnell', '1110458826', 'bbritnell1n@mlb.com', '24D', 5, 15, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (61, 'Quintilla', 'Attwoul', '1175186791', 'qattwoul1o@scientificamerican.com', '11A', 4, 110, '2.34');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (62, 'Crissie', 'Armsden', '1157955718', 'carmsden1p@whitehouse.gov', '22E', 1, 77, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (63, 'Giles', 'Huddles', '1164580140', 'ghuddles1q@auda.org.au', '22C', 8, 110, '2.18');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (64, 'Lindy', 'Reinbach', '1187217921', 'lreinbach1r@hp.com', '24E', 4, 59, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (65, 'Kally', 'Manilo', '1139749342', 'kmanilo1s@paypal.com', '3B', 8, 21, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (66, 'Thornton', 'Dwine', '1158005028', 'tdwine1t@slate.com', '13B', 3, 90, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (67, 'Rafaelita', 'Benoey', '1178140644', 'rbenoey1u@nps.gov', '13B', 7, 120, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (68, 'Tobie', 'Tinson', '1165101227', 'ttinson1v@globo.com', '6E', 6, 10, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (69, 'Jacquelin', 'Sparway', '1170636286', 'jsparway1w@google.ca', '7B', 10, 112, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (70, 'Bayard', 'Overill', '1141499703', 'boverill1x@nhs.uk', '19E', 8, 114, '1.70');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (71, 'Madison', 'Crummey', '1189121030', 'mcrummey1y@aboutads.info', '19E', 2, 118, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (72, 'Lilas', 'Janssens', '1110533477', 'ljanssens1z@mapy.cz', '7B', 8, 65, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (73, 'Mallory', 'Lowles', '1175958123', 'mlowles20@google.com.br', '17D', 2, 54, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (74, 'Flossi', 'Abramzon', '1174739980', 'fabramzon21@hugedomains.com', '2E', 1, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (75, 'Agnese', 'Bollam', '1172676634', 'abollam22@reddit.com', '24E', 8, 62, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (76, 'Adelaide', 'Penk', '1125649579', 'apenk23@jimdo.com', '16D', 1, 50, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (77, 'Emelia', 'Iacobassi', '1111322421', 'eiacobassi24@reference.com', '7F', 8, 12, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (78, 'Trevar', 'O''Spillane', '1146706251', 'tospillane25@quantcast.com', '9C', 4, 45, '2.32');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (79, 'Emmi', 'Shucksmith', '1151664779', 'eshucksmith26@squarespace.com', '2D', 3, 95, '1.32');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (80, 'Manny', 'Collison', '1105047108', 'mcollison27@ezinearticles.com', '7F', 2, 9, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (81, 'Trenna', 'Hugueville', '1176701210', 'thugueville28@blogspot.com', '15D', 8, 63, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (82, 'Mitchael', 'Madden', '1178491991', 'mmadden29@princeton.edu', '1C', 3, 120, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (83, 'Ephrayim', 'Probets', '1157902185', 'eprobets2a@woothemes.com', '2B', 2, 2, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (84, 'Maison', 'Kingcote', '1184673673', 'mkingcote2b@boston.com', '23D', 7, 2, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (85, 'Rozanne', 'Sheekey', '1189452173', 'rsheekey2c@microsoft.com', '8C', 10, 109, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (86, 'Dahlia', 'Wayvill', '1115919341', 'dwayvill2d@behance.net', '21A', 3, 35, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (87, 'Inez', 'Speaks', '1123513017', 'ispeaks2e@google.ca', '6A', 3, 58, '2.15');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (88, 'Rolfe', 'O''Codihie', '1173987833', 'rocodihie2f@51.la', '8B', 10, 110, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (89, 'Baird', 'Bovingdon', '1156681674', 'bbovingdon2g@jigsy.com', '27F', 4, 10, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (90, 'Stefa', 'Resun', '1114709457', 'sresun2h@hatena.ne.jp', '27C', 9, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (91, 'Inger', 'Penman', '1141297184', 'ipenman2i@liveinternet.ru', '7A', 6, 4, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (92, 'Gratia', 'Teffrey', '1112139992', 'gteffrey2j@google.ca', '4A', 6, 13, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (93, 'Cairistiona', 'Vine', '1158656401', 'cvine2k@freewebs.com', '6C', 10, 33, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (94, 'Caitrin', 'Lezemere', '1120818223', 'clezemere2l@engadget.com', '2E', 5, 18, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (95, 'Griffie', 'Witsey', '1182503344', 'gwitsey2m@hp.com', '5A', 4, 72, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (96, 'Leisha', 'Gommery', '1196518793', 'lgommery2n@shinystat.com', '4B', 4, 47, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (97, 'Wiley', 'Kenningley', '1152452523', 'wkenningley2o@usgs.gov', '4F', 1, 41, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (98, 'Chickie', 'Sapena', '1166726932', 'csapena2p@squidoo.com', '8E', 5, 15, '2.14');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (99, 'Sarette', 'Brookwell', '1154089490', 'sbrookwell2q@huffingtonpost.com', '19B', 4, 58, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (100, 'Carly', 'Vasechkin', '1157984067', 'cvasechkin2r@storify.com', '9D', 3, 44, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (101, 'Barret', 'Chittenden', '1193486630', 'bchittenden2s@ucsd.edu', '6A', 4, 27, '1.95');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (102, 'Reagen', 'Plewright', '1109883604', 'rplewright2t@spiegel.de', '5A', 5, 52, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (103, 'Britta', 'Reuble', '1105987426', 'breuble2u@yelp.com', '14F', 5, 57, '2.07');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (104, 'Simona', 'Eronie', '1132273757', 'seronie2v@forbes.com', '5A', 9, 54, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (105, 'Kylynn', 'Santacrole', '1189592205', 'ksantacrole2w@nasa.gov', '29E', 4, 77, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (106, 'Marsha', 'Lisamore', '1165918141', 'mlisamore2x@ucsd.edu', '17D', 3, 57, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (107, 'Bram', 'Grimm', '1154031177', 'bgrimm2y@networksolutions.com', '12E', 7, 88, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (108, 'Cymbre', 'Drezzer', '1129805700', 'cdrezzer2z@washington.edu', '18F', 7, 61, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (109, 'Sully', 'World', '1178292447', 'sworld30@nationalgeographic.com', '18E', 1, 110, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (110, 'Gay', 'Curryer', '1198364715', 'gcurryer31@ameblo.jp', '4A', 9, 16, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (111, 'Karine', 'Mossop', '1143501392', 'kmossop32@mapy.cz', '22A', 1, 20, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (112, 'Shelby', 'Melly', '1164783692', 'smelly33@cafepress.com', '24C', 1, 114, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (113, 'Daisie', 'Lucio', '1199278366', 'dlucio34@ezinearticles.com', '6E', 5, 106, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (114, 'Kelby', 'Batchelour', '1159212888', 'kbatchelour35@mit.edu', '26F', 1, 117, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (115, 'Nadia', 'Blazdell', '1180882150', 'nblazdell36@wikia.com', '8F', 2, 1, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (116, 'Gillian', 'Gimenez', '1168528565', 'ggimenez37@google.co.uk', '6C', 6, 65, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (117, 'Edee', 'Donavan', '1179938673', 'edonavan38@free.fr', '1E', 8, 57, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (118, 'Olivia', 'Addison', '1171379805', 'oaddison39@elegantthemes.com', '13F', 1, 4, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (119, 'Teodor', 'Meeks', '1172970450', 'tmeeks3a@mediafire.com', '26B', 3, 67, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (120, 'Town', 'Cowing', '1147399521', 'tcowing3b@chicagotribune.com', '4B', 3, 103, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (121, 'Isac', 'Reynard', '1141461090', 'ireynard3c@berkeley.edu', '18F', 9, 30, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (122, 'Emilee', 'Trassler', '1197433460', 'etrassler3d@yahoo.com', '11F', 8, 76, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (123, 'Steffi', 'Kinsley', '1152460978', 'skinsley3e@etsy.com', '1E', 2, 60, '2.28');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (124, 'Appolonia', 'Dowbakin', '1119791566', 'adowbakin3f@bloglines.com', '4A', 9, 94, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (125, 'Claudina', 'Breeds', '1139905983', 'cbreeds3g@spiegel.de', '1B', 6, 67, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (126, 'Emlynne', 'Maxwale', '1192159051', 'emaxwale3h@naver.com', '2A', 2, 32, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (127, 'Jodie', 'Mawer', '1117952886', 'jmawer3i@indiatimes.com', '25B', 6, 110, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (128, 'Jae', 'Daffey', '1120688763', 'jdaffey3j@xing.com', '3D', 8, 99, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (129, 'Jayson', 'Whapple', '1100370492', 'jwhapple3k@smugmug.com', '17E', 10, 25, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (130, 'Vinson', 'Speddin', '1157609862', 'vspeddin3l@google.com', '17A', 7, 52, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (131, 'Avigdor', 'Cruise', '1177531825', 'acruise3m@fc2.com', '22E', 7, 7, '2.43');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (132, 'Erna', 'Sullens', '1183849745', 'esullens3n@merriam-webster.com', '2A', 1, 110, '2.12');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (133, 'Gasparo', 'Dougharty', '1133756571', 'gdougharty3o@unicef.org', '23B', 5, 12, '1.23');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (134, 'Vaclav', 'Baterip', '1149450777', 'vbaterip3p@google.es', '27C', 2, 58, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (135, 'Coralyn', 'Ingrey', '1137913080', 'cingrey3q@reference.com', '2B', 6, 94, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (136, 'Lindsay', 'Alen', '1135500821', 'lalen3r@topsy.com', '15B', 9, 73, '2.21');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (137, 'Rozamond', 'Trill', '1142443136', 'rtrill3s@furl.net', '9B', 10, 94, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (138, 'Theodosia', 'Maven', '1113087656', 'tmaven3t@noaa.gov', '27E', 2, 46, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (139, 'Lib', 'Dimsdale', '1116646687', 'ldimsdale3u@springer.com', '6B', 1, 45, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (140, 'Barbe', 'Steenson', '1142942308', 'bsteenson3v@blogspot.com', '11F', 10, 21, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (141, 'Chandal', 'Stanley', '1130038579', 'cstanley3w@shinystat.com', '7B', 1, 97, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (142, 'Early', 'Hoffner', '1110618148', 'ehoffner3x@ameblo.jp', '19D', 6, 116, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (143, 'Niki', 'Pund', '1196039056', 'npund3y@infoseek.co.jp', '8C', 7, 39, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (144, 'Catharine', 'Wingate', '1118356809', 'cwingate3z@dmoz.org', '6E', 10, 65, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (145, 'Quinn', 'Bullivent', '1175826296', 'qbullivent40@fastcompany.com', '3B', 2, 106, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (146, 'Gregoor', 'de Nore', '1183543063', 'gdenore41@gravatar.com', '13B', 7, 27, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (147, 'Ashely', 'Ioan', '1196670894', 'aioan42@wordpress.org', '9F', 7, 60, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (148, 'Josias', 'Birchwood', '1174872656', 'jbirchwood43@creativecommons.org', '13D', 10, 20, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (149, 'Gwyn', 'Deetlefs', '1105604559', 'gdeetlefs44@over-blog.com', '7D', 5, 40, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (150, 'Fawne', 'Drake', '1149609406', 'fdrake45@purevolume.com', '1C', 8, 19, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (151, 'Ted', 'Nibley', '1143931624', 'tnibley46@zimbio.com', '17E', 6, 105, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (152, 'Pembroke', 'Caddick', '1102135515', 'pcaddick47@slate.com', '19C', 4, 58, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (153, 'Julius', 'Rego', '1164242462', 'jrego48@sina.com.cn', '17A', 2, 42, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (154, 'Laverna', 'Crocumbe', '1131943941', 'lcrocumbe49@cornell.edu', '7A', 1, 109, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (155, 'Chic', 'Bispo', '1182732588', 'cbispo4a@bloglines.com', '27A', 9, 20, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (156, 'Alfy', 'Pitman', '1199142968', 'apitman4b@chron.com', '1B', 3, 97, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (157, 'Shawna', 'Altamirano', '1119242961', 'saltamirano4c@washington.edu', '15E', 4, 100, '2.25');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (158, 'Fransisco', 'Senecaux', '1134142800', 'fsenecaux4d@mail.ru', '2D', 9, 13, '2.17');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (159, 'Prince', 'Stenning', '1108603926', 'pstenning4e@myspace.com', '6F', 5, 44, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (160, 'Vivyanne', 'Demogeot', '1104464530', 'vdemogeot4f@storify.com', '27B', 1, 5, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (161, 'Huey', 'Vasilmanov', '1141363671', 'hvasilmanov4g@sciencedaily.com', '2E', 2, 3, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (162, 'Talya', 'Orto', '1127180694', 'torto4h@mayoclinic.com', '22F', 1, 84, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (163, 'Wilhelmine', 'Eagland', '1141232837', 'weagland4i@cloudflare.com', '14B', 8, 98, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (164, 'York', 'Gilbey', '1145309646', 'ygilbey4j@imageshack.us', '12E', 10, 49, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (165, 'Alf', 'Dudderidge', '1173662134', 'adudderidge4k@t.co', '16B', 7, 119, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (166, 'Burton', 'McElrea', '1123365838', 'bmcelrea4l@woothemes.com', '7F', 5, 6, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (167, 'Luz', 'Ironside', '1163855020', 'lironside4m@wufoo.com', '27E', 5, 111, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (168, 'Othella', 'Venart', '1171240911', 'ovenart4n@php.net', '5D', 6, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (169, 'Marji', 'McKinlay', '1198583220', 'mmckinlay4o@mit.edu', '2A', 9, 41, '1.71');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (170, 'Gunner', 'Ghirigori', '1125362778', 'gghirigori4p@google.pl', '9D', 2, 109, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (171, 'Aurelie', 'Fraschini', '1118848010', 'afraschini4q@china.com.cn', '6F', 10, 31, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (172, 'Angel', 'Gillopp', '1102987881', 'agillopp4r@sakura.ne.jp', '1D', 7, 112, '2.39');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (173, 'Joseph', 'Pohlak', '1111493590', 'jpohlak4s@edublogs.org', '9A', 1, 62, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (174, 'Julienne', 'Petrushanko', '1171515867', 'jpetrushanko4t@biblegateway.com', '28B', 7, 104, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (175, 'Dov', 'Portch', '1169048099', 'dportch4u@alexa.com', '3C', 10, 63, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (176, 'Geraldine', 'Colaco', '1181736435', 'gcolaco4v@addtoany.com', '4A', 2, 39, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (177, 'Adora', 'Fairclough', '1168040570', 'afairclough4w@canalblog.com', '1C', 3, 91, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (178, 'Emili', 'Betke', '1113146994', 'ebetke4x@cpanel.net', '16C', 10, 24, '1.67');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (179, 'Irvin', 'Zeale', '1182556892', 'izeale4y@shinystat.com', '3F', 9, 25, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (180, 'Rica', 'Attril', '1114815946', 'rattril4z@lycos.com', '3F', 8, 119, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (181, 'Lauren', 'Weadick', '1183912622', 'lweadick50@sbwire.com', '9D', 8, 100, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (182, 'Stevie', 'Wakeman', '1150157566', 'swakeman51@cnet.com', '23D', 8, 41, '1.74');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (183, 'Olag', 'Salmond', '1162268803', 'osalmond52@sciencedirect.com', '4D', 4, 107, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (184, 'Maxie', 'Nisco', '1177433762', 'mnisco53@irs.gov', '7A', 5, 117, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (185, 'Ernestus', 'Kasparski', '1121856704', 'ekasparski54@google.fr', '8C', 8, 25, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (186, 'Hank', 'Belliveau', '1107344339', 'hbelliveau55@blogspot.com', '25F', 3, 49, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (187, 'Lolita', 'Vandrill', '1127200414', 'lvandrill56@ehow.com', '12C', 9, 51, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (188, 'Susi', 'Conford', '1142836789', 'sconford57@reuters.com', '4A', 5, 56, '1.38');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (189, 'Clevie', 'Swale', '1162520002', 'cswale58@ustream.tv', '28F', 1, 101, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (190, 'Noak', 'Lycett', '1138819621', 'nlycett59@photobucket.com', '29E', 8, 74, '2.32');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (191, 'Venus', 'Bermingham', '1137850238', 'vbermingham5a@ted.com', '8C', 9, 94, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (192, 'Aridatha', 'Bree', '1150336337', 'abree5b@indiatimes.com', '7E', 5, 61, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (193, 'Way', 'Abernethy', '1157068734', 'wabernethy5c@globo.com', '15E', 1, 29, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (194, 'Gwenneth', 'Hendrickx', '1112949681', 'ghendrickx5d@zdnet.com', '7B', 4, 60, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (195, 'Garth', 'Dacey', '1107946705', 'gdacey5e@boston.com', '9F', 1, 113, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (196, 'Emmye', 'Petcher', '1125368763', 'epetcher5f@myspace.com', '27A', 8, 18, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (197, 'Lana', 'Curwood', '1131173477', 'lcurwood5g@mac.com', '17A', 3, 20, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (198, 'Erik', 'Wistance', '1134764121', 'ewistance5h@ucsd.edu', '23A', 10, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (199, 'Corbin', 'Connue', '1119121287', 'cconnue5i@hc360.com', '3D', 6, 3, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (200, 'Dalli', 'Fairtlough', '1127102579', 'dfairtlough5j@prweb.com', '3B', 9, 43, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (201, 'Maurizio', 'O'' Mara', '1191693165', 'momara5k@indiegogo.com', '21C', 7, 34, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (202, 'Maxie', 'Scane', '1159217412', 'mscane5l@devhub.com', '7B', 3, 92, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (203, 'Freda', 'Maccrea', '1142622147', 'fmaccrea5m@eepurl.com', '7E', 4, 12, '1.25');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (204, 'Caria', 'Valsler', '1180973879', 'cvalsler5n@pagesperso-orange.fr', '14B', 6, 14, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (205, 'Karalee', 'Grinnov', '1166238021', 'kgrinnov5o@amazon.com', '18C', 9, 70, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (206, 'Pepita', 'Lines', '1164379179', 'plines5p@google.nl', '21E', 2, 3, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (207, 'Agnese', 'Hegges', '1115280263', 'ahegges5q@plala.or.jp', '13F', 9, 3, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (208, 'Aidan', 'Grishin', '1167018512', 'agrishin5r@latimes.com', '17F', 2, 103, '2.43');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (209, 'Wyatt', 'Van Dalen', '1197814455', 'wvandalen5s@gnu.org', '1F', 3, 72, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (210, 'Wallace', 'Arkin', '1114322830', 'warkin5t@google.com.au', '24F', 1, 77, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (211, 'Pierson', 'Maryin', '1127974766', 'pmaryin5u@youtu.be', '1A', 9, 58, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (212, 'Angelico', 'Doutch', '1107612253', 'adoutch5v@comcast.net', '22A', 8, 34, '1.39');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (213, 'Paxton', 'Craigie', '1101979516', 'pcraigie5w@umn.edu', '23B', 5, 96, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (214, 'Arlette', 'Beneteau', '1127807181', 'abeneteau5x@businesswire.com', '17B', 4, 102, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (215, 'Eleen', 'Lenton', '1178226963', 'elenton5y@amazon.co.jp', '6E', 8, 82, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (216, 'Avery', 'Darrington', '1121042730', 'adarrington5z@diigo.com', '19F', 9, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (217, 'Larina', 'Grime', '1141434631', 'lgrime60@flickr.com', '16C', 1, 111, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (218, 'Fairfax', 'Baylie', '1152732757', 'fbaylie61@desdev.cn', '3E', 9, 98, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (219, 'Elwyn', 'Haggis', '1147913232', 'ehaggis62@domainmarket.com', '8C', 3, 16, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (220, 'Karlie', 'Menis', '1136550684', 'kmenis63@mapquest.com', '12C', 5, 35, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (221, 'Karlotta', 'Dukelow', '1159096585', 'kdukelow64@si.edu', '22B', 9, 94, '1.29');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (222, 'Lorrayne', 'Hovy', '1120637667', 'lhovy65@google.com', '18F', 5, 10, '1.04');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (223, 'Ber', 'Cristoforo', '1108176094', 'bcristoforo66@macromedia.com', '9F', 3, 35, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (224, 'Marius', 'Belchamber', '1120842473', 'mbelchamber67@a8.net', '3B', 8, 36, '1.18');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (225, 'Adam', 'Philpin', '1177192484', 'aphilpin68@omniture.com', '29F', 6, 15, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (226, 'Kynthia', 'Holmyard', '1178117433', 'kholmyard69@independent.co.uk', '14E', 1, 63, '1.61');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (227, 'Kirstin', 'Meriguet', '1153622427', 'kmeriguet6a@technorati.com', '16E', 2, 36, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (228, 'Umberto', 'Bulch', '1155247260', 'ubulch6b@virginia.edu', '15D', 5, 51, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (229, 'Rafe', 'Titchmarsh', '1178635603', 'rtitchmarsh6c@cdc.gov', '14A', 6, 119, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (230, 'Natal', 'Ascough', '1198059692', 'nascough6d@smh.com.au', '8E', 10, 114, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (231, 'Davida', 'Gauford', '1104871285', 'dgauford6e@dion.ne.jp', '18F', 2, 107, '1.62');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (232, 'Ania', 'Brabon', '1182361469', 'abrabon6f@parallels.com', '1E', 8, 28, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (233, 'Isiahi', 'Nevinson', '1193861315', 'inevinson6g@ycombinator.com', '9B', 3, 87, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (234, 'Valencia', 'Fusedale', '1155492696', 'vfusedale6h@answers.com', '2E', 4, 99, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (235, 'Homerus', 'Kopmann', '1176409699', 'hkopmann6i@google.pl', '5E', 4, 95, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (236, 'Madonna', 'Sidnell', '1174059561', 'msidnell6j@nsw.gov.au', '9B', 3, 92, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (237, 'Ardisj', 'Clemendot', '1101567887', 'aclemendot6k@amazon.com', '19E', 2, 58, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (238, 'Katinka', 'Frushard', '1159753391', 'kfrushard6l@huffingtonpost.com', '14D', 3, 113, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (239, 'Ericka', 'Lutty', '1112502371', 'elutty6m@tiny.cc', '25C', 7, 77, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (240, 'Jeannie', 'Hambrick', '1142980216', 'jhambrick6n@archive.org', '27D', 6, 101, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (241, 'Sayers', 'Westman', '1141302393', 'swestman6o@slate.com', '16E', 3, 57, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (242, 'Fergus', 'Gillimgham', '1113351593', 'fgillimgham6p@irs.gov', '3A', 6, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (243, 'Ansley', 'Charter', '1170774599', 'acharter6q@xing.com', '22E', 8, 72, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (244, 'Carmina', 'Boland', '1142061088', 'cboland6r@comsenz.com', '29F', 10, 70, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (245, 'Carie', 'Rumford', '1196529867', 'crumford6s@comcast.net', '8D', 10, 74, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (246, 'Juliet', 'McGiffie', '1102174895', 'jmcgiffie6t@pinterest.com', '11B', 9, 46, '2.15');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (247, 'Dwain', 'Olner', '1173501167', 'dolner6u@tinyurl.com', '2B', 9, 86, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (248, 'Adi', 'Cromwell', '1113126011', 'acromwell6v@slate.com', '2A', 1, 100, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (249, 'Melisa', 'Blackler', '1176785863', 'mblackler6w@drupal.org', '18A', 10, 59, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (250, 'Terese', 'Jovis', '1193700217', 'tjovis6x@mlb.com', '2D', 4, 46, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (251, 'Natal', 'Crambie', '1150722413', 'ncrambie6y@hud.gov', '23F', 3, 32, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (252, 'Roldan', 'Fradgley', '1131143500', 'rfradgley6z@ihg.com', '12B', 5, 53, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (253, 'Aristotle', 'Foad', '1190996060', 'afoad70@purevolume.com', '8B', 4, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (254, 'Ware', 'Maddock', '1128693760', 'wmaddock71@youtube.com', '3D', 1, 47, '1.06');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (255, 'Beverlee', 'Whapple', '1113905696', 'bwhapple72@ameblo.jp', '3B', 8, 14, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (256, 'Yorgo', 'Danielczyk', '1159139985', 'ydanielczyk73@themeforest.net', '1B', 3, 105, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (257, 'Rodina', 'Palay', '1179791372', 'rpalay74@globo.com', '15D', 2, 82, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (258, 'Dawna', 'Coniff', '1108712043', 'dconiff75@dmoz.org', '23B', 5, 41, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (259, 'Johnette', 'Vinden', '1140266709', 'jvinden76@studiopress.com', '14B', 10, 61, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (260, 'Sofia', 'Humphery', '1136957846', 'shumphery77@stumbleupon.com', '4A', 5, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (261, 'Aryn', 'Bolle', '1180966079', 'abolle78@bing.com', '17B', 2, 24, '1.58');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (262, 'Milly', 'Thomkins', '1126804753', 'mthomkins79@wp.com', '4D', 3, 13, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (263, 'Claribel', 'Johnigan', '1177236898', 'cjohnigan7a@clickbank.net', '1C', 9, 18, '2.35');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (264, 'Adara', 'Isard', '1169140787', 'aisard7b@ustream.tv', '6F', 4, 90, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (265, 'Rube', 'Scotts', '1153367048', 'rscotts7c@tripadvisor.com', '3E', 9, 33, '2.20');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (266, 'Ashleigh', 'Kippling', '1149088550', 'akippling7d@mozilla.org', '9E', 1, 9, '1.21');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (267, 'Rivalee', 'Pulford', '1128889820', 'rpulford7e@topsy.com', '1D', 3, 72, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (268, 'Victoria', 'Milbank', '1169850663', 'vmilbank7f@buzzfeed.com', '15A', 2, 35, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (269, 'Christine', 'Tatam', '1144773859', 'ctatam7g@goodreads.com', '2E', 8, 99, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (270, 'Glyn', 'Taffrey', '1142899797', 'gtaffrey7h@earthlink.net', '23C', 9, 110, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (271, 'Gabriello', 'Slyman', '1131411526', 'gslyman7i@slideshare.net', '15C', 5, 71, '1.17');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (272, 'Audre', 'Beckers', '1139485627', 'abeckers7j@mail.ru', '26F', 9, 42, '2.36');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (273, 'Emera', 'Buckney', '1179491723', 'ebuckney7k@hubpages.com', '2D', 4, 97, '2.19');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (274, 'Lorettalorna', 'Whitman', '1146022215', 'lwhitman7l@xing.com', '3E', 10, 37, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (275, 'Somerset', 'Seals', '1116692593', 'sseals7m@histats.com', '14C', 4, 31, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (276, 'Kelli', 'Fodden', '1161125539', 'kfodden7n@globo.com', '29E', 1, 50, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (277, 'Jobye', 'Bescoby', '1157470590', 'jbescoby7o@google.ca', '2E', 5, 85, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (278, 'Hew', 'Order', '1147079673', 'horder7p@reverbnation.com', '8B', 10, 84, '2.43');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (279, 'Marisa', 'Charnick', '1181524013', 'mcharnick7q@prweb.com', '13F', 7, 21, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (280, 'Sheelah', 'Hollow', '1139669556', 'shollow7r@meetup.com', '12F', 3, 12, '1.23');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (281, 'Rod', 'Fortye', '1192554551', 'rfortye7s@washington.edu', '29B', 1, 86, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (282, 'Suzann', 'Partkya', '1186737811', 'spartkya7t@slashdot.org', '5E', 9, 71, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (283, 'Fleurette', 'De Lascy', '1152552720', 'fdelascy7u@bravesites.com', '29B', 3, 120, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (284, 'Freedman', 'Hirtzmann', '1158934021', 'fhirtzmann7v@google.cn', '27F', 6, 44, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (285, 'Marie', 'Mattes', '1154792520', 'mmattes7w@goo.gl', '17E', 4, 5, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (286, 'Robbi', 'Rudland', '1119782935', 'rrudland7x@ucla.edu', '18F', 7, 39, '2.17');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (287, 'Johannes', 'Fulle', '1131871625', 'jfulle7y@blogtalkradio.com', '1A', 2, 115, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (288, 'Gerry', 'Haughin', '1181584008', 'ghaughin7z@netlog.com', '3D', 6, 79, '1.69');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (289, 'Esdras', 'Reignard', '1149226028', 'ereignard80@gizmodo.com', '8F', 2, 3, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (290, 'Brannon', 'Josham', '1126644693', 'bjosham81@nymag.com', '7A', 9, 53, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (291, 'Olivette', 'Dowson', '1134439133', 'odowson82@nytimes.com', '11D', 9, 25, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (292, 'Justina', 'Sexti', '1141334048', 'jsexti83@about.me', '6E', 2, 27, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (293, 'Nolana', 'Scarlan', '1106277903', 'nscarlan84@thetimes.co.uk', '26D', 5, 20, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (294, 'Elysee', 'Lauritsen', '1183956254', 'elauritsen85@cmu.edu', '7E', 8, 49, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (295, 'Tanhya', 'Crux', '1152988124', 'tcrux86@issuu.com', '24E', 1, 46, '2.49');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (296, 'Merridie', 'Ellcock', '1101003204', 'mellcock87@icio.us', '4C', 1, 62, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (297, 'Marjie', 'Kirkman', '1191119729', 'mkirkman88@vkontakte.ru', '3F', 2, 67, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (298, 'Ryan', 'Espinho', '1155648931', 'respinho89@theguardian.com', '9A', 6, 43, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (299, 'Zeb', 'Roscrigg', '1116585883', 'zroscrigg8a@washingtonpost.com', '8E', 10, 13, '2.42');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (300, 'Muire', 'O''Dowling', '1102079507', 'modowling8b@phpbb.com', '22A', 9, 19, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (301, 'Nissie', 'Hatliff', '1101654253', 'nhatliff8c@uol.com.br', '5A', 10, 70, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (302, 'Desiree', 'Gloster', '1162108776', 'dgloster8d@opensource.org', '24C', 4, 69, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (303, 'Rahel', 'Enns', '1194197753', 'renns8e@istockphoto.com', '5A', 2, 3, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (304, 'Mariska', 'McJarrow', '1123217588', 'mmcjarrow8f@pagesperso-orange.fr', '28C', 3, 11, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (305, 'Jesselyn', 'Crowe', '1196747625', 'jcrowe8g@time.com', '19A', 7, 120, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (306, 'Grayce', 'Leedal', '1176362987', 'gleedal8h@tinypic.com', '6A', 4, 19, '1.12');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (307, 'Odille', 'Gheorghe', '1174034987', 'ogheorghe8i@scribd.com', '7C', 5, 103, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (308, 'Vinny', 'Darcey', '1188738241', 'vdarcey8j@yahoo.com', '24F', 6, 41, '2.26');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (309, 'Borden', 'Sewart', '1185879357', 'bsewart8k@xinhuanet.com', '1B', 4, 78, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (310, 'Nester', 'Fletcher', '1194878410', 'nfletcher8l@woothemes.com', '8B', 9, 25, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (311, 'Tomkin', 'Toovey', '1124303581', 'ttoovey8m@t.co', '29A', 10, 82, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (312, 'Garrard', 'Fawcus', '1176162227', 'gfawcus8n@github.com', '9F', 4, 74, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (313, 'Kingston', 'Sharply', '1118147959', 'ksharply8o@list-manage.com', '17D', 6, 27, '2.38');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (314, 'Zed', 'L''oiseau', '1179268941', 'zloiseau8p@ustream.tv', '28C', 5, 83, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (315, 'Worden', 'Phillipps', '1131224341', 'wphillipps8q@craigslist.org', '13D', 3, 66, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (316, 'Goldy', 'Leveridge', '1103375423', 'gleveridge8r@apache.org', '5C', 6, 47, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (317, 'Sidney', 'Rubertelli', '1134629003', 'srubertelli8s@comcast.net', '24E', 9, 44, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (318, 'Ethel', 'Elvidge', '1169675026', 'eelvidge8t@newyorker.com', '29C', 2, 87, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (319, 'Gabrielle', 'Sleightholme', '1124444203', 'gsleightholme8u@jugem.jp', '2F', 3, 26, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (320, 'Sarajane', 'Press', '1161552271', 'spress8v@livejournal.com', '5B', 3, 59, '1.91');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (321, 'Erna', 'Chazelle', '1157924873', 'echazelle8w@baidu.com', '9D', 2, 64, '1.88');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (322, 'Ianthe', 'Nickerson', '1192274071', 'inickerson8x@webnode.com', '24C', 8, 7, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (323, 'Griffith', 'De Gregoli', '1106669195', 'gdegregoli8y@jugem.jp', '21B', 2, 25, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (324, 'Morganne', 'Hansbury', '1160809560', 'mhansbury8z@tuttocitta.it', '7E', 6, 50, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (325, 'Sawyere', 'Cheer', '1131717623', 'scheer90@opera.com', '25C', 10, 93, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (326, 'Arlena', 'Leaton', '1135816618', 'aleaton91@jalbum.net', '6F', 4, 67, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (327, 'Maurene', 'Torry', '1193619047', 'mtorry92@live.com', '5F', 10, 115, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (328, 'Marlie', 'Clarae', '1103029190', 'mclarae93@census.gov', '21E', 4, 46, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (329, 'Carny', 'Clemente', '1174374345', 'cclemente94@vistaprint.com', '22E', 2, 107, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (330, 'Wheeler', 'Shevlane', '1105570508', 'wshevlane95@g.co', '1D', 10, 14, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (331, 'Aila', 'Lockyear', '1129214294', 'alockyear96@phpbb.com', '17E', 2, 103, '1.85');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (332, 'Sonni', 'Jepps', '1101495980', 'sjepps97@timesonline.co.uk', '15B', 1, 12, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (333, 'Lannie', 'Ingham', '1139304329', 'lingham98@mtv.com', '12A', 4, 32, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (334, 'Rosemaria', 'Aubri', '1164057930', 'raubri99@moonfruit.com', '2E', 2, 98, '1.55');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (335, 'Breanne', 'Sarch', '1195216729', 'bsarch9a@hexun.com', '25D', 6, 99, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (336, 'Nelle', 'Luto', '1120618892', 'nluto9b@mit.edu', '18D', 3, 37, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (337, 'Cristian', 'Petroff', '1171519335', 'cpetroff9c@utexas.edu', '5D', 2, 1, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (338, 'Caren', 'Lattey', '1132255544', 'clattey9d@networkadvertising.org', '1C', 2, 1, '2.19');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (339, 'Smitty', 'Askaw', '1189352766', 'saskaw9e@amazonaws.com', '25D', 9, 1, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (340, 'Sophey', 'Vamplers', '1176040792', 'svamplers9f@who.int', '4E', 1, 2, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (341, 'Clarey', 'Cuberley', '1108020511', 'ccuberley9g@army.mil', '3A', 5, 57, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (342, 'De witt', 'Sturges', '1121168435', 'dsturges9h@ucla.edu', '26A', 6, 66, '1.01');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (343, 'Dion', 'Kroger', '1104628683', 'dkroger9i@pen.io', '24B', 3, 119, '1.46');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (344, 'Johanna', 'Snare', '1171316748', 'jsnare9j@yahoo.co.jp', '4B', 9, 4, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (345, 'Tony', 'Worthy', '1193688006', 'tworthy9k@mail.ru', '5A', 1, 11, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (346, 'Adrianna', 'Ardron', '1123174553', 'aardron9l@bing.com', '1E', 3, 102, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (347, 'Konstanze', 'McQuilliam', '1165326205', 'kmcquilliam9m@vimeo.com', '8F', 1, 81, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (348, 'Bobine', 'Tunuy', '1143433704', 'btunuy9n@pbs.org', '7D', 3, 117, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (349, 'Danyelle', 'Lye', '1140535580', 'dlye9o@google.de', '6F', 2, 95, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (350, 'Alayne', 'McCrann', '1198301176', 'amccrann9p@prlog.org', '22A', 3, 35, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (351, 'Faydra', 'Lowton', '1187730961', 'flowton9q@weibo.com', '9E', 9, 112, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (352, 'Tadio', 'Bendon', '1196518699', 'tbendon9r@noaa.gov', '6A', 5, 38, '2.48');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (353, 'Dre', 'Airs', '1168885759', 'dairs9s@jigsy.com', '8C', 9, 47, '1.27');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (354, 'Joyann', 'Yukhov', '1147295433', 'jyukhov9t@devhub.com', '17E', 3, 110, '2.41');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (355, 'Dynah', 'Grammer', '1105366870', 'dgrammer9u@posterous.com', '25E', 3, 12, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (356, 'Vitoria', 'Everal', '1142532189', 'veveral9v@psu.edu', '9D', 9, 49, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (357, 'Kimball', 'Parkin', '1192111728', 'kparkin9w@google.co.jp', '21D', 7, 118, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (358, 'Geno', 'Tinson', '1176728810', 'gtinson9x@t.co', '26D', 3, 24, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (359, 'Janis', 'Bramsom', '1109818768', 'jbramsom9y@tinyurl.com', '5B', 4, 42, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (360, 'Jesselyn', 'Tembey', '1176780916', 'jtembey9z@unesco.org', '13A', 10, 41, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (361, 'Alfy', 'Facher', '1106820580', 'afachera0@rediff.com', '2A', 5, 28, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (362, 'Randal', 'Greaterex', '1131288631', 'rgreaterexa1@rakuten.co.jp', '27E', 7, 17, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (363, 'Kerrin', 'Armour', '1109890473', 'karmoura2@gmpg.org', '14C', 1, 50, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (364, 'Austin', 'Kittredge', '1129862287', 'akittredgea3@delicious.com', '29C', 10, 80, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (365, 'Reidar', 'Scholfield', '1198266622', 'rscholfielda4@51.la', '15A', 9, 30, '2.21');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (366, 'Prince', 'Strathe', '1118802900', 'pstrathea5@oracle.com', '22B', 10, 67, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (367, 'Boigie', 'Cockshutt', '1159723901', 'bcockshutta6@nbcnews.com', '19D', 4, 29, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (368, 'Eb', 'Ritson', '1146069360', 'eritsona7@usa.gov', '7B', 9, 112, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (369, 'Dugald', 'Lauchlan', '1165321285', 'dlauchlana8@chron.com', '19D', 4, 96, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (370, 'Shay', 'Hoodspeth', '1153204984', 'shoodspetha9@dyndns.org', '2E', 9, 113, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (371, 'Carroll', 'Ianson', '1177591278', 'ciansonaa@alexa.com', '7E', 1, 63, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (372, 'Eugine', 'Moretto', '1103619994', 'emorettoab@berkeley.edu', '19C', 4, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (373, 'Betsy', 'Tink', '1110264088', 'btinkac@is.gd', '19A', 8, 35, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (374, 'Royal', 'Shankster', '1192528563', 'rshanksterad@biglobe.ne.jp', '1C', 10, 80, '1.52');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (375, 'Rosita', 'O''Heaney', '1181513924', 'roheaneyae@drupal.org', '5A', 7, 14, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (376, 'Adele', 'Larkin', '1147260504', 'alarkinaf@mapy.cz', '1A', 10, 96, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (377, 'Winfield', 'Winders', '1155923679', 'wwindersag@engadget.com', '5F', 6, 110, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (378, 'Vonni', 'McRae', '1174321410', 'vmcraeah@alibaba.com', '19D', 10, 1, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (379, 'Vikky', 'Joret', '1133344006', 'vjoretai@webeden.co.uk', '19A', 3, 53, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (380, 'Jessie', 'Garatty', '1125636816', 'jgarattyaj@wp.com', '16B', 4, 31, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (381, 'Nelle', 'McMurraya', '1117863965', 'nmcmurrayaak@chicagotribune.com', '6F', 8, 3, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (382, 'Cathie', 'Crighton', '1194144621', 'ccrightonal@unicef.org', '29D', 8, 53, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (383, 'Fraser', 'Foale', '1188819352', 'ffoaleam@github.com', '23F', 10, 59, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (384, 'Calida', 'Surplice', '1172606578', 'csurplicean@istockphoto.com', '1C', 7, 73, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (385, 'Abrahan', 'Lushey', '1115906673', 'alusheyao@gnu.org', '1B', 6, 33, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (386, 'Beth', 'Ashbolt', '1130288040', 'bashboltap@canalblog.com', '25B', 2, 82, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (387, 'Hewett', 'Fallis', '1156398328', 'hfallisaq@last.fm', '5B', 7, 75, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (388, 'Elmore', 'Shwalbe', '1186010999', 'eshwalbear@skype.com', '12F', 9, 43, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (389, 'Kaia', 'Roe', '1117887631', 'kroeas@php.net', '28E', 8, 33, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (390, 'Burg', 'Mountstephen', '1100844958', 'bmountstephenat@tuttocitta.it', '19C', 9, 115, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (391, 'Jacquie', 'Dolton', '1137165112', 'jdoltonau@jimdo.com', '15C', 9, 21, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (392, 'Ruthe', 'Mannion', '1103021872', 'rmannionav@wufoo.com', '17C', 4, 84, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (393, 'Jonah', 'Pantry', '1149218678', 'jpantryaw@google.ca', '18B', 6, 37, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (394, 'Lauri', 'Deason', '1182322490', 'ldeasonax@t.co', '16B', 5, 81, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (395, 'Rhoda', 'Vernalls', '1185884504', 'rvernallsay@ftc.gov', '1A', 9, 117, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (396, 'Kizzee', 'Tommen', '1108383309', 'ktommenaz@earthlink.net', '2A', 5, 33, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (397, 'Yehudi', 'Wrettum', '1178359514', 'ywrettumb0@bizjournals.com', '5C', 7, 92, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (398, 'Josepha', 'Edmondson', '1108396122', 'jedmondsonb1@joomla.org', '4A', 2, 81, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (399, 'Jennica', 'McNirlan', '1147889180', 'jmcnirlanb2@mail.ru', '27A', 2, 36, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (400, 'Paddy', 'Seamons', '1195297254', 'pseamonsb3@adobe.com', '1D', 3, 75, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (401, 'Edan', 'Pidgeley', '1120893332', 'epidgeleyb4@telegraph.co.uk', '4C', 1, 61, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (402, 'Tiffie', 'Robbie', '1140857720', 'trobbieb5@wikimedia.org', '3F', 1, 69, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (403, 'Josiah', 'Matherson', '1134277960', 'jmathersonb6@seattletimes.com', '2A', 2, 61, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (404, 'Tove', 'Skitt', '1134760422', 'tskittb7@wordpress.org', '8A', 6, 99, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (405, 'Ninnetta', 'Planque', '1105163915', 'nplanqueb8@icio.us', '16B', 2, 77, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (406, 'Bennett', 'Lange', '1126161024', 'blangeb9@smh.com.au', '1E', 10, 8, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (407, 'Seumas', 'Chazelle', '1132343169', 'schazelleba@dmoz.org', '2C', 8, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (408, 'Ara', 'Brookzie', '1185616203', 'abrookziebb@is.gd', '1C', 9, 44, '2.28');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (409, 'Marcos', 'Cable', '1121748268', 'mcablebc@loc.gov', '26A', 2, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (410, 'Irv', 'Baverstock', '1106707893', 'ibaverstockbd@w3.org', '12B', 4, 66, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (411, 'Ileana', 'Beazer', '1133391596', 'ibeazerbe@addthis.com', '25C', 10, 110, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (412, 'Reade', 'Lemoir', '1187603468', 'rlemoirbf@businessweek.com', '1C', 1, 111, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (413, 'Ad', 'Valance', '1108209195', 'avalancebg@google.pl', '11D', 7, 66, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (414, 'Hamid', 'Eagles', '1181131091', 'heaglesbh@bigcartel.com', '24B', 5, 10, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (415, 'Mab', 'Edward', '1165276695', 'medwardbi@java.com', '26A', 2, 36, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (416, 'Tudor', 'Pachta', '1132047122', 'tpachtabj@phoca.cz', '9C', 1, 14, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (417, 'Crissy', 'Martins', '1105818327', 'cmartinsbk@statcounter.com', '5E', 10, 28, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (418, 'Teresina', 'Verecker', '1195925603', 'tvereckerbl@craigslist.org', '12F', 9, 12, '1.68');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (419, 'Urbanus', 'Hillin', '1101094405', 'uhillinbm@freewebs.com', '1E', 6, 78, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (420, 'Kayle', 'Trotter', '1186251160', 'ktrotterbn@4shared.com', '27A', 5, 114, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (421, 'Shepherd', 'Menilove', '1123925200', 'smenilovebo@arizona.edu', '22B', 1, 86, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (422, 'Edgardo', 'Ruse', '1136147287', 'erusebp@unc.edu', '25C', 2, 65, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (423, 'Blancha', 'Meenan', '1142052988', 'bmeenanbq@reverbnation.com', '11F', 7, 93, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (424, 'Francesca', 'Mansuer', '1103483203', 'fmansuerbr@gizmodo.com', '8D', 6, 115, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (425, 'Stanford', 'Mendez', '1170833554', 'smendezbs@kickstarter.com', '27F', 5, 58, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (426, 'Kynthia', 'McLevie', '1160618958', 'kmcleviebt@who.int', '5A', 5, 30, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (427, 'Viv', 'Sharrier', '1134988156', 'vsharrierbu@bandcamp.com', '7A', 4, 88, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (428, 'Ambrosi', 'McEniry', '1180553891', 'amcenirybv@nifty.com', '7F', 10, 54, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (429, 'Axel', 'Mulvaney', '1181818425', 'amulvaneybw@miitbeian.gov.cn', '19B', 4, 94, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (430, 'Roby', 'Beacon', '1176194213', 'rbeaconbx@youtu.be', '28A', 10, 7, '1.35');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (431, 'Maureen', 'Childers', '1125802428', 'mchildersby@mtv.com', '18E', 8, 79, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (432, 'Harlan', 'Barosch', '1131446180', 'hbaroschbz@apple.com', '7D', 3, 115, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (433, 'Windy', 'Batchelder', '1117699815', 'wbatchelderc0@wired.com', '29F', 4, 109, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (434, 'Cobb', 'Abadam', '1117827114', 'cabadamc1@webs.com', '4C', 7, 99, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (435, 'Krystle', 'Peile', '1102855083', 'kpeilec2@nba.com', '17D', 5, 15, '1.99');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (436, 'Helaine', 'Tinson', '1178254060', 'htinsonc3@ustream.tv', '26C', 5, 6, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (437, 'Guglielma', 'Adelberg', '1106034864', 'gadelbergc4@scribd.com', '22B', 7, 28, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (438, 'Skipp', 'Garces', '1143058700', 'sgarcesc5@nbcnews.com', '5B', 4, 19, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (439, 'Karyn', 'Feldstein', '1127667790', 'kfeldsteinc6@shop-pro.jp', '14D', 10, 61, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (440, 'Ariel', 'Musico', '1194218412', 'amusicoc7@mac.com', '23F', 4, 108, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (441, 'Odey', 'Kenwood', '1183532954', 'okenwoodc8@slideshare.net', '27A', 2, 77, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (442, 'Barrie', 'Tomek', '1175227006', 'btomekc9@nbcnews.com', '7C', 1, 117, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (443, 'Charlean', 'Everwin', '1191481338', 'ceverwinca@nbcnews.com', '2D', 10, 119, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (444, 'Elwin', 'Aggio', '1194651516', 'eaggiocb@msu.edu', '11E', 6, 26, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (445, 'Corbin', 'Spurdle', '1141283848', 'cspurdlecc@hibu.com', '2B', 1, 6, '1.49');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (446, 'Jilly', 'Shemming', '1104755318', 'jshemmingcd@ifeng.com', '28C', 4, 65, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (447, 'Carlene', 'Peppett', '1135474818', 'cpeppettce@webs.com', '6F', 8, 26, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (448, 'Griffy', 'Lynch', '1120515636', 'glynchcf@discovery.com', '14B', 6, 56, '1.44');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (449, 'Elbert', 'Eckley', '1114425039', 'eeckleycg@sogou.com', '7C', 8, 6, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (450, 'Dorie', 'Braddick', '1180382334', 'dbraddickch@engadget.com', '2A', 3, 79, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (451, 'Frieda', 'Miskimmon', '1122953494', 'fmiskimmonci@nba.com', '1D', 5, 15, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (452, 'Felice', 'Brotherhood', '1136316753', 'fbrotherhoodcj@bloglovin.com', '3B', 6, 30, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (453, 'Klaus', 'Francescozzi', '1148059523', 'kfrancescozzick@tuttocitta.it', '27F', 9, 77, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (454, 'Ernie', 'Scotter', '1180699161', 'escottercl@google.ru', '28D', 6, 89, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (455, 'Ariana', 'Gaylord', '1176416882', 'agaylordcm@sohu.com', '9A', 7, 10, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (456, 'Shurlock', 'Luipold', '1184440000', 'sluipoldcn@sitemeter.com', '5D', 6, 105, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (457, 'Ibrahim', 'Airds', '1168284503', 'iairdsco@w3.org', '11B', 2, 5, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (458, 'Cindee', 'Elderidge', '1115709899', 'celderidgecp@t.co', '6D', 5, 29, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (459, 'Genevra', 'Manklow', '1175966820', 'gmanklowcq@privacy.gov.au', '5B', 2, 73, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (460, 'Gil', 'Cossar', '1104073283', 'gcossarcr@wikispaces.com', '5F', 8, 77, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (461, 'Gui', 'Eayrs', '1120260030', 'geayrscs@linkedin.com', '1E', 6, 42, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (462, 'Neal', 'Clink', '1182141875', 'nclinkct@opensource.org', '6E', 10, 64, '1.19');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (463, 'Almeta', 'Woolens', '1150811787', 'awoolenscu@nasa.gov', '14E', 6, 22, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (464, 'Daune', 'Rope', '1142879475', 'dropecv@geocities.com', '4A', 10, 111, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (465, 'Farleigh', 'Ponter', '1139194117', 'fpontercw@google.de', '17E', 1, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (466, 'Lucie', 'Queyeiro', '1102500323', 'lqueyeirocx@slashdot.org', '12B', 2, 33, '2.11');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (467, 'Roarke', 'Haslegrave', '1189515937', 'rhaslegravecy@forbes.com', '6D', 2, 108, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (468, 'Valerie', 'Cadlock', '1128055166', 'vcadlockcz@buzzfeed.com', '29C', 1, 37, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (469, 'Giulio', 'Benezeit', '1190157421', 'gbenezeitd0@4shared.com', '16C', 5, 87, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (470, 'Halsy', 'Puckinghorne', '1156941743', 'hpuckinghorned1@baidu.com', '23D', 8, 45, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (471, 'Phaedra', 'Guntrip', '1128100394', 'pguntripd2@icq.com', '17B', 8, 42, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (472, 'Shannon', 'Higbin', '1185986395', 'shigbind3@t-online.de', '26E', 10, 65, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (473, 'Joyous', 'Sifflett', '1162998461', 'jsifflettd4@macromedia.com', '22C', 4, 117, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (474, 'Franklyn', 'Jewess', '1139956860', 'fjewessd5@theatlantic.com', '4B', 3, 110, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (475, 'Bethanne', 'Jillard', '1159732823', 'bjillardd6@va.gov', '22E', 1, 41, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (476, 'Kelley', 'Josefer', '1162899243', 'kjoseferd7@dropbox.com', '21A', 6, 49, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (477, 'Whitaker', 'Sappson', '1112229808', 'wsappsond8@sohu.com', '24C', 4, 3, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (478, 'Natty', 'Lockier', '1172854666', 'nlockierd9@bluehost.com', '6E', 2, 71, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (479, 'Myrtice', 'Biford', '1125761718', 'mbifordda@bigcartel.com', '27B', 2, 93, '1.50');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (480, 'Allianora', 'Leas', '1111375338', 'aleasdb@about.com', '7F', 8, 89, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (481, 'Shurlocke', 'Chattell', '1166725092', 'schattelldc@wisc.edu', '29F', 8, 35, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (482, 'Babbette', 'MacCafferky', '1121760980', 'bmaccafferkydd@mediafire.com', '8B', 9, 2, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (483, 'Lorne', 'Armor', '1183282562', 'larmorde@techcrunch.com', '6B', 7, 96, '2');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (484, 'Ruprecht', 'Chasmor', '1109357593', 'rchasmordf@hugedomains.com', '5C', 6, 80, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (485, 'Jaquelin', 'Solano', '1105379420', 'jsolanodg@mozilla.com', '19E', 5, 57, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (486, 'Paulina', 'Suatt', '1193766380', 'psuattdh@ycombinator.com', '1A', 10, 83, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (487, 'Dredi', 'Glasheen', '1153627436', 'dglasheendi@bizjournals.com', '11C', 2, 46, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (488, 'Elwyn', 'Boxhall', '1116249370', 'eboxhalldj@fda.gov', '21D', 1, 10, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (489, 'Pauline', 'McCosker', '1147034049', 'pmccoskerdk@homestead.com', '18A', 3, 55, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (490, 'Mellicent', 'Claringbold', '1129553855', 'mclaringbolddl@time.com', '6D', 5, 63, '2.04');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (491, 'Damian', 'Besemer', '1104863511', 'dbesemerdm@slate.com', '25A', 9, 71, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (492, 'Ephrem', 'd'' Eye', '1177081557', 'edeyedn@google.ca', '28C', 2, 54, '1.60');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (493, 'Sarita', 'Vidineev', '1101753392', 'svidineevdo@sourceforge.net', '8E', 1, 116, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (494, 'Jayson', 'Poleye', '1105384905', 'jpoleyedp@pagesperso-orange.fr', '16B', 10, 92, '1.57');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (495, 'Ferdy', 'Mower', '1132817754', 'fmowerdq@google.com', '9D', 4, 60, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (496, 'Kimmy', 'Glasebrook', '1199451633', 'kglasebrookdr@nih.gov', '4B', 7, 43, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (497, 'Adair', 'Coull', '1144372963', 'acoullds@virginia.edu', '2B', 3, 27, '2.04');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (498, 'Antonius', 'Traut', '1138130219', 'atrautdt@tripadvisor.com', '15D', 1, 33, '1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (499, 'Matty', 'McKiernan', '1115596200', 'mmckiernandu@house.gov', '6F', 3, 21, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (500, 'Stesha', 'Downgate', '1107727301', 'sdowngatedv@microsoft.com', '7B', 10, 101, '2.43');
-- Insertar h_Gastos (500)
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (1, 2, 7, '729774.96', '2022-06-20', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (2, 4, 6, '1879593.1', '2022-02-01', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (3, 4, 1, '543744', '2024-03-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (4, 7, 8, '2163112', '2023-09-13', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (5, 3, 9, '915056.88', '2023-03-31', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (6, 8, 2, '247125', '2021-12-15', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (7, 2, 6, '358497', '2022-03-07', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (8, 7, 4, '1169132.8', '2022-03-11', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (9, 8, 7, '637924.9', '2023-07-11', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (10, 6, 1, '554135.96', '2023-07-16', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (11, 6, 6, '1870370', '2022-03-29', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (12, 6, 3, '1981613.04', '2022-01-28', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (13, 4, 3, '2292480.1', '2022-11-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (14, 2, 8, '488016.1', '2023-04-01', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (15, 6, 3, '351211.79', '2023-03-12', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (16, 11, 3, '2147786.9', '2023-12-30', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (17, 12, 3, '984836.38', '2024-06-08', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (18, 5, 1, '325134.90', '2024-01-04', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (19, 11, 10, '396996', '2023-02-24', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (20, 3, 5, '1824449', '2022-07-29', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (21, 8, 3, '767573.9', '2022-05-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (22, 6, 9, '597377.6', '2022-05-07', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (23, 7, 6, '2907242.3', '2024-03-20', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (24, 4, 10, '374398.61', '2023-10-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (25, 9, 8, '2628725.47', '2023-06-14', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (26, 2, 8, '570163.7', '2022-10-05', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (27, 8, 8, '2219648.1', '2024-04-22', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (28, 2, 9, '247517.48', '2022-01-09', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (29, 8, 7, '863584.05', '2023-09-13', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (30, 6, 5, '243717', '2023-04-16', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (31, 5, 2, '1756873.0', '2022-01-20', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (32, 2, 9, '716937', '2022-02-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (33, 3, 2, '2842756', '2022-06-24', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (34, 5, 6, '797703', '2023-10-13', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (35, 12, 4, '2219714.60', '2024-04-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (36, 3, 5, '1107907.4', '2023-11-16', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (37, 1, 9, '562005', '2023-02-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (38, 4, 5, '1173830.4', '2023-04-06', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (39, 1, 8, '112976', '2022-10-14', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (40, 10, 4, '604823.74', '2023-09-28', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (41, 8, 5, '899051', '2022-09-15', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (42, 9, 3, '1139940', '2024-03-10', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (43, 7, 7, '2297643.4', '2022-07-23', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (44, 3, 1, '1548973', '2022-03-30', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (45, 2, 6, '2832436.86', '2023-09-12', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (46, 3, 9, '217567', '2022-03-02', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (47, 5, 2, '810349', '2022-11-01', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (48, 2, 4, '2512182.84', '2024-02-27', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (49, 3, 5, '1467218.9', '2024-05-02', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (50, 11, 8, '2782821.5', '2024-06-05', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (51, 7, 4, '449146', '2024-05-09', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (52, 9, 10, '728668.89', '2023-05-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (53, 3, 3, '2970289.74', '2022-03-29', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (54, 3, 10, '2378612', '2023-02-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (55, 1, 4, '732491', '2023-08-31', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (56, 8, 9, '2841015.12', '2022-07-20', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (57, 6, 3, '1591875', '2022-06-13', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (58, 1, 5, '2681069', '2023-08-10', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (59, 1, 1, '1804820.38', '2023-04-23', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (60, 4, 6, '1388500.21', '2022-03-26', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (61, 3, 7, '2704878.8', '2024-02-12', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (62, 8, 5, '2120930', '2023-05-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (63, 1, 4, '762086.5', '2024-01-28', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (64, 4, 1, '398900.0', '2023-03-14', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (65, 1, 4, '658649', '2022-11-05', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (66, 1, 2, '2124583.2', '2023-11-07', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (67, 12, 8, '829573', '2023-05-20', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (68, 5, 6, '1185283', '2022-07-26', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (69, 1, 1, '272601', '2022-03-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (70, 7, 4, '2446774.96', '2023-07-14', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (71, 4, 1, '2353985', '2023-06-16', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (72, 4, 1, '477385.6', '2022-11-28', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (73, 2, 2, '629998', '2022-12-24', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (74, 5, 3, '749176', '2023-09-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (75, 6, 5, '2297498.6', '2022-06-21', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (76, 11, 8, '449477', '2023-09-16', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (77, 5, 4, '1681689.33', '2022-04-30', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (78, 1, 10, '1301745.9', '2023-03-29', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (79, 12, 8, '2311594', '2023-06-25', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (80, 6, 10, '2849291', '2023-08-05', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (81, 6, 5, '2609074', '2024-05-11', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (82, 10, 6, '689772.47', '2023-08-21', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (83, 1, 1, '919047', '2022-04-06', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (84, 7, 4, '501375.48', '2023-08-30', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (85, 5, 1, '1901240.40', '2022-12-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (86, 1, 10, '254198.1', '2022-12-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (87, 6, 4, '176228.4', '2024-04-22', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (88, 8, 4, '927702.0', '2022-09-14', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (89, 8, 10, '1580783.97', '2023-03-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (90, 1, 1, '1580847.80', '2024-03-02', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (91, 3, 1, '1148346.2', '2022-05-02', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (92, 7, 1, '879102.5', '2023-01-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (93, 9, 5, '1737198.3', '2022-11-04', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (94, 7, 4, '843852', '2023-12-11', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (95, 8, 1, '547433.19', '2022-01-31', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (96, 1, 4, '541039.17', '2024-03-05', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (97, 12, 7, '471125.8', '2022-09-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (98, 5, 8, '1438249', '2022-12-31', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (99, 5, 7, '490093.62', '2024-02-26', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (100, 6, 1, '1386852', '2022-11-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (101, 4, 7, '1211534.97', '2022-11-23', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (102, 1, 9, '544586', '2024-02-23', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (103, 12, 7, '2747275.61', '2023-04-20', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (104, 2, 9, '2844086.27', '2022-07-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (105, 8, 2, '228213', '2023-06-07', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (106, 8, 1, '1591999', '2022-07-21', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (107, 4, 9, '1114443', '2024-06-04', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (108, 9, 5, '2921196.3', '2022-10-18', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (109, 8, 8, '2792243', '2022-07-18', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (110, 3, 6, '2906612', '2022-02-01', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (111, 4, 3, '599022.90', '2023-09-06', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (112, 12, 9, '499516.45', '2022-09-20', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (113, 7, 8, '2589315.9', '2022-02-13', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (114, 4, 9, '2583236', '2024-06-18', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (115, 6, 1, '975355', '2024-03-24', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (116, 6, 6, '1437548', '2023-09-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (117, 9, 8, '1723296', '2023-01-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (118, 1, 2, '454340.9', '2024-06-08', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (119, 6, 5, '874132.82', '2021-12-23', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (120, 8, 5, '926768.5', '2022-12-29', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (121, 6, 2, '1826578.26', '2022-03-08', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (122, 9, 2, '2592104.52', '2024-04-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (123, 9, 6, '2425211', '2023-01-07', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (124, 10, 7, '2147831.84', '2023-09-04', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (125, 6, 4, '2797126.60', '2022-12-04', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (126, 6, 5, '2357352', '2022-04-18', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (127, 3, 4, '1658305.6', '2023-08-11', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (128, 10, 6, '2563499.5', '2024-05-30', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (129, 1, 9, '541175.3', '2022-04-20', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (130, 9, 6, '967053.1', '2023-05-13', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (131, 4, 2, '567529.03', '2023-05-04', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (132, 1, 9, '419939', '2023-03-20', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (133, 5, 6, '831934', '2022-02-08', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (134, 5, 3, '929961.0', '2022-07-29', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (135, 4, 7, '373815', '2024-04-05', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (136, 2, 9, '100316.7', '2022-09-04', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (137, 10, 5, '1532167', '2023-01-09', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (138, 7, 5, '1172555', '2022-02-03', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (139, 5, 1, '1785455', '2022-01-03', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (140, 2, 2, '2332973.74', '2023-04-08', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (141, 10, 10, '1607675.80', '2024-03-03', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (142, 7, 4, '764322.08', '2024-01-28', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (143, 7, 2, '2614284', '2022-11-17', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (144, 6, 5, '2349881', '2022-12-26', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (145, 2, 2, '799662.5', '2021-12-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (146, 4, 6, '874324', '2023-03-27', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (147, 8, 10, '408296', '2024-03-07', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (148, 1, 7, '1555900.91', '2024-03-04', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (149, 4, 9, '1374403', '2022-10-07', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (150, 9, 7, '690164.78', '2024-05-15', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (151, 4, 7, '663298', '2023-01-20', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (152, 7, 9, '212530.37', '2024-05-22', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (153, 2, 9, '1251098', '2024-01-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (154, 5, 10, '964269.92', '2024-02-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (155, 10, 8, '651917', '2022-10-07', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (156, 5, 10, '1149216', '2022-04-14', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (157, 11, 5, '696185.87', '2024-02-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (158, 8, 10, '595654', '2024-06-10', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (159, 5, 9, '1428248', '2022-05-15', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (160, 4, 3, '2968722.6', '2022-10-03', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (161, 7, 10, '886463', '2024-04-22', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (162, 8, 3, '453080.16', '2022-12-29', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (163, 12, 3, '2216645.8', '2022-07-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (164, 8, 9, '407140.66', '2022-06-21', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (165, 6, 6, '323020.16', '2022-04-23', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (166, 12, 4, '2180285.6', '2022-07-05', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (167, 11, 5, '466485.1', '2023-11-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (168, 4, 4, '2304131', '2023-10-01', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (169, 11, 6, '637377.83', '2023-02-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (170, 2, 1, '2685863.9', '2023-04-12', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (171, 10, 9, '857974', '2023-06-13', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (172, 10, 5, '1742405.07', '2023-03-30', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (173, 7, 9, '566122', '2023-02-04', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (174, 5, 6, '2312481.0', '2023-09-29', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (175, 9, 3, '747150.8', '2023-04-13', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (176, 1, 4, '1723583', '2022-09-18', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (177, 4, 3, '2912878.4', '2023-01-19', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (178, 8, 8, '2789107.79', '2023-09-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (179, 12, 5, '2133120.30', '2024-06-29', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (180, 4, 10, '1457453', '2023-12-22', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (181, 8, 10, '2536498.97', '2023-12-23', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (182, 4, 2, '1945108.8', '2022-10-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (183, 9, 7, '2252420.88', '2022-08-29', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (184, 1, 6, '382430.9', '2022-05-11', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (185, 3, 5, '2200621.8', '2023-09-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (186, 11, 7, '2174342.3', '2023-03-27', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (187, 12, 2, '1999827', '2023-11-30', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (188, 3, 1, '370582.79', '2023-09-11', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (189, 11, 1, '142203', '2022-05-04', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (190, 9, 3, '491943.4', '2022-01-06', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (191, 1, 4, '528622.2', '2023-09-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (192, 3, 10, '935419.1', '2022-04-25', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (193, 1, 1, '2920967.18', '2024-04-22', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (194, 5, 6, '2470624', '2024-06-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (195, 3, 4, '887097.6', '2023-09-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (196, 4, 9, '666101.7', '2023-07-02', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (197, 11, 3, '1387252.26', '2022-05-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (198, 7, 5, '885632.30', '2022-01-21', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (199, 8, 1, '2898525', '2023-06-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (200, 1, 3, '320475.82', '2022-06-11', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (201, 10, 10, '1479412', '2023-07-29', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (202, 4, 8, '377557', '2022-11-03', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (203, 8, 7, '2481422', '2023-02-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (204, 12, 7, '2339146.5', '2023-07-06', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (205, 6, 1, '278747', '2022-01-12', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (206, 2, 3, '568936', '2022-10-22', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (207, 12, 3, '271889', '2022-09-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (208, 12, 3, '676589', '2022-01-14', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (209, 12, 10, '791510', '2022-09-04', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (210, 10, 6, '667983', '2022-11-02', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (211, 8, 1, '1293842.2', '2022-06-23', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (212, 11, 5, '2999745', '2022-06-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (213, 9, 10, '512996', '2022-04-20', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (214, 10, 10, '448651', '2023-11-14', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (215, 11, 2, '150711.37', '2022-04-03', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (216, 6, 9, '2347941', '2022-09-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (217, 4, 5, '881305', '2023-03-22', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (218, 12, 8, '694267.58', '2024-01-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (219, 4, 6, '1721865.52', '2023-01-13', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (220, 5, 4, '833560.6', '2023-04-22', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (221, 3, 9, '861142.46', '2023-05-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (222, 10, 4, '1741867', '2023-07-09', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (223, 8, 8, '370710', '2024-05-15', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (224, 3, 9, '466422.7', '2024-01-24', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (225, 5, 1, '485817', '2023-05-01', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (226, 11, 6, '1845567', '2022-12-10', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (227, 8, 1, '562909', '2023-04-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (228, 7, 8, '105200.84', '2022-01-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (229, 5, 8, '279666', '2023-08-08', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (230, 11, 9, '443280.8', '2022-04-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (231, 9, 7, '205307', '2022-10-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (232, 3, 3, '2510618.26', '2024-03-13', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (233, 2, 4, '2672879', '2022-04-04', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (234, 10, 5, '2366235', '2024-05-03', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (235, 2, 10, '412662', '2024-01-02', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (236, 1, 3, '2889351', '2023-10-16', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (237, 11, 3, '1828914', '2021-12-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (238, 12, 4, '2246624.4', '2022-04-12', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (239, 1, 5, '955845', '2022-02-19', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (240, 2, 8, '568938.81', '2024-04-16', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (241, 11, 4, '1135591.5', '2022-04-07', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (242, 8, 5, '858747', '2023-05-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (243, 2, 4, '1644100.72', '2023-08-26', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (244, 1, 4, '2995740', '2022-07-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (245, 5, 4, '1990208.79', '2024-01-22', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (246, 10, 10, '245234', '2023-11-10', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (247, 7, 6, '2758731', '2022-12-13', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (248, 8, 3, '2650690.72', '2023-07-14', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (249, 10, 5, '1121934.23', '2022-07-27', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (250, 4, 4, '1629480.7', '2023-02-12', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (251, 6, 9, '1197538.6', '2023-02-28', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (252, 8, 3, '798079', '2021-12-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (253, 4, 9, '1692246', '2023-07-27', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (254, 9, 1, '2269269.7', '2023-12-19', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (255, 7, 6, '2994277', '2023-03-07', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (256, 6, 10, '2382618.9', '2023-07-18', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (257, 5, 5, '240329.7', '2022-06-19', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (258, 9, 10, '782399', '2023-10-13', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (259, 2, 3, '303082', '2023-06-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (260, 5, 9, '968723.82', '2024-02-21', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (261, 7, 3, '2301189', '2022-01-23', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (262, 5, 9, '740998.1', '2023-09-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (263, 8, 7, '1390454', '2022-11-25', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (264, 2, 8, '2487560', '2023-06-27', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (265, 9, 10, '1936525.7', '2022-10-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (266, 11, 6, '670789.22', '2022-01-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (267, 7, 6, '2158585', '2023-01-05', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (268, 6, 10, '635438.56', '2022-10-16', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (269, 8, 10, '388382.8', '2023-03-31', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (270, 8, 6, '884265', '2023-12-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (271, 11, 3, '2158362', '2024-04-05', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (272, 8, 2, '142369.23', '2023-11-29', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (273, 6, 10, '977147', '2024-04-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (274, 11, 3, '849065', '2024-04-21', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (275, 2, 5, '1952316', '2023-07-05', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (276, 1, 6, '255943.8', '2022-06-12', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (277, 10, 2, '1201308', '2021-12-29', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (278, 10, 6, '1845589.50', '2023-02-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (279, 10, 5, '311230', '2024-02-17', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (280, 10, 10, '830200', '2022-03-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (281, 2, 6, '793144', '2022-09-12', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (282, 2, 1, '689711.38', '2024-05-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (283, 1, 1, '917289.1', '2022-11-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (284, 2, 6, '312741', '2024-05-07', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (285, 11, 8, '1259342.80', '2023-05-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (286, 4, 4, '2109484.1', '2023-09-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (287, 9, 8, '802892.7', '2023-04-08', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (288, 2, 10, '2396140', '2024-02-04', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (289, 9, 7, '1501649', '2023-10-26', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (290, 12, 8, '437269', '2024-05-14', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (291, 1, 3, '1336948', '2024-03-14', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (292, 5, 4, '2320331.49', '2023-06-09', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (293, 4, 1, '246954', '2022-06-15', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (294, 10, 10, '706305', '2023-11-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (295, 12, 7, '2313088.9', '2022-06-14', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (296, 11, 3, '140349', '2024-01-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (297, 9, 3, '2980661', '2024-05-19', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (298, 2, 2, '2202037', '2021-12-12', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (299, 9, 5, '585306', '2023-12-10', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (300, 6, 1, '2206594', '2023-04-09', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (301, 1, 5, '1819393.0', '2022-07-10', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (302, 7, 8, '2680955', '2024-04-04', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (303, 10, 1, '444462.64', '2022-10-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (304, 8, 1, '361007', '2023-11-06', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (305, 12, 6, '637780', '2022-05-27', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (306, 6, 7, '798443.05', '2022-03-25', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (307, 5, 8, '2397542.15', '2023-03-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (308, 4, 2, '475138', '2024-01-20', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (309, 11, 6, '399602.55', '2022-08-02', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (310, 9, 5, '1989782.6', '2022-09-19', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (311, 8, 7, '2440326.8', '2022-05-02', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (312, 11, 1, '1574993.35', '2022-10-17', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (313, 2, 4, '993026.9', '2024-06-11', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (314, 9, 8, '1272438.4', '2023-01-27', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (315, 7, 8, '211680.8', '2022-02-28', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (316, 12, 9, '2987903.85', '2022-04-28', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (317, 4, 6, '2343176.9', '2022-04-12', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (318, 1, 7, '751220', '2023-01-18', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (319, 1, 10, '723979', '2023-06-22', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (320, 4, 7, '1889520.13', '2022-06-22', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (321, 6, 9, '826772', '2024-01-11', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (322, 4, 8, '1104836.7', '2023-06-08', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (323, 4, 2, '837786.2', '2024-04-29', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (324, 11, 8, '639226.8', '2024-03-21', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (325, 2, 7, '237517.2', '2023-05-30', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (326, 12, 10, '766531.0', '2022-02-28', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (327, 2, 3, '1860861', '2024-06-20', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (328, 4, 1, '822547', '2023-09-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (329, 4, 9, '158588.3', '2024-05-15', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (330, 4, 4, '2463407.6', '2022-07-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (331, 8, 6, '1535138', '2023-04-11', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (332, 3, 9, '1803512.9', '2024-02-06', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (333, 5, 10, '2838712', '2022-04-12', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (334, 2, 6, '313546.2', '2024-01-26', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (335, 6, 5, '2909362.9', '2023-02-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (336, 6, 4, '2823134', '2022-11-25', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (337, 1, 6, '2799828', '2022-07-27', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (338, 10, 9, '752336.93', '2022-09-18', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (339, 9, 6, '652136.33', '2022-08-15', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (340, 1, 8, '2539223.73', '2022-01-14', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (341, 1, 7, '145871.5', '2023-11-13', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (342, 2, 10, '1781419.7', '2024-06-22', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (343, 1, 6, '933866', '2022-10-17', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (344, 12, 1, '1439261', '2022-09-03', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (345, 11, 1, '515241.14', '2024-05-01', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (346, 8, 7, '168745', '2022-08-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (347, 8, 1, '946211', '2021-12-26', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (348, 3, 8, '220148', '2023-02-25', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (349, 10, 7, '2349192.2', '2021-12-16', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (350, 7, 4, '1714601', '2023-11-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (351, 9, 4, '201399.79', '2023-05-02', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (352, 8, 1, '2295602', '2024-03-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (353, 2, 8, '306069', '2023-04-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (354, 1, 2, '520473', '2024-06-03', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (355, 9, 9, '139447', '2023-05-28', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (356, 1, 2, '568368.0', '2022-07-09', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (357, 4, 3, '654902', '2023-11-29', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (358, 3, 6, '897629', '2022-05-23', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (359, 1, 2, '1298568', '2022-09-21', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (360, 1, 6, '1103759.97', '2024-01-12', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (361, 7, 10, '967209.1', '2023-08-06', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (362, 6, 6, '219562', '2024-04-08', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (363, 6, 2, '1413490.7', '2022-12-03', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (364, 1, 5, '2216090', '2023-05-22', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (365, 10, 10, '590761.54', '2024-01-06', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (366, 3, 5, '131160', '2022-03-06', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (367, 4, 3, '1208733', '2022-12-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (368, 10, 4, '2865235', '2024-01-29', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (369, 7, 1, '2715409', '2023-12-20', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (370, 9, 4, '1105337', '2021-12-11', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (371, 12, 4, '2526829.1', '2022-09-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (372, 5, 7, '848996.40', '2022-05-14', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (373, 5, 8, '1194043', '2022-09-01', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (374, 12, 1, '987884', '2022-09-19', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (375, 2, 10, '721433.76', '2023-03-09', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (376, 5, 10, '974909.3', '2023-02-16', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (377, 5, 5, '369616', '2022-11-07', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (378, 11, 2, '1130090', '2023-04-25', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (379, 2, 3, '2409374', '2023-01-11', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (380, 9, 3, '711365.32', '2023-05-01', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (381, 1, 2, '770208', '2022-05-22', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (382, 8, 2, '1384619', '2024-02-02', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (383, 10, 10, '2599763.6', '2022-03-01', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (384, 8, 1, '596711', '2022-02-18', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (385, 5, 3, '2948918.25', '2023-06-24', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (386, 1, 2, '996883.1', '2023-11-03', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (387, 2, 1, '2760796', '2023-04-17', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (388, 9, 7, '293062', '2023-06-15', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (389, 1, 5, '1431679', '2021-12-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (390, 8, 1, '641406.2', '2023-08-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (391, 3, 3, '380740.7', '2023-11-11', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (392, 10, 9, '1727023.9', '2023-01-11', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (393, 7, 6, '228256.7', '2023-03-27', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (394, 10, 7, '222518.9', '2024-03-30', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (395, 11, 7, '2250776', '2023-03-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (396, 1, 1, '212027.83', '2023-09-29', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (397, 10, 9, '2461258.04', '2022-05-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (398, 2, 8, '1263436.21', '2022-04-10', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (399, 10, 10, '1285918.3', '2024-03-11', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (400, 3, 5, '2783512.25', '2022-06-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (401, 6, 4, '1845688.9', '2022-12-17', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (402, 8, 8, '774923.3', '2022-03-16', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (403, 11, 10, '983294', '2022-06-20', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (404, 3, 9, '329237', '2023-11-05', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (405, 9, 7, '241312.54', '2022-09-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (406, 10, 10, '1992062', '2022-10-10', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (407, 4, 1, '806415.8', '2022-11-22', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (408, 6, 3, '2191859', '2024-03-04', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (409, 5, 9, '309730.39', '2023-05-16', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (410, 5, 10, '199766', '2024-05-21', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (411, 2, 9, '2566489.9', '2022-03-30', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (412, 8, 1, '1310245.8', '2023-12-14', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (413, 1, 10, '207913.5', '2022-03-15', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (414, 5, 5, '333267.45', '2023-04-19', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (415, 4, 7, '2562835.9', '2024-01-18', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (416, 9, 1, '734575', '2023-01-31', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (417, 7, 9, '551399', '2023-07-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (418, 8, 10, '2299371.11', '2023-05-05', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (419, 10, 8, '2572549', '2024-03-18', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (420, 7, 8, '2554556', '2022-03-25', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (421, 3, 8, '1640462', '2023-09-21', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (422, 12, 10, '136038', '2022-04-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (423, 7, 10, '796325.9', '2023-09-02', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (424, 3, 1, '1352858', '2022-08-02', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (425, 11, 5, '971350.9', '2022-08-10', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (426, 4, 2, '2654401.4', '2022-06-12', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (427, 4, 5, '565624', '2024-02-04', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (428, 4, 10, '886504.2', '2023-04-06', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (429, 10, 1, '2550342.9', '2022-03-21', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (430, 7, 4, '599346', '2021-12-04', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (431, 3, 3, '775702.98', '2024-05-10', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (432, 11, 1, '842400', '2024-04-27', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (433, 11, 9, '2390432.15', '2023-07-30', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (434, 2, 10, '945348.34', '2023-05-20', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (435, 1, 8, '440068.87', '2023-10-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (436, 9, 8, '1258596.69', '2024-02-12', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (437, 1, 3, '920937', '2022-05-08', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (438, 2, 5, '2173561', '2023-11-18', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (439, 5, 1, '428697', '2023-11-05', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (440, 5, 9, '243510.3', '2022-04-28', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (441, 4, 7, '361751.11', '2023-03-06', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (442, 11, 4, '450052', '2022-09-07', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (443, 9, 4, '1245570', '2024-03-22', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (444, 10, 5, '601630.1', '2023-01-28', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (445, 3, 5, '2652232.9', '2023-09-15', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (446, 11, 6, '318362', '2022-06-18', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (447, 2, 8, '916730.15', '2024-06-25', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (448, 8, 2, '260217', '2023-02-12', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (449, 12, 9, '1985746', '2023-11-11', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (450, 9, 1, '1578532', '2023-06-17', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (451, 12, 5, '1850966', '2022-01-01', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (452, 9, 5, '2533512.5', '2024-06-10', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (453, 11, 6, '2666976.30', '2022-07-04', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (454, 1, 2, '2177723.47', '2022-11-15', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (455, 3, 3, '223639', '2022-05-05', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (456, 5, 9, '1849875', '2022-11-27', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (457, 2, 8, '1607686.53', '2022-06-25', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (458, 12, 2, '2831416', '2022-09-06', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (459, 11, 9, '1493001.39', '2022-04-09', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (460, 9, 10, '1738230', '2021-12-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (461, 9, 9, '2850082.74', '2024-02-04', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (462, 2, 7, '174042.41', '2024-03-01', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (463, 11, 3, '1725529', '2023-03-18', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (464, 7, 1, '1877230', '2022-05-21', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (465, 11, 5, '1461151', '2023-03-01', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (466, 9, 9, '2802595.8', '2022-06-09', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (467, 3, 1, '1551985', '2023-03-19', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (468, 10, 4, '741120', '2023-11-01', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (469, 6, 9, '765395', '2023-07-09', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (470, 3, 9, '960546.57', '2023-05-21', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (471, 2, 1, '776875.72', '2022-05-01', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (472, 7, 8, '321402', '2022-06-02', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (473, 5, 1, '860453', '2023-10-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (474, 3, 10, '324291', '2024-06-24', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (475, 4, 1, '1211251', '2024-01-27', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (476, 3, 1, '2939225.5', '2023-03-26', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (477, 3, 8, '2715312', '2022-06-12', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (478, 3, 5, '709652.24', '2023-03-07', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (479, 8, 2, '1499205', '2023-03-21', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (480, 11, 10, '548241', '2022-07-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (481, 9, 3, '706347', '2023-03-02', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (482, 9, 7, '470019', '2022-08-18', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (483, 4, 6, '920753', '2022-09-24', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (484, 12, 4, '1474952.8', '2023-10-01', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (485, 5, 1, '1593818.8', '2023-10-01', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (486, 5, 2, '1861904', '2024-06-26', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (487, 10, 9, '2904676', '2023-06-22', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (488, 4, 3, '642715', '2023-07-13', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (489, 10, 9, '2391851.83', '2022-04-03', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (490, 9, 6, '1855450', '2024-01-25', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (491, 7, 6, '1774473.2', '2022-12-10', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (492, 10, 8, '723223', '2023-11-05', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (493, 3, 3, '2423359', '2022-11-26', 'EDESUR');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (494, 11, 5, '1499496.14', '2023-07-16', 'mantenimiento de ascensor');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (495, 6, 9, '818445', '2022-04-02', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (496, 11, 3, '2347311.52', '2023-03-07', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (497, 11, 4, '246524', '2024-04-07', 'pintura palieres');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (498, 1, 10, '2666515', '2023-08-31', 'reemplazo lamparitas');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (499, 7, 1, '199240.4', '2023-07-29', 'limpieza de tanques');
insert into h_Gastos (id_gasto, id_proveedor, id_consorcio, costo_total, fecha, concepto) values (500, 12, 10, '1888037.67', '2024-06-25', 'mantenimiento de ascensor');
-- Insertar h_Reclamos (100)
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (1, 418, 5, 9, 'el encargado no hace nada', '2022-01-05');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (2, 451, 8, 2, 'el encargado no hace nada', '2024-04-21');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (3, 287, 6, 2, 'las expensas están muy caras', '2023-01-12');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (4, 155, 1, 7, 'las expensas están muy caras', '2022-06-06');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (5, 271, 2, 5, 'las expensas están muy caras', '2023-01-09');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (6, 437, 1, 2, 'el ascensor no anda', '2022-08-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (7, 456, 7, 3, 'las paredes están sucias', '2022-06-14');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (8, 53, 3, 5, 'el encargado me trata mal', '2023-03-08');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (9, 417, 8, 1, 'el encargado me trata mal', '2022-07-28');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (10, 68, 10, 2, 'el encargado me trata mal', '2024-05-16');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (11, 390, 2, 1, 'las expensas están muy caras', '2023-07-13');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (12, 440, 1, 2, 'el ascensor no anda', '2023-09-21');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (13, 416, 10, 9, 'las expensas están muy caras', '2023-09-09');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (14, 225, 1, 9, 'el encargado no hace nada', '2023-11-22');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (15, 55, 7, 8, 'las paredes están sucias', '2022-08-25');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (16, 118, 5, 4, 'el ascensor no anda', '2023-01-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (17, 363, 7, 3, 'el encargado no hace nada', '2021-12-02');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (18, 104, 7, 4, 'las paredes están sucias', '2024-05-04');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (19, 30, 9, 3, 'las expensas están muy caras', '2023-10-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (20, 426, 5, 9, 'el encargado no hace nada', '2023-04-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (21, 266, 9, 9, 'el ascensor no anda', '2022-11-20');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (22, 66, 8, 9, 'el ascensor no anda', '2024-06-17');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (23, 245, 4, 9, 'el ascensor no anda', '2024-06-03');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (24, 177, 4, 9, 'el ascensor no anda', '2022-01-15');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (25, 401, 8, 1, 'el encargado me trata mal', '2022-01-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (26, 67, 6, 5, 'el encargado me trata mal', '2023-08-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (27, 124, 2, 1, 'las paredes están sucias', '2022-09-26');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (28, 153, 7, 3, 'el encargado me trata mal', '2022-02-23');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (29, 276, 6, 5, 'el encargado me trata mal', '2022-11-22');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (30, 167, 1, 10, 'las paredes están sucias', '2024-05-29');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (31, 147, 10, 7, 'el encargado no hace nada', '2024-05-09');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (32, 361, 2, 8, 'las paredes están sucias', '2024-02-10');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (33, 124, 4, 7, 'las paredes están sucias', '2024-05-10');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (34, 89, 9, 4, 'el encargado no hace nada', '2023-08-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (35, 172, 2, 2, 'el encargado me trata mal', '2022-04-10');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (36, 384, 5, 5, 'el encargado no hace nada', '2024-05-23');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (37, 359, 2, 8, 'el encargado me trata mal', '2022-11-09');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (38, 328, 7, 6, 'el encargado no hace nada', '2023-02-12');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (39, 279, 7, 9, 'las paredes están sucias', '2022-09-05');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (40, 340, 2, 6, 'el ascensor no anda', '2022-07-10');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (41, 97, 9, 9, 'el encargado no hace nada', '2023-03-03');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (42, 406, 6, 7, 'el encargado me trata mal', '2022-06-25');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (43, 478, 4, 6, 'las expensas están muy caras', '2023-11-02');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (44, 58, 7, 5, 'el ascensor no anda', '2022-11-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (45, 154, 3, 10, 'las expensas están muy caras', '2023-02-13');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (46, 326, 5, 3, 'el encargado no hace nada', '2023-07-21');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (47, 404, 6, 10, 'el encargado no hace nada', '2022-06-29');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (48, 472, 3, 9, 'el encargado no hace nada', '2022-02-11');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (49, 373, 7, 2, 'las paredes están sucias', '2023-01-08');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (50, 280, 6, 1, 'las expensas están muy caras', '2023-08-12');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (51, 483, 4, 9, 'el encargado no hace nada', '2024-02-12');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (52, 70, 5, 2, 'las paredes están sucias', '2023-07-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (53, 137, 5, 3, 'el encargado me trata mal', '2023-11-24');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (54, 396, 4, 3, 'el encargado me trata mal', '2022-07-30');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (55, 195, 4, 9, 'el encargado no hace nada', '2024-06-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (56, 236, 1, 9, 'las paredes están sucias', '2023-12-17');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (57, 21, 8, 5, 'el encargado me trata mal', '2022-12-02');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (58, 166, 10, 1, 'el ascensor no anda', '2023-03-25');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (59, 111, 8, 10, 'el encargado me trata mal', '2022-04-14');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (60, 395, 2, 7, 'las paredes están sucias', '2022-07-25');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (61, 183, 5, 5, 'las paredes están sucias', '2022-08-24');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (62, 488, 2, 7, 'las expensas están muy caras', '2023-03-08');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (63, 312, 9, 9, 'el encargado me trata mal', '2023-05-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (64, 483, 4, 10, 'las paredes están sucias', '2023-09-11');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (65, 420, 1, 6, 'el encargado no hace nada', '2023-02-07');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (66, 114, 5, 8, 'las paredes están sucias', '2022-06-03');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (67, 11, 1, 4, 'el encargado me trata mal', '2023-09-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (68, 92, 5, 3, 'el ascensor no anda', '2023-01-16');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (69, 474, 8, 1, 'las expensas están muy caras', '2023-04-28');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (70, 392, 6, 3, 'el encargado no hace nada', '2022-03-15');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (71, 107, 1, 3, 'las expensas están muy caras', '2023-12-07');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (72, 107, 9, 6, 'el encargado me trata mal', '2024-04-15');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (73, 481, 3, 4, 'el ascensor no anda', '2024-05-20');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (74, 476, 9, 8, 'el ascensor no anda', '2023-11-15');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (75, 458, 6, 1, 'el encargado me trata mal', '2022-09-19');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (76, 54, 4, 7, 'el encargado me trata mal', '2022-12-13');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (77, 414, 10, 7, 'las expensas están muy caras', '2024-04-22');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (78, 89, 7, 10, 'el encargado no hace nada', '2023-05-09');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (79, 198, 9, 8, 'las expensas están muy caras', '2022-06-20');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (80, 345, 1, 1, 'el ascensor no anda', '2024-02-18');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (81, 222, 10, 9, 'el encargado me trata mal', '2023-07-21');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (82, 365, 8, 6, 'las expensas están muy caras', '2022-10-07');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (83, 384, 6, 6, 'el ascensor no anda', '2021-12-06');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (84, 51, 9, 1, 'las expensas están muy caras', '2023-11-07');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (85, 227, 10, 5, 'las expensas están muy caras', '2023-02-27');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (86, 293, 9, 10, 'el ascensor no anda', '2022-09-05');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (87, 314, 7, 7, 'el ascensor no anda', '2022-10-10');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (88, 206, 6, 10, 'las expensas están muy caras', '2023-02-14');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (89, 500, 6, 10, 'el ascensor no anda', '2022-09-25');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (90, 398, 9, 6, 'el encargado no hace nada', '2022-05-21');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (91, 186, 2, 7, 'el ascensor no anda', '2024-03-15');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (92, 19, 6, 7, 'el ascensor no anda', '2024-05-22');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (93, 487, 4, 6, 'las expensas están muy caras', '2023-01-31');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (94, 486, 6, 8, 'el encargado no hace nada', '2023-08-03');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (95, 383, 5, 2, 'el ascensor no anda', '2022-10-11');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (96, 435, 5, 8, 'el ascensor no anda', '2024-03-30');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (97, 229, 4, 3, 'el encargado no hace nada', '2022-04-01');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (98, 312, 1, 4, 'las paredes están sucias', '2022-01-28');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (99, 481, 8, 9, 'el ascensor no anda', '2024-03-08');
insert into h_Reclamos (id_reclamo, id_propietario, id_consorcio, id_administrador, descripcion, fecha) values (100, 7, 5, 2, 'las paredes están sucias', '2023-11-17');


-- PRUEBA DE UPDATE EN GASTOS
-- Actualizar Gasto 1
UPDATE h_Gastos
SET costo_total = 550.00
WHERE id_gasto = 1;

-- Actualizar Gasto 2
UPDATE h_Gastos
SET costo_total = 800.00
WHERE id_gasto = 2;

-- Actualizar Gasto 3
UPDATE h_Gastos
SET costo_total = 350.00
WHERE id_gasto = 3;

-- Actualizar Gasto 4
UPDATE h_Gastos
SET costo_total = 1100.00
WHERE id_gasto = 4;

-- Actualizar Gasto 5
UPDATE h_Gastos
SET costo_total = 300.00
WHERE id_gasto = 5;

-- SELECT * FROM consorcios;
SELECT * FROM h_Pagos_Periodo;
SELECT * FROM h_Gastos;
SELECT * FROM h_Expensas;
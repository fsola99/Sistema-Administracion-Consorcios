-- Creación de la base de datos
CREATE DATABASE administracion_consorcios;

-- Selección de la base de datos
USE administracion_consorcios;

-- Creación de la tabla Administradores
CREATE TABLE Administradores (
    id_administrador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    CUIT VARCHAR(13) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL
);

-- Creación de la tabla Encargados
CREATE TABLE Encargados (
    id_encargado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    CUIL VARCHAR(13) NOT NULL,
    salario DECIMAL(10,2) NOT NULL
);

-- Creación de la tabla Consorcios
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

-- Creación de la tabla Proveedores
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(75) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL,
    descripcion_servicio VARCHAR(100) NOT NULL
);

-- Creación de la tabla Propietarios con referencia a Hechos_Expensas
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

-- Tablas de Hechos
-- Creación de la tabla de hechos de Gastos
CREATE TABLE h_Gastos (
    id_gasto INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,
    fecha DATE NOT NULL,
    comun BOOL NOT NULL,
    departamento VARCHAR(3),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de la tabla de hechos de Expensas
CREATE TABLE h_Expensas (
    id_expensa INT AUTO_INCREMENT PRIMARY KEY,
    monto_expensas DECIMAL(10,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    pagada BOOL NOT NULL DEFAULT false
);

-- Creación de la tabla de hechos de Reclamos
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

-- Tablas intermedias
-- Creación de la tabla intermedia que contiene las Expensas de cada Propietario
CREATE TABLE Expensas_por_Propietario (
	id_expensa_por_propietario INT AUTO_INCREMENT PRIMARY KEY,
    id_expensa INT,
    id_propietario INT,
    FOREIGN KEY (id_expensa) REFERENCES h_Expensas(id_expensa),
    FOREIGN KEY (id_propietario) REFERENCES Propietarios(id_propietario)
);

-- Creación de la tabla intermedia que contiene las Expensas de cada Consorcio
CREATE TABLE Expensas_por_Consorcio (
	id_expensa_por_consorcio INT AUTO_INCREMENT PRIMARY KEY,
    id_expensa INT,
    id_consorcio INT,
    FOREIGN KEY (id_expensa) REFERENCES h_Expensas(id_expensa),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de Funciones
DELIMITER //

-- Función para calcular las expensas de un propietario
CREATE FUNCTION funcion_calcular_expensas_propietario(
    total_expensas DECIMAL(10,2),
    porcentaje_fiscal DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN (total_expensas * porcentaje_fiscal / 100);
END //

-- Función para calcular el total de gastos históricos de un consorcio
CREATE FUNCTION funcion_obtener_total_gastos_consorcio(consorcio_id INT) RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Selecciona la suma de los gastos totales para el consorcio especificado
    SELECT SUM(costo_total) INTO total
    FROM h_Gastos
    WHERE id_consorcio = consorcio_id;
    
    -- Si el total es NULL, establece total a 0
    IF total IS NULL THEN
        SET total = 0;
    END IF;
    
    -- Retorna el total de gastos históricas
    RETURN total;
END //

-- Función para calcular el total de gastos desde una fecha específica de un consorcio
CREATE FUNCTION funcion_obtener_total_gastos_consorcio_desde_fecha(consorcio_id INT, fecha_inicio DATE) RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Selecciona la suma de los gastos totales para el consorcio especificado desde una fecha específica
    SELECT SUM(costo_total) INTO total
    FROM h_Gastos
    WHERE id_consorcio = consorcio_id
    AND fecha >= fecha_inicio;
    
    -- Si el total es NULL, establece total a 0
    IF total IS NULL THEN
        SET total = 0;
    END IF;
    
    -- Retorna el total de gastos desde la fecha específica
    RETURN total;
END //

-- Función para obtener el total de las ultimas expensas de todos los consorcios de un administrador
CREATE FUNCTION funcion_obtener_total_ultimas_expensas_administrador(id_administrador INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);

    SELECT SUM(he.monto_expensas) INTO total
    FROM Consorcios c
    JOIN Expensas_por_Consorcio epc ON c.id_consorcio = epc.id_consorcio
    JOIN h_Expensas he ON epc.id_expensa = he.id_expensa
    WHERE c.id_administrador = id_administrador
      AND he.fecha_vencimiento = funcion_obtener_fecha_vencimiento_mas_reciente_consorcio(c.id_consorcio);

    RETURN total;
END //

-- Función para obtener la expensa asociada a un propietario en base a una fecha de vencimiento
CREATE FUNCTION funcion_obtener_expensa_por_fecha(fecha_busqueda DATE, id_prop INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE monto DECIMAL(10,2);

    SELECT h.monto_expensas INTO monto
    FROM h_Expensas h
    JOIN Expensas_por_Propietario ep ON h.id_expensa = ep.id_expensa
    WHERE h.fecha_vencimiento = fecha_busqueda
    AND ep.id_propietario = id_prop;

    RETURN monto;
END //

-- Función para obtener la fecha de vencimiento más reciente de las expensas de un propietario (en base a su ID)
CREATE FUNCTION funcion_obtener_fecha_vencimiento_mas_reciente_propietario(id_prop INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_max DATE;

    SELECT MAX(he.fecha_vencimiento) INTO fecha_max
    FROM Expensas_por_Propietario epp
    JOIN h_Expensas he ON epp.id_expensa = he.id_expensa
    WHERE epp.id_propietario = id_prop;

    RETURN fecha_max;
END //

-- Función para obtener la fecha de vencimiento más reciente de las expensas de un propietario (en base a su ID)
CREATE FUNCTION funcion_obtener_fecha_vencimiento_mas_reciente_consorcio(id_cons INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_max DATE;

    SELECT MAX(he.fecha_vencimiento) INTO fecha_max
    FROM Expensas_por_Consorcio epc
    JOIN h_Expensas he ON epc.id_expensa = he.id_expensa
    WHERE epc.id_consorcio = id_cons;

    RETURN fecha_max;
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

-- Vista que muestra el histórico de expensas de un propietario con detalles del consorcio
CREATE VIEW vista_historico_expensas_propietario_consorcio AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
	c.direccion AS direccion_consorcio,
    c.CUIT AS cuit_consorcio,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
JOIN 
    Expensas_por_Propietario epp ON p.id_propietario = epp.id_propietario
JOIN 
    h_Expensas he ON epp.id_expensa = he.id_expensa
ORDER BY 
    p.id_propietario, he.fecha_vencimiento;
    
-- Vista para obtener la última expensa de cada propietario utilizando
CREATE VIEW vista_ultima_expensa_por_propietario AS
SELECT 
    epp.id_propietario,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Expensas_por_Propietario epp
JOIN 
    h_Expensas he ON epp.id_expensa = he.id_expensa
WHERE 
    he.fecha_vencimiento = funcion_obtener_fecha_vencimiento_mas_reciente_propietario(epp.id_propietario);

-- Vista que brinda información general de los propietarios de un consorcio con las últimas expensas que deben pagar
CREATE VIEW vista_propietarios_consorcio_ultimas_expensas AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    p.departamento,
    c.direccion AS direccion_consorcio,
    c.CUIT AS cuit_consorcio,
    ue.monto_expensas,
    ue.fecha_vencimiento,
    ue.pagada
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
LEFT JOIN 
    vista_ultima_expensa_por_propietario ue ON p.id_propietario = ue.id_propietario
ORDER BY 
    p.id_propietario;

-- Vista para ver las ultimas expensas de cada consorcio
CREATE VIEW vista_ultima_expensa_por_consorcio AS
SELECT 
    epc.id_consorcio,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Expensas_por_Consorcio epc
JOIN 
    h_Expensas he ON epc.id_expensa = he.id_expensa
WHERE 
    he.fecha_vencimiento = funcion_obtener_fecha_vencimiento_mas_reciente_consorcio(epc.id_consorcio);

-- Vista para ver las ultimas expensas totales de un consorcio asociado a sus administradores
CREATE VIEW vista_consorcios_administradores_ultimas_expensas AS
SELECT 
    c.id_consorcio,
    c.direccion,
    c.CUIT AS cuit_consorcio,
    c.unidades_funcionales,
    a.nombre AS nombre_administrador,
    a.CUIT AS cuit_administrador,
    a.telefono AS telefono_administrador,
    a.email AS email_administrador,
    ue.monto_expensas,
    ue.fecha_vencimiento,
    ue.pagada
FROM 
    Consorcios c
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador
LEFT JOIN 
    vista_ultima_expensa_por_consorcio ue ON c.id_consorcio = ue.id_consorcio
ORDER BY 
    c.id_consorcio;

-- Vista para ver el salario de los encargados de cada consorcio
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

-- Vista que muestra el total de las expensas a pagar por administrador
CREATE VIEW vista_total_expensas_administrador AS
SELECT 
    a.id_administrador,
    a.nombre AS nombre_administrador,
    funcion_obtener_total_ultimas_expensas_administrador(a.id_administrador) AS total_expensas
FROM 
    Administradores a;
    
-- Vista que muestra el histórico de gastos con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.costo_total,
    hg.fecha,
    hg.comun
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
ORDER BY 
    hg.fecha DESC;
    
-- vista que muestre el histórico de gastos comunes (para todo el consorcio) con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos_comunes AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.costo_total,
    hg.fecha
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
WHERE 
    hg.comun = true
ORDER BY 
    hg.fecha DESC;

-- Vista que muestra el histórico de gastos específicos de un departamento con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos_especificos_departamento AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.departamento,
    hg.costo_total,
    hg.fecha
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
WHERE 
    hg.comun = false
ORDER BY 
    hg.fecha DESC;
    
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
    
-- vista que muestre el historíco de reclamos de los consorcios de un administrador.
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

-- Vista que muestra el histórico de expensas de propietarios.
CREATE VIEW vista_historico_expensas_propietarios AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.departamento,
    e.monto_expensas,
    e.fecha_vencimiento,
    e.pagada,
    c.direccion AS consorcio
FROM 
    h_Expensas e
JOIN 
    Expensas_por_Propietario ep ON e.id_expensa = ep.id_expensa
JOIN 
    Propietarios p ON ep.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    p.id_propietario, e.fecha_vencimiento DESC;
    
-- Vista que muestra el histórico de expensas de consorcios.
CREATE VIEW vista_historico_expensas_consorcios AS
SELECT 
    c.id_consorcio,
    c.direccion AS consorcio,
    e.monto_expensas,
    e.fecha_vencimiento,
    e.pagada
FROM 
    h_Expensas e
JOIN 
    Expensas_por_Consorcio ec ON e.id_expensa = ec.id_expensa
JOIN 
    Consorcios c ON ec.id_consorcio = c.id_consorcio
ORDER BY 
    c.id_consorcio, e.fecha_vencimiento DESC;
    
-- Creación de Stored Procedures.
DELIMITER //

-- Stored Procedure principal para insercion de una expensa de un consorcio, insertando entrada en h_Expensas y Expensas_por_Consorcio.
CREATE PROCEDURE sp_insertar_expensa_consorcio(
    IN consorcio_id INT,
    IN monto_expensas DECIMAL(10,2),
    IN fecha_vencimiento DATE
)
BEGIN
    DECLARE nueva_expensa_id INT;

    -- Insertar nueva expensa para el consorcio
    INSERT INTO h_Expensas (monto_expensas, fecha_vencimiento, pagada)
    VALUES (monto_expensas, fecha_vencimiento, FALSE);

    -- Obtener el id de la nueva expensa insertada
    SET nueva_expensa_id = LAST_INSERT_ID();

    -- Insertar en Expensas_por_Consorcio
    INSERT INTO Expensas_por_Consorcio (id_expensa, id_consorcio)
    VALUES (nueva_expensa_id, consorcio_id);
    
END //

-- Stored Procedure para crear las expensas de un propietario, insertando entrada en h_Expensas y Expensas_por_Propietario.
CREATE PROCEDURE sp_insertar_expensa_propietario(
    IN propietario_id INT,
    IN fecha_vencimiento DATE,
    IN monto_expensas DECIMAL(10,2)
)
BEGIN
    DECLARE new_expensa_id INT;

    -- Insertar nueva expensa para el propietario
    INSERT INTO h_Expensas (monto_expensas, fecha_vencimiento, pagada)
    VALUES (monto_expensas, fecha_vencimiento, FALSE);

    -- Obtener el id de la nueva expensa insertada
    SET new_expensa_id = LAST_INSERT_ID();

    -- Insertar en Expensas_por_Propietario
    INSERT INTO Expensas_por_Propietario (id_expensa, id_propietario)
    VALUES (new_expensa_id, propietario_id);
END //

-- Stored Procedure para Crear Expensas para Todos los Propietarios de un Consorcio, invocando.
CREATE PROCEDURE sp_crear_expensas_propietarios(
    IN expensa_id INT,
    IN consorcio_id INT,
    IN total_expensas DECIMAL(10,2),
    IN fecha DATE
)
BEGIN
    DECLARE propietario_id INT;
    DECLARE porcentaje_fiscal DECIMAL(5,2);
    
    -- Iterar sobre los propietarios del consorcio y calcular expensas
    SET @propietario_id = 0;
    WHILE EXISTS (SELECT id_propietario FROM Propietarios WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id LIMIT 1) DO
        SELECT id_propietario, porcentaje_fiscal INTO @propietario_id, porcentaje_fiscal
        FROM Propietarios 
        WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id
        LIMIT 1;
        
        -- Calcular expensa para el propietario y llamar al SP intermedio
        CALL sp_insertar_expensa_propietario(
            @propietario_id,
            fecha,
            funcion_calcular_expensas_propietario(total_expensas, porcentaje_fiscal)
        );
    END WHILE;
END //

-- Stored Procedure para actualizar las expensas de todos los propietarios de un consorcio
CREATE PROCEDURE sp_actualizar_expensas_propietarios(
    IN expensa_id INT,
    IN consorcio_id INT,
    IN nuevo_total_expensas DECIMAL(10,2),
    IN nueva_fecha DATE
)
BEGIN
    DECLARE propietario_id INT;
    DECLARE porcentaje_fiscal DECIMAL(5,2);

    -- Iterar sobre los propietarios del consorcio y actualizar expensas
    SET @propietario_id = 0;
    WHILE EXISTS (SELECT id_propietario FROM Propietarios WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id LIMIT 1) DO
        SELECT id_propietario, porcentaje_fiscal INTO @propietario_id, porcentaje_fiscal
        FROM Propietarios 
        WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id
        LIMIT 1;

        -- Calcular nueva expensa para el propietario y actualizarla en h_Expensas y Expensas_por_Propietario
        UPDATE h_Expensas he
        JOIN Expensas_por_Propietario epp ON he.id_expensa = epp.id_expensa
        SET he.monto_expensas = funcion_calcular_expensas_propietario(nuevo_total_expensas, porcentaje_fiscal), 
            he.fecha_vencimiento = nueva_fecha
        WHERE epp.id_propietario = @propietario_id 
          AND he.id_expensa = expensa_id;
    END WHILE;
END //

-- SP para actualizar el salario de un encargado específico.
CREATE PROCEDURE sp_actualizar_salario_encargado(
    IN id_encargado INT,
    IN nuevo_salario DECIMAL(10,2)
)
BEGIN
    UPDATE Encargados
    SET salario = nuevo_salario
    WHERE id_encargado = id_encargado;
END //

DELIMITER ;

DELIMITER //

-- Trigger que ante el agregado de una entrada en la tabla de Expensas_por_Consorcio, agrega las expensas correspondientes para cada propietario del Consorcio.
CREATE TRIGGER trigger_after_insert_expensas_por_consorcio
AFTER INSERT ON Expensas_por_Consorcio
FOR EACH ROW
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    DECLARE fecha DATE;

    -- Obtener el monto de la expensa desde h_Expensas
    SELECT monto_expensas INTO total_expensas
    FROM h_Expensas
    WHERE id_expensa = NEW.id_expensa;
    
	-- Obtener la fecha de vencimiento de la expensa desde h_Expensas
    SELECT fecha_vencimiento INTO fecha
    FROM h_Expensas
    WHERE id_expensa = NEW.id_expensa;

    -- Llamar al procedimiento para crear expensas de propietarios
    CALL sp_crear_expensas_propietarios(NEW.id_expensa, NEW.id_consorcio, total_expensas, fecha);
END //

-- Trigger que ante la modificación de una entrada en la tabla h_Expensas, actualiza las expensas correspondientes de los propietarios del Consorcio.
CREATE TRIGGER trigger_after_update_expensas
AFTER UPDATE ON h_Expensas
FOR EACH ROW
BEGIN
    DECLARE consorcio_id INT;

    -- Verificar si la expensa modificada está asociada a algún consorcio
    SELECT id_consorcio INTO consorcio_id
    FROM Expensas_por_Consorcio
    WHERE id_expensa = NEW.id_expensa;
    
    -- Si se encuentra el consorcio asociado, llamar al SP para actualizar las expensas de los propietarios
    IF consorcio_id IS NOT NULL THEN
        CALL sp_actualizar_expensas_propietarios(NEW.id_expensa, consorcio_id, NEW.monto_expensas, NEW.fecha_vencimiento);
    END IF;
END //

-- >
-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
--

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
-- Insertar Proveedores (10)
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
-- Para insertar expensas, usar SP "sp_insertar_expensa_consorcio"
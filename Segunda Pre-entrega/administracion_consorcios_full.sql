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
    razon_social VARCHAR(75) NOT NULL,
    CUIT VARCHAR(13) NOT NULL,
    direccion VARCHAR(75) NOT NULL,
    unidades_funcionales INT NOT NULL,
    id_administrador INT NOT NULL,
    id_encargado INT NOT NULL,
    expensas_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_administrador) REFERENCES Administradores(id_administrador),
    FOREIGN KEY (id_encargado) REFERENCES Encargados(id_encargado)
);

-- Creación de la tabla Propietarios
CREATE TABLE Propietarios (
    id_propietario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    direccion VARCHAR(75) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL,
    departamento VARCHAR(3),
    id_consorcio INT NOT NULL,
    unidad_funcional INT NOT NULL,
    expensas DECIMAL(10,2) NOT NULL DEFAULT 0,
    porcentaje_fiscal DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de la tabla Proveedores
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(75) NOT NULL,
    telefono VARCHAR(10) NOT NULL,
    email VARCHAR(50) NOT NULL,
    descripcion_servicio VARCHAR(100) NOT NULL
);

-- Creación de la tabla Reparaciones
CREATE TABLE Reparaciones (
    id_reparacion INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,
    fecha DATE NOT NULL,
    reparacion_comun BOOL NOT NULL,
    departamento VARCHAR(3),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
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

-- Función para calcular el total gastado en reparaciones del consorcio
CREATE FUNCTION funcion_obtener_total_reparaciones_consorcio(consorcio_id INT) RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Selecciona la suma de los costos totales de las reparaciones para el consorcio especificado
    SELECT SUM(costo_total) INTO total
    FROM Reparaciones
    WHERE id_consorcio = consorcio_id;
    
    -- Si el total es NULL, establece total a 0
    IF total IS NULL THEN
        SET total = 0;
    END IF;
    
    -- Retorna el total de reparaciones
    RETURN total;
END //

-- Función para obtener el total de expensas de todos los consorcios de un administrador
CREATE FUNCTION funcion_obtener_total_expensas_administrador(id_administrador INT) RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT SUM(expensas_total) INTO total
    FROM Consorcios
    WHERE id_administrador = id_administrador;
    
    IF total IS NULL THEN
        SET total = 0;
    END IF;
    
    RETURN total;
END //

DELIMITER ;

-- Creación de Vistas
-- Vista que brinda información general de los propietarios de un consorcio.
CREATE VIEW vista_general_propietarios_consorcios AS
SELECT 
    p.id_propietario,
    p.nombre AS nombre_propietario,
    p.apellido,
    p.telefono,
    p.email,
    p.expensas,
    c.razon_social AS consorcio
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista para ver las expensas totales de un consorcio asociado a sus administradores
CREATE VIEW vista_expensas_consorcios_adminstrador AS
SELECT 
    c.id_consorcio,
    c.razon_social,
    c.unidades_funcionales,
    c.expensas_total,
    a.id_administrador,
    a.nombre AS nombre_administrador,
    a.email AS email_administrador
FROM 
    Consorcios c
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador;
    
-- Vista que muestra las expensas de cada propietario con detalles del consorcio
CREATE VIEW vista_expensas_propietarios_consorcio AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    p.departamento,
    p.unidad_funcional,
	p.porcentaje_fiscal,
    p.expensas,
    c.id_consorcio,
    c.razon_social AS nombre_consorcio,
    c.expensas_total
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista que muestra las reparaciones realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones AS
SELECT 
    r.id_reparacion,
    r.fecha,
    r.reparacion_comun,
    r.departamento,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio;
    
-- Vista que muestra las reparaciones comunes realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones_comunes AS
SELECT 
    r.id_reparacion,
    r.fecha,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio
WHERE
    r.reparacion_comun = true;
    
-- Vista que muestra las reparaciones no comunes realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones_particulares AS
SELECT 
    r.id_reparacion,
    r.fecha,
    r.departamento,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio
WHERE
    r.reparacion_comun = false;

-- Vista para ver el salario de los encargados de cada consorcio
CREATE VIEW vista_salarios_encargados_consorcio AS
SELECT
    c.id_consorcio,
    c.razon_social,
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
    a.email AS email_administrador,
    funcion_obtener_total_expensas_administrador(a.id_administrador) AS total_expensas
FROM 
    Administradores a;

-- Creación de Stored Procedures
DELIMITER //

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

-- SP para actualizar el total de expensas de un consorcio
CREATE PROCEDURE sp_actualizar_expensas_consorcio(
    IN id_consorcio_param INT,
    IN nuevas_expensas_total DECIMAL(10,2)
)
BEGIN
    -- Variable para almacenar el total de expensas
    DECLARE total_expensas DECIMAL(10,2);

    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio_param;
    -- LIMIT 1;

    -- Verificar si se encontró un resultado
    IF total_expensas IS NOT NULL THEN
        -- Actualizar el total de expensas del consorcio
        UPDATE Consorcios
        SET expensas_total = nuevas_expensas_total
        WHERE id_consorcio = id_consorcio_param;

        -- Llamar a la función para recalcular las expensas de los propietarios
        CALL sp_actualizar_expensas_propietarios(id_consorcio_param);
    ELSE
        -- Si no se encontró ningún consorcio con ese id, mostrar un mensaje o manejar el error según sea necesario
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se encontró ningún consorcio con el ID especificado.';
    END IF;
END //

-- SP para recalcular las expensas de cada propietario en un consorcio
CREATE PROCEDURE sp_actualizar_expensas_propietarios(
    IN id_consorcio_param INT
)
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    
    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio_param;
    -- LIMIT 1;

    -- Actualizar las expensas de cada propietario usando la función
    UPDATE Propietarios
    SET expensas = funcion_calcular_expensas_propietario(total_expensas, porcentaje_fiscal)
    WHERE id_consorcio = id_consorcio_param;
END //

DELIMITER ;

-- TRIGGERS
DELIMITER //

-- Trigger para actualizar las expensas de cada propietario cuando se actualiza el valor total de las expensas de un consorcio
CREATE TRIGGER trigger_actualizar_expensas_propietarios
AFTER UPDATE ON Consorcios
FOR EACH ROW
BEGIN
    IF NEW.expensas_total <> OLD.expensas_total THEN
        CALL sp_actualizar_expensas_propietarios(NEW.id_consorcio);
    END IF;
END //

-- Trigger para calcular automaticamente el valor de las expensas del propietario antes de ser insertado en la base (sirve para creacion base de propietario)
CREATE TRIGGER trigger_calcular_expensas_propietario
BEFORE INSERT ON Propietarios
FOR EACH ROW
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    DECLARE cuota_parte_propietario DECIMAL(5,2);

    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = NEW.id_consorcio;

    -- Calcular la cuota parte del propietario
    SET cuota_parte_propietario = NEW.porcentaje_fiscal / 100;

    -- Calcular las expensas del propietario
    SET NEW.expensas = total_expensas * cuota_parte_propietario;
END //

-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
CREATE TRIGGER trigger_sumar_costo_reparacion_expensas_consorcio
AFTER INSERT ON Reparaciones
FOR EACH ROW
BEGIN
    UPDATE Consorcios
    SET expensas_total = expensas_total + NEW.costo_total
    WHERE id_consorcio = NEW.id_consorcio;
END //

DELIMITER ;

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
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (1, '66 Walton Crossing', '33-75759115-3', '66 Walton Crossing', 572, 10, 4);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (2, '857 Muir Trail', '30-78335263-3', '857 Muir Trail', 483, 9, 2);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (3, '35 Lake View Pass', '30-54927417-1', '35 Lake View Pass', 598, 2, 7);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (4, '11330 Johnson Street', '30-32286770-1', '11330 Johnson Street', 539, 1, 7);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (5, '2 Nobel Place', '23-13590496-2', '2 Nobel Place', 390, 2, 4);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (6, '28 Anniversary Terrace', '20-65346667-0', '28 Anniversary Terrace', 648, 3, 3);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (7, '59 Mifflin Hill', '20-26751285-1', '59 Mifflin Hill', 496, 8, 10);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (8, '83 Haas Trail', '30-50642535-2', '83 Haas Trail', 380, 3, 6);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (9, '73 Lindbergh Drive', '20-08965651-3', '73 Lindbergh Drive', 626, 2, 6);
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (10, '678 Thackeray Terrace', '23-78074622-1', '678 Thackeray Terrace', 641, 3, 2);
-- Insertar Propietarios (500)
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (1, 'Lisha', 'Haddick', '40 Stephen Terrace', '1174766297', 'lhaddick0@ucoz.ru', '13E', 5, 25, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (2, 'Fransisco', 'Yeandel', '450 Porter Parkway', '1110018526', 'fyeandel1@earthlink.net', '11E', 6, 117, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (3, 'Itch', 'McCoish', '681 8th Pass', '1122548128', 'imccoish2@w3.org', '3E', 9, 55, '2.33');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (4, 'Erica', 'Webling', '5 Northview Plaza', '1120281720', 'ewebling3@nationalgeographic.com', '24D', 7, 41, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (5, 'Erminia', 'Delacourt', '80203 Roth Pass', '1137909214', 'edelacourt4@surveymonkey.com', '7B', 3, 51, '2.31');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (6, 'Brose', 'Di Ruggiero', '982 Lake View Alley', '1197413365', 'bdiruggiero5@g.co', '28F', 10, 17, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (7, 'Gorden', 'Toye', '1999 Pierstorff Plaza', '1159918408', 'gtoye6@quantcast.com', '3D', 6, 88, '2.43');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (8, 'Chiquia', 'Barkas', '9263 Meadow Ridge Park', '1161388572', 'cbarkas7@mlb.com', '2E', 9, 111, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (9, 'Lissy', 'Cornick', '586 Lake View Terrace', '1116185548', 'lcornick8@jugem.jp', '22D', 7, 53, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (10, 'Noby', 'Headington', '9255 Fisk Street', '1165925321', 'nheadington9@irs.gov', '7B', 5, 49, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (11, 'Kingsly', 'Broadwood', '328 Sauthoff Crossing', '1150452223', 'kbroadwooda@photobucket.com', '24A', 10, 86, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (12, 'Art', 'Klemencic', '441 Merchant Center', '1187856869', 'aklemencicb@behance.net', '3B', 3, 98, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (13, 'Judie', 'Cess', '6918 Brown Point', '1111854689', 'jcessc@sina.com.cn', '9F', 5, 54, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (14, 'Violette', 'Rantoul', '31976 Loftsgordon Way', '1195568956', 'vrantould@indiegogo.com', '13E', 10, 79, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (15, 'Jilly', 'Videan', '80 Northwestern Park', '1103074850', 'jvideane@slashdot.org', '23E', 1, 7, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (16, 'Cordie', 'Bellocht', '83286 Weeping Birch Trail', '1121551261', 'cbellochtf@csmonitor.com', '15A', 7, 35, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (17, 'Brittney', 'Earwaker', '99582 Vahlen Place', '1159980736', 'bearwakerg@google.ca', '6C', 1, 25, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (18, 'Harlene', 'Laird', '79023 Sutherland Hill', '1167964514', 'hlairdh@mayoclinic.com', '7F', 3, 107, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (19, 'Wainwright', 'Albinson', '7695 Grim Parkway', '1119213523', 'walbinsoni@china.com.cn', '2C', 4, 15, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (20, 'Venita', 'Ellerey', '695 Lyons Alley', '1154745799', 'vellereyj@nih.gov', '5B', 1, 5, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (21, 'Domeniga', 'Broadis', '3910 Declaration Street', '1174116286', 'dbroadisk@wordpress.com', '28C', 8, 62, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (22, 'Verne', 'Munson', '83 Blaine Trail', '1185279872', 'vmunsonl@wikispaces.com', '3C', 7, 81, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (23, 'Astra', 'Pischoff', '8074 Dakota Hill', '1184656267', 'apischoffm@newsvine.com', '7C', 3, 77, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (24, 'Revkah', 'Heale', '307 David Hill', '1192594192', 'rhealen@ezinearticles.com', '5F', 3, 5, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (25, 'Leroi', 'Daldry', '480 Springs Road', '1178220537', 'ldaldryo@amazonaws.com', '22E', 6, 71, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (26, 'Sheelah', 'Poulsom', '0 Trailsway Terrace', '1106813545', 'spoulsomp@ocn.ne.jp', '8B', 6, 85, '2.15');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (27, 'Ricardo', 'Dur', '31 Mayer Circle', '1135390661', 'rdurq@merriam-webster.com', '4B', 7, 63, '1.94');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (28, 'Evita', 'Wasylkiewicz', '5 Sauthoff Court', '1109042147', 'ewasylkiewiczr@prlog.org', '3F', 3, 71, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (29, 'Stearn', 'Andraud', '9 Declaration Trail', '1113290348', 'sandrauds@marriott.com', '5B', 9, 81, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (30, 'Marsiella', 'Gabbett', '4 Pine View Circle', '1116600179', 'mgabbettt@stumbleupon.com', '1E', 9, 43, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (31, 'Rosemarie', 'Huey', '6811 Forest Pass', '1149803808', 'rhueyu@usgs.gov', '6B', 1, 15, '1.78');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (32, 'Arluene', 'Connock', '95 Lindbergh Center', '1178703084', 'aconnockv@usa.gov', '21F', 2, 58, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (33, 'Garner', 'O''Hagan', '43 Brickson Park Point', '1113266822', 'gohaganw@macromedia.com', '8C', 3, 57, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (34, 'Patty', 'Craggs', '00845 Superior Avenue', '1150511425', 'pcraggsx@narod.ru', '9F', 2, 58, '2.46');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (35, 'Benedetto', 'Athow', '43 Iowa Plaza', '1109622462', 'bathowy@bigcartel.com', '1D', 5, 3, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (36, 'Rebecca', 'Brindle', '7865 Valley Edge Trail', '1162429490', 'rbrindlez@patch.com', '16D', 8, 114, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (37, 'Pansie', 'Corriea', '4370 Ruskin Place', '1107672288', 'pcorriea10@yahoo.co.jp', '15E', 2, 11, '1.29');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (38, 'Sigfried', 'Spurritt', '969 Cody Parkway', '1106506836', 'sspurritt11@elpais.com', '13D', 7, 41, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (39, 'Tessi', 'Sebastian', '94850 Mayer Road', '1142931618', 'tsebastian12@bbc.co.uk', '29B', 5, 7, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (40, 'Veronique', 'Discombe', '0538 Monica Court', '1142744331', 'vdiscombe13@goodreads.com', '6E', 4, 26, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (41, 'Addie', 'Drinan', '7643 Rieder Plaza', '1111656783', 'adrinan14@apache.org', '24A', 2, 9, '2.40');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (42, 'Fleur', 'Macewan', '31 Swallow Avenue', '1154931749', 'fmacewan15@furl.net', '25B', 9, 95, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (43, 'Myrtia', 'Scotson', '74390 Holmberg Parkway', '1174602542', 'mscotson16@hugedomains.com', '5F', 8, 61, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (44, 'Iggie', 'Iowarch', '67 Sutherland Way', '1105997127', 'iiowarch17@walmart.com', '8F', 9, 104, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (45, 'Clarissa', 'Cobbe', '102 Vernon Lane', '1167372227', 'ccobbe18@who.int', '21F', 4, 29, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (46, 'Ralina', 'Castane', '49 Redwing Court', '1155206906', 'rcastane19@va.gov', '9D', 7, 54, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (47, 'Lanae', 'Aizikov', '23 Little Fleur Park', '1130771171', 'laizikov1a@fema.gov', '4F', 6, 113, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (48, 'Pearce', 'Attride', '8 Briar Crest Road', '1181333885', 'pattride1b@wisc.edu', '18A', 7, 89, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (49, 'Wendie', 'Worvill', '16 Homewood Street', '1126860673', 'wworvill1c@usgs.gov', '23E', 3, 100, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (50, 'Anet', 'Blachford', '61175 Gale Trail', '1194497886', 'ablachford1d@princeton.edu', '5E', 5, 116, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (51, 'Jo-anne', 'Avrasin', '3839 4th Center', '1197463087', 'javrasin1e@hostgator.com', '21C', 3, 77, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (52, 'Virgina', 'Minci', '201 Fisk Alley', '1129402159', 'vminci1f@narod.ru', '22C', 3, 109, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (53, 'Magdalena', 'Crampton', '1810 Summerview Lane', '1103471366', 'mcrampton1g@hubpages.com', '25B', 1, 46, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (54, 'Isa', 'Philpot', '4 Glacier Hill Way', '1182079127', 'iphilpot1h@yahoo.com', '2A', 10, 100, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (55, 'Maximilian', 'McIntosh', '34926 Starling Road', '1136701308', 'mmcintosh1i@wordpress.org', '6C', 8, 44, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (56, 'Ruthi', 'Muddiman', '43876 Express Plaza', '1117750043', 'rmuddiman1j@prnewswire.com', '9C', 5, 84, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (57, 'Joyous', 'Reichhardt', '1 Kropf Street', '1187437281', 'jreichhardt1k@hatena.ne.jp', '29F', 2, 116, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (58, 'Fayette', 'Jendrach', '178 Caliangt Trail', '1180520715', 'fjendrach1l@newyorker.com', '26C', 2, 53, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (59, 'Norine', 'Manion', '896 Jana Parkway', '1108806398', 'nmanion1m@unicef.org', '4B', 3, 4, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (60, 'Fabien', 'Azemar', '6575 Crownhardt Pass', '1149902854', 'fazemar1n@freewebs.com', '1B', 4, 115, '1.78');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (61, 'Thorndike', 'Morecomb', '56874 Onsgard Pass', '1187968244', 'tmorecomb1o@wikipedia.org', '1D', 7, 70, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (62, 'Red', 'Nestle', '04278 Badeau Center', '1100897283', 'rnestle1p@blogspot.com', '23F', 8, 16, '1.50');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (63, 'Alexandra', 'Stawell', '31 Stoughton Drive', '1191169811', 'astawell1q@independent.co.uk', '3A', 1, 13, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (64, 'Kameko', 'Winder', '3631 Maple Avenue', '1193450098', 'kwinder1r@epa.gov', '29B', 5, 20, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (65, 'Bernard', 'Skillett', '98580 Lakewood Park', '1165290975', 'bskillett1s@soup.io', '11E', 1, 20, '2.09');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (66, 'Kippy', 'Waber', '770 Artisan Lane', '1163336382', 'kwaber1t@nifty.com', '2B', 2, 99, '1.49');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (67, 'Liva', 'Wade', '62228 6th Junction', '1159418147', 'lwade1u@reverbnation.com', '18A', 1, 15, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (68, 'Georgeta', 'Chettle', '77515 Comanche Hill', '1160879432', 'gchettle1v@miitbeian.gov.cn', '6B', 6, 56, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (69, 'Bond', 'Snaddon', '36900 Tennessee Park', '1170915816', 'bsnaddon1w@vimeo.com', '8C', 8, 102, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (70, 'Gale', 'Simkins', '772 Blue Bill Park Terrace', '1118292797', 'gsimkins1x@tinypic.com', '24F', 3, 34, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (71, 'Netta', 'Carren', '818 Emmet Hill', '1154781362', 'ncarren1y@nationalgeographic.com', '18E', 8, 83, '1.06');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (72, 'Eirena', 'Glossup', '8 Vernon Crossing', '1143475224', 'eglossup1z@aboutads.info', '27D', 3, 92, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (73, 'Esma', 'Antoniou', '744 Meadow Vale Plaza', '1109549265', 'eantoniou20@examiner.com', '26A', 9, 27, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (74, 'Liesa', 'Yushankin', '5707 Orin Lane', '1162854160', 'lyushankin21@mlb.com', '18E', 8, 97, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (75, 'Gizela', 'Kirkbride', '55 Crescent Oaks Circle', '1190357653', 'gkirkbride22@toplist.cz', '14F', 6, 82, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (76, 'Callie', 'Blythin', '69 Alpine Plaza', '1167632778', 'cblythin23@a8.net', '9E', 8, 35, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (77, 'Elsi', 'Emeny', '8 Westport Hill', '1173996773', 'eemeny24@163.com', '4A', 5, 78, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (78, 'Geralda', 'Wakes', '4 Arrowood Hill', '1119169848', 'gwakes25@nasa.gov', '4F', 7, 74, '2.17');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (79, 'Misty', 'Ohms', '4647 Westport Parkway', '1181369842', 'mohms26@amazonaws.com', '28D', 5, 104, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (80, 'Anne', 'Brien', '1 Eliot Street', '1187375126', 'abrien27@google.ru', '11B', 7, 34, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (81, 'Bartlet', 'Whewell', '9 Duke Circle', '1117065985', 'bwhewell28@tripadvisor.com', '3C', 2, 46, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (82, 'Lenee', 'Milella', '77 Saint Paul Hill', '1123894488', 'lmilella29@surveymonkey.com', '4F', 5, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (83, 'Augustus', 'Nuzzetti', '9 Hintze Way', '1140317436', 'anuzzetti2a@statcounter.com', '8F', 7, 117, '1.04');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (84, 'Jennie', 'Goodban', '59817 Myrtle Road', '1174090144', 'jgoodban2b@admin.ch', '2E', 7, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (85, 'Kennith', 'McQuirk', '969 Comanche Hill', '1193731208', 'kmcquirk2c@archive.org', '1E', 2, 69, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (86, 'Tedd', 'Mursell', '7 Ridgeview Crossing', '1149289122', 'tmursell2d@yolasite.com', '5C', 3, 108, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (87, 'Kinnie', 'Jex', '9454 Meadow Valley Crossing', '1180295605', 'kjex2e@va.gov', '16B', 9, 3, '1.15');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (88, 'Angelia', 'Rieme', '98826 Rigney Pass', '1178851818', 'arieme2f@ask.com', '27A', 5, 42, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (89, 'Mickie', 'Hulles', '3092 Jenifer Place', '1158177963', 'mhulles2g@slashdot.org', '9B', 6, 2, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (90, 'Haven', 'Scrimgeour', '358 Maryland Lane', '1192623232', 'hscrimgeour2h@posterous.com', '24B', 6, 21, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (91, 'Pincus', 'Toghill', '258 Walton Way', '1190245102', 'ptoghill2i@etsy.com', '23C', 9, 120, '1.73');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (92, 'Aurlie', 'Punt', '5 Fulton Pass', '1103116660', 'apunt2j@cam.ac.uk', '7D', 9, 45, '1.49');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (93, 'Jacinthe', 'Klisch', '2015 Myrtle Terrace', '1103160285', 'jklisch2k@google.fr', '23C', 10, 36, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (94, 'Beatrisa', 'Lagden', '3055 Ohio Road', '1106508866', 'blagden2l@biglobe.ne.jp', '2D', 4, 9, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (95, 'Farlee', 'Stening', '8263 Forster Park', '1119970156', 'fstening2m@comsenz.com', '17B', 2, 107, '2.39');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (96, 'Sky', 'Whitmore', '71848 Wayridge Plaza', '1105079075', 'swhitmore2n@exblog.jp', '7F', 4, 15, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (97, 'Annmarie', 'Mapes', '2 Talmadge Park', '1196950569', 'amapes2o@wsj.com', '2D', 6, 92, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (98, 'Carlie', 'Bart', '26839 Karstens Alley', '1153122211', 'cbart2p@mozilla.com', '5B', 7, 13, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (99, 'Thorstein', 'Sterman', '2070 Forster Crossing', '1115551056', 'tsterman2q@oaic.gov.au', '3D', 8, 74, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (100, 'Cleon', 'Nathon', '73794 Marcy Center', '1150804488', 'cnathon2r@bbc.co.uk', '23D', 1, 2, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (101, 'Garfield', 'O'' Culligan', '8103 Nevada Parkway', '1145272927', 'goculligan2s@opera.com', '29E', 2, 30, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (102, 'Joelle', 'Churchward', '331 Raven Drive', '1155654548', 'jchurchward2t@cargocollective.com', '25B', 4, 24, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (103, 'Deloria', 'Wolfarth', '8 Weeping Birch Way', '1181500367', 'dwolfarth2u@foxnews.com', '17E', 3, 5, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (104, 'Rhett', 'Baudassi', '042 Bartelt Lane', '1109871342', 'rbaudassi2v@lycos.com', '7B', 7, 16, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (105, 'Peter', 'Giveen', '92476 New Castle Trail', '1107666736', 'pgiveen2w@jigsy.com', '21F', 6, 101, '2.02');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (106, 'Marthena', 'Brezlaw', '41889 Autumn Leaf Trail', '1116078653', 'mbrezlaw2x@china.com.cn', '13C', 4, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (107, 'Brice', 'Weildish', '08 Golf Hill', '1174006509', 'bweildish2y@umich.edu', '15B', 9, 29, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (108, 'Shirline', 'Grelak', '532 Bowman Point', '1113216568', 'sgrelak2z@cbc.ca', '12A', 6, 18, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (109, 'Andria', 'Radleigh', '4303 Main Crossing', '1127464156', 'aradleigh30@sourceforge.net', '13B', 10, 102, '1.75');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (110, 'Griff', 'Brumble', '05 Butterfield Court', '1174623665', 'gbrumble31@cpanel.net', '27E', 4, 99, '2.32');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (111, 'Cloe', 'Durrad', '7 Merry Terrace', '1191620155', 'cdurrad32@miibeian.gov.cn', '3D', 9, 66, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (112, 'Anatollo', 'Wooff', '2 Golf Course Place', '1147993595', 'awooff33@businessweek.com', '22B', 7, 70, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (113, 'Janka', 'Guisler', '58 Arkansas Road', '1127216783', 'jguisler34@ocn.ne.jp', '7C', 2, 71, '1.09');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (114, 'Dorrie', 'Doorbar', '768 Fremont Avenue', '1197852565', 'ddoorbar35@facebook.com', '4C', 1, 97, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (115, 'Gui', 'Bondesen', '57 Marcy Place', '1108157708', 'gbondesen36@yellowpages.com', '4B', 3, 1, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (116, 'Peggy', 'Osmund', '84288 Bunting Place', '1152521781', 'posmund37@nbcnews.com', '3A', 5, 67, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (117, 'Duncan', 'Fritzer', '6 Old Gate Crossing', '1160637477', 'dfritzer38@ycombinator.com', '1B', 3, 20, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (118, 'Norrie', 'Humes', '2 Tennessee Parkway', '1187305814', 'nhumes39@delicious.com', '18C', 7, 103, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (119, 'Dannel', 'Monkton', '26558 Victoria Way', '1119596584', 'dmonkton3a@mlb.com', '9C', 1, 11, '1.10');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (120, 'Jesus', 'Giorgeschi', '5171 Twin Pines Road', '1112320163', 'jgiorgeschi3b@whitehouse.gov', '22F', 6, 42, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (121, 'Vin', 'Jaggard', '027 Hauk Crossing', '1106231584', 'vjaggard3c@scientificamerican.com', '24E', 3, 3, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (122, 'Felipe', 'Lindstrom', '56195 Dapin Plaza', '1105668563', 'flindstrom3d@whitehouse.gov', '25D', 1, 70, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (123, 'Lurette', 'Holmyard', '613 Dennis Alley', '1143971420', 'lholmyard3e@de.vu', '28E', 5, 24, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (124, 'Dominga', 'Rounds', '587 Transport Center', '1137818976', 'drounds3f@sina.com.cn', '2C', 7, 46, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (125, 'Hinda', 'Fursey', '557 5th Parkway', '1149537889', 'hfursey3g@omniture.com', '12C', 2, 5, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (126, 'Chad', 'Younghusband', '5 Petterle Circle', '1116525463', 'cyounghusband3h@w3.org', '7B', 3, 81, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (127, 'Fee', 'Grattan', '819 Maywood Avenue', '1188836886', 'fgrattan3i@businessinsider.com', '13D', 6, 29, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (128, 'Archie', 'Spargo', '75 Blaine Street', '1156105340', 'aspargo3j@devhub.com', '16D', 9, 33, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (129, 'Beatrisa', 'McGiffin', '4 Talmadge Pass', '1140152734', 'bmcgiffin3k@netvibes.com', '17F', 1, 66, '1.58');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (130, 'Sylvia', 'Gaisford', '50491 Rowland Alley', '1167831648', 'sgaisford3l@meetup.com', '9E', 6, 105, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (131, 'Sharl', 'McKellar', '87 Melvin Way', '1161078524', 'smckellar3m@ed.gov', '11F', 9, 111, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (132, 'Freddy', 'Dagg', '1978 Summit Pass', '1151878457', 'fdagg3n@mozilla.com', '21D', 7, 61, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (133, 'Gaspar', 'Awde', '25 Pankratz Way', '1104332200', 'gawde3o@google.com.au', '18B', 8, 24, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (134, 'Aurea', 'Stickens', '0582 Morningstar Hill', '1171319836', 'astickens3p@vinaora.com', '22F', 7, 47, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (135, 'Nicky', 'Tucsell', '03251 Pierstorff Hill', '1149370542', 'ntucsell3q@hostgator.com', '1F', 3, 18, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (136, 'Saunder', 'Piele', '364 Mccormick Center', '1113002087', 'spiele3r@fc2.com', '16D', 9, 119, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (137, 'Dawna', 'Stelljes', '614 Lotheville Crossing', '1107748090', 'dstelljes3s@cnn.com', '17D', 10, 83, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (138, 'Antin', 'Hymer', '235 Fordem Alley', '1179803982', 'ahymer3t@aol.com', '25F', 7, 38, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (139, 'Theo', 'Crosfield', '978 Merry Crossing', '1126472490', 'tcrosfield3u@marketwatch.com', '7A', 4, 43, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (140, 'Tobias', 'Dalwood', '3 Lerdahl Center', '1173241925', 'tdalwood3v@ask.com', '21B', 4, 33, '2.46');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (141, 'Mia', 'Brookton', '608 Moland Way', '1180335632', 'mbrookton3w@imgur.com', '8E', 2, 54, '2.31');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (142, 'Miran', 'Akett', '4 Elmside Trail', '1116197458', 'makett3x@vk.com', '25C', 3, 88, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (143, 'Barthel', 'Mawson', '065 Roxbury Road', '1174942143', 'bmawson3y@skyrock.com', '19A', 5, 79, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (144, 'Ferdinanda', 'Wrightham', '988 Elgar Crossing', '1114031800', 'fwrightham3z@purevolume.com', '3E', 9, 51, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (145, 'Shani', 'Lisett', '2 Fremont Plaza', '1127928701', 'slisett40@tripadvisor.com', '3A', 4, 105, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (146, 'Katine', 'Matcham', '69 Sutteridge Court', '1198281331', 'kmatcham41@slate.com', '2A', 1, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (147, 'Thorny', 'Scholar', '84 Sherman Court', '1181745814', 'tscholar42@shareasale.com', '1F', 8, 65, '1.39');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (148, 'Gretal', 'Hardman', '7800 Texas Parkway', '1196161304', 'ghardman43@berkeley.edu', '8E', 2, 10, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (149, 'Jourdain', 'Kirrens', '600 Kingsford Crossing', '1145502524', 'jkirrens44@ask.com', '3D', 10, 33, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (150, 'Merrili', 'Crossan', '1255 Red Cloud Hill', '1111528243', 'mcrossan45@comcast.net', '2E', 7, 23, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (151, 'Town', 'Bernaciak', '40 Maple Wood Street', '1179376893', 'tbernaciak46@bloglines.com', '4F', 5, 9, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (152, 'Eziechiele', 'Lethlay', '73795 Schmedeman Center', '1137673711', 'elethlay47@spiegel.de', '9A', 6, 39, '2.18');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (153, 'Tammara', 'Kidsley', '4246 Nobel Junction', '1100304410', 'tkidsley48@xrea.com', '25E', 8, 11, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (154, 'Odo', 'Fearon', '5522 Dryden Park', '1106577696', 'ofearon49@gravatar.com', '3C', 7, 100, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (155, 'Marillin', 'Essex', '6 Schurz Alley', '1147149758', 'messex4a@addthis.com', '28F', 1, 16, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (156, 'Dexter', 'Kyte', '34 Oriole Trail', '1155495295', 'dkyte4b@accuweather.com', '3D', 4, 10, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (157, 'Lincoln', 'Reoch', '4 Tennessee Parkway', '1143279417', 'lreoch4c@wp.com', '13A', 5, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (158, 'Sephira', 'Wallas', '45182 Londonderry Junction', '1194916112', 'swallas4d@geocities.com', '22B', 10, 82, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (159, 'Fara', 'Meininking', '36 Anthes Plaza', '1111568699', 'fmeininking4e@sourceforge.net', '13C', 10, 103, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (160, 'Griff', 'Ert', '070 Beilfuss Alley', '1142379528', 'gert4f@bluehost.com', '7F', 7, 2, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (161, 'Chester', 'Zanazzi', '23313 Barby Alley', '1123775245', 'czanazzi4g@github.com', '1B', 1, 23, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (162, 'Bibbie', 'Youll', '47805 Swallow Plaza', '1123785441', 'byoull4h@engadget.com', '22F', 3, 101, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (163, 'Tabbie', 'Cardoe', '72417 Lakewood Gardens Crossing', '1145646885', 'tcardoe4i@youtu.be', '5F', 4, 113, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (164, 'Quintina', 'Gheorghescu', '38436 Orin Trail', '1163744987', 'qgheorghescu4j@ehow.com', '8D', 8, 39, '2.13');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (165, 'Ricca', 'Greenslade', '31 Commercial Plaza', '1170364453', 'rgreenslade4k@goodreads.com', '5D', 6, 31, '1.70');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (166, 'Marjy', 'Soreau', '82 Riverside Avenue', '1189854489', 'msoreau4l@mayoclinic.com', '4F', 4, 34, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (167, 'Temple', 'Dyett', '3132 Utah Crossing', '1179152827', 'tdyett4m@uiuc.edu', '8B', 2, 86, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (168, 'Conrad', 'Halwill', '67832 Walton Drive', '1166939540', 'chalwill4n@elpais.com', '16A', 3, 98, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (169, 'Oralia', 'Kiddell', '8407 Amoth Drive', '1125924889', 'okiddell4o@ucsd.edu', '4B', 1, 57, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (170, 'Ivor', 'Quenby', '465 Welch Drive', '1119868103', 'iquenby4p@pagesperso-orange.fr', '9E', 3, 99, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (171, 'Anjanette', 'Prydden', '1524 Pierstorff Place', '1162309818', 'aprydden4q@businesswire.com', '2C', 7, 114, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (172, 'Beryl', 'Anslow', '9636 Myrtle Drive', '1173317805', 'banslow4r@jigsy.com', '6E', 7, 103, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (173, 'Tadio', 'Lemarie', '5216 Mandrake Road', '1169045703', 'tlemarie4s@people.com.cn', '4F', 7, 51, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (174, 'Nona', 'Kuhnel', '74805 Carpenter Way', '1149440728', 'nkuhnel4t@nytimes.com', '16A', 7, 113, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (175, 'Alan', 'Panichelli', '2 Tennyson Court', '1126390281', 'apanichelli4u@goodreads.com', '19C', 7, 2, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (176, 'Clotilda', 'Goalley', '43 Swallow Alley', '1104127657', 'cgoalley4v@wikispaces.com', '15E', 4, 32, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (177, 'Darill', 'Rayner', '17487 Oxford Plaza', '1186175797', 'drayner4w@forbes.com', '6B', 1, 43, '1.56');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (178, 'Malorie', 'Blainey', '27 Canary Point', '1110989568', 'mblainey4x@twitter.com', '2A', 4, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (179, 'Idell', 'Ginie', '7947 Hovde Place', '1141328878', 'iginie4y@indiegogo.com', '28E', 9, 108, '1.29');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (180, 'Waverley', 'Cartwight', '2330 American Ash Lane', '1181774610', 'wcartwight4z@psu.edu', '11B', 7, 95, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (181, 'Florence', 'Soar', '535 2nd Pass', '1179153157', 'fsoar50@alexa.com', '12F', 2, 83, '1.13');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (182, 'Saloma', 'Robottham', '8254 Golf Course Street', '1150014809', 'srobottham51@eventbrite.com', '8F', 6, 95, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (183, 'Bucky', 'Keiley', '8643 5th Street', '1148268614', 'bkeiley52@issuu.com', '4B', 1, 43, '2.26');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (184, 'Pam', 'Spoors', '2 Dwight Point', '1169269672', 'pspoors53@odnoklassniki.ru', '2E', 7, 75, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (185, 'Jacquie', 'Franzen', '6888 Lakeland Street', '1141758002', 'jfranzen54@unc.edu', '1C', 8, 108, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (186, 'Michaeline', 'Trolley', '62 Bluestem Street', '1161880313', 'mtrolley55@examiner.com', '14E', 6, 52, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (187, 'Francis', 'Halbeard', '145 Corscot Point', '1143346622', 'fhalbeard56@amazonaws.com', '8B', 4, 116, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (188, 'Grantley', 'Crust', '7 Waxwing Center', '1133728719', 'gcrust57@theglobeandmail.com', '11B', 9, 18, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (189, 'Merrick', 'Roubeix', '4554 Hoepker Circle', '1143988017', 'mroubeix58@java.com', '5E', 4, 108, '1.43');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (190, 'Jacqueline', 'June', '05 Becker Place', '1152500317', 'jjune59@icio.us', '16C', 2, 35, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (191, 'Arda', 'Treneer', '076 Fieldstone Parkway', '1175370422', 'atreneer5a@shop-pro.jp', '13C', 6, 106, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (192, 'Leodora', 'Garrit', '0684 Butterfield Drive', '1179689871', 'lgarrit5b@nasa.gov', '3D', 3, 95, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (193, 'Brier', 'Capelin', '16067 Moose Way', '1152992913', 'bcapelin5c@yolasite.com', '25A', 5, 50, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (194, 'Guinevere', 'Doak', '7840 Darwin Court', '1150383979', 'gdoak5d@wikispaces.com', '13F', 6, 83, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (195, 'Wendel', 'Hampson', '4843 Lukken Court', '1133334777', 'whampson5e@fotki.com', '22F', 6, 15, '1.62');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (196, 'Svend', 'Mangan', '81 Dryden Junction', '1187386527', 'smangan5f@biglobe.ne.jp', '2D', 1, 42, '1.99');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (197, 'Philis', 'Hefforde', '72 Fieldstone Avenue', '1195613086', 'phefforde5g@aboutads.info', '9D', 7, 62, '1.39');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (198, 'Joanne', 'Lermouth', '2 Di Loreto Crossing', '1128633922', 'jlermouth5h@mayoclinic.com', '19C', 9, 88, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (199, 'Pace', 'Brandacci', '17749 Bellgrove Place', '1154292134', 'pbrandacci5i@squidoo.com', '14A', 8, 98, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (200, 'Carny', 'Breslau', '018 Annamark Center', '1162027239', 'cbreslau5j@timesonline.co.uk', '18F', 8, 85, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (201, 'Meara', 'MacMarcuis', '41815 Hintze Hill', '1144800876', 'mmacmarcuis5k@bandcamp.com', '1A', 9, 86, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (202, 'Maddie', 'Byham', '36904 Doe Crossing Center', '1145240546', 'mbyham5l@seesaa.net', '17F', 3, 60, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (203, 'Jane', 'Ludwig', '8271 New Castle Center', '1192728554', 'jludwig5m@com.com', '1B', 5, 71, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (204, 'Kenna', 'Cordle', '4 Superior Pass', '1113404033', 'kcordle5n@yolasite.com', '26B', 10, 81, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (205, 'Robinet', 'Gibling', '03895 Pennsylvania Point', '1139664221', 'rgibling5o@cnn.com', '3B', 6, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (206, 'Caryn', 'Nadin', '882 Claremont Trail', '1139563824', 'cnadin5p@umn.edu', '27E', 1, 58, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (207, 'Graham', 'Fayre', '452 Banding Circle', '1199023531', 'gfayre5q@comcast.net', '28B', 1, 106, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (208, 'Lib', 'Henkens', '8 Oxford Lane', '1126594928', 'lhenkens5r@google.co.jp', '5A', 9, 102, '2.07');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (209, 'Arleta', 'Castiblanco', '48 1st Hill', '1101354970', 'acastiblanco5s@redcross.org', '3D', 10, 110, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (210, 'Nilson', 'Hickisson', '2951 Birchwood Trail', '1162591612', 'nhickisson5t@nps.gov', '13B', 1, 15, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (211, 'Bren', 'Pittway', '119 Becker Terrace', '1181372569', 'bpittway5u@google.it', '8C', 3, 115, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (212, 'Yetty', 'Sivyour', '0 Paget Drive', '1178014404', 'ysivyour5v@pagesperso-orange.fr', '11C', 6, 108, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (213, 'Marijo', 'Pennycuick', '2 Hoffman Parkway', '1153637495', 'mpennycuick5w@quantcast.com', '5B', 9, 96, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (214, 'Kial', 'Hurt', '597 Schlimgen Pass', '1179264463', 'khurt5x@technorati.com', '1A', 1, 116, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (215, 'Dimitry', 'Hover', '9541 Donald Plaza', '1125045199', 'dhover5y@msn.com', '9D', 9, 19, '1.98');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (216, 'Angele', 'Bradborne', '1513 Center Trail', '1137163660', 'abradborne5z@g.co', '15E', 6, 39, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (217, 'Farleigh', 'Coweuppe', '76 Drewry Avenue', '1125384033', 'fcoweuppe60@hc360.com', '2F', 5, 70, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (218, 'Tyne', 'Luckey', '89134 Summerview Terrace', '1122695122', 'tluckey61@wikipedia.org', '11C', 2, 30, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (219, 'Winne', 'Ellerbeck', '284 Tomscot Junction', '1188919364', 'wellerbeck62@guardian.co.uk', '8C', 8, 59, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (220, 'Elysia', 'Orred', '6 Rieder Park', '1175502649', 'eorred63@opera.com', '15A', 4, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (221, 'Aliza', 'Kores', '5 Harbort Place', '1109492447', 'akores64@latimes.com', '1A', 10, 29, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (222, 'Grannie', 'Henkmann', '934 Chinook Point', '1113824253', 'ghenkmann65@cbslocal.com', '15E', 1, 58, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (223, 'Bekki', 'Timeby', '7 Hoepker Park', '1139216655', 'btimeby66@360.cn', '1E', 4, 13, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (224, 'Janeta', 'Leneve', '94 Burning Wood Road', '1126555966', 'jleneve67@wufoo.com', '5D', 2, 58, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (225, 'Donica', 'Blayd', '7 Ronald Regan Avenue', '1167521398', 'dblayd68@51.la', '15A', 3, 9, '1.36');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (226, 'Rodolph', 'Dyerson', '0 Duke Way', '1191096418', 'rdyerson69@hubpages.com', '29C', 3, 51, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (227, 'Carmelia', 'Fletcher', '38 Shasta Hill', '1127104475', 'cfletcher6a@japanpost.jp', '4A', 7, 79, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (228, 'Ivan', 'Camilleri', '57528 Pine View Avenue', '1127803207', 'icamilleri6b@cargocollective.com', '5E', 9, 67, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (229, 'Bondy', 'Henstridge', '3551 Towne Road', '1129519906', 'bhenstridge6c@hatena.ne.jp', '12B', 8, 43, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (230, 'Magnum', 'Kastel', '205 Ryan Place', '1170934270', 'mkastel6d@miitbeian.gov.cn', '1C', 9, 79, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (231, 'Nicholle', 'Buckle', '388 Gerald Junction', '1128518211', 'nbuckle6e@guardian.co.uk', '17B', 1, 92, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (232, 'Tracey', 'Fellgatt', '7 Portage Crossing', '1134705487', 'tfellgatt6f@sbwire.com', '2C', 4, 73, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (233, 'Alexandro', 'Tokley', '8716 Porter Street', '1157085340', 'atokley6g@usgs.gov', '15F', 7, 89, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (234, 'Cherish', 'Jaine', '4467 Briar Crest Point', '1101679195', 'cjaine6h@vimeo.com', '29F', 1, 52, '1.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (235, 'Darnall', 'Tidbury', '81 Quincy Junction', '1158012154', 'dtidbury6i@chronoengine.com', '29B', 6, 52, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (236, 'Bobby', 'Bothwell', '9584 Algoma Parkway', '1163193676', 'bbothwell6j@list-manage.com', '9B', 7, 104, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (237, 'Bastian', 'Gilbody', '891 Jay Road', '1134172782', 'bgilbody6k@nsw.gov.au', '7F', 2, 30, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (238, 'Othella', 'Hakes', '9982 Sundown Junction', '1150637098', 'ohakes6l@usgs.gov', '6F', 5, 107, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (239, 'Hakeem', 'Lamberti', '1 Sugar Way', '1177743427', 'hlamberti6m@sciencedirect.com', '24F', 8, 5, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (240, 'Craggy', 'Mynett', '51760 Randy Drive', '1149931931', 'cmynett6n@merriam-webster.com', '3D', 8, 101, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (241, 'Cory', 'Storah', '7 Manufacturers Circle', '1194064354', 'cstorah6o@devhub.com', '1C', 8, 57, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (242, 'Harri', 'Lichfield', '1357 Rowland Alley', '1165640531', 'hlichfield6p@princeton.edu', '1E', 3, 7, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (243, 'Daron', 'MacNally', '21309 Reindahl Drive', '1144513596', 'dmacnally6q@oaic.gov.au', '2A', 4, 79, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (244, 'Deeyn', 'Whapple', '528 Spohn Alley', '1137881126', 'dwhapple6r@geocities.jp', '5D', 6, 64, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (245, 'Jonas', 'Ahrendsen', '30061 Northland Terrace', '1134239881', 'jahrendsen6s@msu.edu', '28C', 7, 30, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (246, 'Magdalen', 'Graddell', '4 Westend Circle', '1177952420', 'mgraddell6t@miibeian.gov.cn', '7C', 4, 98, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (247, 'Norine', 'Claeskens', '673 Moose Road', '1156583192', 'nclaeskens6u@linkedin.com', '12B', 3, 90, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (248, 'Sebastien', 'Bauldrey', '58797 Eastlawn Place', '1125577584', 'sbauldrey6v@uiuc.edu', '2E', 7, 9, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (249, 'Molly', 'Vase', '67 Browning Way', '1164521192', 'mvase6w@virginia.edu', '12F', 8, 33, '2.44');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (250, 'Hilliary', 'Sprosson', '8536 Talmadge Point', '1115814277', 'hsprosson6x@psu.edu', '6D', 5, 100, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (251, 'Vevay', 'Gilgryst', '23882 Cordelia Avenue', '1166929712', 'vgilgryst6y@cbslocal.com', '13A', 3, 114, '1.51');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (252, 'Ofelia', 'Balazin', '82 Mallory Plaza', '1125372154', 'obalazin6z@google.co.jp', '4A', 5, 68, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (253, 'Roze', 'Elloit', '00420 Thompson Park', '1151329115', 'relloit70@nifty.com', '15D', 6, 28, '1.36');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (254, 'Bobbe', 'Raynes', '1421 Sauthoff Hill', '1155264606', 'braynes71@weather.com', '8B', 7, 105, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (255, 'Alexandros', 'Germaine', '9 Manley Parkway', '1193280177', 'agermaine72@bing.com', '16E', 4, 46, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (256, 'Saundra', 'Hedaux', '3443 Mcguire Road', '1118715940', 'shedaux73@usa.gov', '24A', 4, 114, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (257, 'Freida', 'Bouda', '1 Steensland Terrace', '1160473011', 'fbouda74@reverbnation.com', '4E', 7, 64, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (258, 'Maddie', 'Turban', '02 Monica Trail', '1120478630', 'mturban75@google.it', '22E', 7, 21, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (259, 'Don', 'Ary', '1 Fulton Center', '1111492423', 'dary76@disqus.com', '23E', 2, 68, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (260, 'Ludovika', 'Izzett', '53230 Derek Alley', '1125406810', 'lizzett77@wordpress.org', '26F', 8, 22, '1.09');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (261, 'Herschel', 'Gertray', '56529 Cherokee Junction', '1162644196', 'hgertray78@hp.com', '7C', 3, 37, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (262, 'Christy', 'Hiner', '0 Jackson Circle', '1145856156', 'chiner79@psu.edu', '3C', 1, 1, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (263, 'Gwenette', 'Chellingworth', '38 Bartelt Park', '1112305365', 'gchellingworth7a@wikia.com', '4E', 8, 71, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (264, 'Enos', 'Crennell', '4 Westerfield Park', '1190343745', 'ecrennell7b@vkontakte.ru', '1E', 7, 73, '1.61');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (265, 'Ethe', 'Kinder', '63 Chinook Lane', '1160580330', 'ekinder7c@gmpg.org', '4F', 7, 108, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (266, 'Onofredo', 'Dufer', '8524 Schlimgen Center', '1154521888', 'odufer7d@deliciousdays.com', '6A', 5, 65, '1.82');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (267, 'Lani', 'Tallboy', '4 Valley Edge Pass', '1134432393', 'ltallboy7e@seattletimes.com', '2F', 7, 68, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (268, 'Thibaud', 'Nolton', '69746 Dixon Alley', '1122987959', 'tnolton7f@netlog.com', '8F', 6, 1, '2.15');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (269, 'Beryl', 'Faughey', '1 Manitowish Parkway', '1150508215', 'bfaughey7g@dagondesign.com', '5E', 10, 33, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (270, 'Brendon', 'Tomovic', '27074 Arapahoe Point', '1194884550', 'btomovic7h@scientificamerican.com', '7F', 3, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (271, 'Tatiania', 'Patria', '55828 Stang Street', '1170795584', 'tpatria7i@multiply.com', '18D', 2, 22, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (272, 'Lin', 'Mushet', '1 Acker Terrace', '1198682609', 'lmushet7j@pcworld.com', '9D', 10, 113, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (273, 'Kelila', 'Clubley', '768 Esch Avenue', '1110238812', 'kclubley7k@123-reg.co.uk', '16D', 3, 27, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (274, 'Paolina', 'Scotchbourouge', '135 Monument Trail', '1164496868', 'pscotchbourouge7l@cbslocal.com', '28F', 1, 57, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (275, 'Roxine', 'Stych', '9079 Marquette Avenue', '1192680530', 'rstych7m@com.com', '23D', 10, 98, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (276, 'Kaleb', 'Easman', '95303 Colorado Crossing', '1178587677', 'keasman7n@bbc.co.uk', '6C', 1, 67, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (277, 'Gisella', 'Housam', '634 Banding Alley', '1195175978', 'ghousam7o@quantcast.com', '4D', 4, 24, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (278, 'Marline', 'Gritskov', '94009 Warner Crossing', '1157493708', 'mgritskov7p@edublogs.org', '25B', 2, 70, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (279, 'Andeee', 'Quemby', '2 Northport Pass', '1105353421', 'aquemby7q@smugmug.com', '13A', 9, 98, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (280, 'Rafferty', 'Guenther', '02 Gerald Pass', '1152006498', 'rguenther7r@ucoz.ru', '1B', 9, 12, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (281, 'Aigneis', 'Lucken', '819 Hoffman Junction', '1164186114', 'alucken7s@geocities.com', '7C', 10, 79, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (282, 'Gnni', 'Beedon', '1644 David Way', '1149025729', 'gbeedon7t@wikia.com', '4D', 8, 23, '1.47');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (283, 'Brandie', 'Marquez', '67933 Marquette Road', '1177453267', 'bmarquez7u@google.com.hk', '19A', 4, 82, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (284, 'Walther', 'Licence', '4081 Toban Way', '1185920431', 'wlicence7v@skype.com', '7E', 4, 21, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (285, 'Tiphani', 'Formoy', '0 Crowley Lane', '1162286326', 'tformoy7w@amazon.com', '19B', 4, 5, '1.50');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (286, 'Lyssa', 'Bronger', '196 Fordem Center', '1130919693', 'lbronger7x@networkadvertising.org', '14C', 8, 101, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (287, 'Rodrick', 'Kinze', '077 Reindahl Lane', '1118652223', 'rkinze7y@cisco.com', '1D', 10, 85, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (288, 'Andriette', 'Fruchon', '6570 Oak Valley Junction', '1136308880', 'afruchon7z@webs.com', '9A', 3, 106, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (289, 'Madelaine', 'Ascough', '6919 Fulton Court', '1154489433', 'mascough80@ustream.tv', '7A', 1, 19, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (290, 'Cleveland', 'Georgeou', '1 Shasta Way', '1181420645', 'cgeorgeou81@phoca.cz', '21A', 8, 49, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (291, 'Leah', 'Hallan', '12672 Cody Way', '1172372945', 'lhallan82@ameblo.jp', '7F', 6, 61, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (292, 'Roxanna', 'Leathwood', '9 Norway Maple Street', '1124109188', 'rleathwood83@nationalgeographic.com', '5F', 3, 45, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (293, 'Modestia', 'Couroy', '92551 Goodland Junction', '1189724766', 'mcouroy84@bizjournals.com', '8B', 8, 67, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (294, 'Cyrill', 'MacClinton', '796 Longview Avenue', '1165273094', 'cmacclinton85@simplemachines.org', '9E', 6, 49, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (295, 'Bartholomew', 'Renfield', '0942 Montana Terrace', '1178823943', 'brenfield86@mapquest.com', '17B', 7, 77, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (296, 'Dorthea', 'Soldan', '41 Service Crossing', '1103712698', 'dsoldan87@tumblr.com', '22D', 2, 60, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (297, 'Lucilia', 'Hillatt', '277 Prairieview Avenue', '1100843609', 'lhillatt88@discovery.com', '27F', 5, 36, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (298, 'Alyce', 'Cattel', '0065 Badeau Crossing', '1118489655', 'acattel89@devhub.com', '2D', 1, 78, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (299, 'Con', 'Gaymer', '0203 Quincy Way', '1172759406', 'cgaymer8a@webs.com', '3A', 7, 97, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (300, 'Abbot', 'St Ledger', '394 Shelley Road', '1117520421', 'astledger8b@mapquest.com', '3D', 5, 56, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (301, 'Dominga', 'Coils', '76054 Ryan Trail', '1184381128', 'dcoils8c@nytimes.com', '8D', 10, 81, '1.96');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (302, 'Juieta', 'Halfacree', '830 Kim Terrace', '1161278228', 'jhalfacree8d@51.la', '25F', 2, 59, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (303, 'Robby', 'Parken', '2751 Warner Park', '1105795522', 'rparken8e@theglobeandmail.com', '9D', 6, 104, '2.28');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (304, 'Virginia', 'Belfield', '257 Evergreen Circle', '1106956926', 'vbelfield8f@opensource.org', '5B', 5, 59, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (305, 'Darda', 'Coltart', '0 Stoughton Drive', '1151189188', 'dcoltart8g@imageshack.us', '5F', 2, 51, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (306, 'Cynthia', 'Corder', '55 Monterey Trail', '1162354549', 'ccorder8h@baidu.com', '5A', 3, 29, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (307, 'Elie', 'Lethieulier', '757 Vidon Court', '1137748427', 'elethieulier8i@prweb.com', '22B', 6, 31, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (308, 'Farlie', 'Rhodus', '761 Ronald Regan Lane', '1181343841', 'frhodus8j@qq.com', '21D', 6, 106, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (309, 'Kimberlee', 'Skevington', '950 Morningstar Circle', '1144267404', 'kskevington8k@issuu.com', '19B', 9, 58, '2.16');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (310, 'Reagan', 'Amori', '5120 Warrior Circle', '1178743262', 'ramori8l@ustream.tv', '5E', 1, 91, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (311, 'Sarajane', 'Nardrup', '4489 Atwood Road', '1169515455', 'snardrup8m@jimdo.com', '28A', 6, 26, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (312, 'Filmore', 'Lestrange', '7 Thompson Place', '1189540338', 'flestrange8n@unicef.org', '8F', 1, 82, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (313, 'Hildagarde', 'Van', '6524 Hauk Terrace', '1182161688', 'hvan8o@slashdot.org', '8D', 6, 76, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (314, 'Archibold', 'Pressland', '6249 Commercial Crossing', '1143497401', 'apressland8p@odnoklassniki.ru', '26C', 1, 106, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (315, 'Shepherd', 'Baud', '16459 School Terrace', '1127425904', 'sbaud8q@naver.com', '14B', 10, 46, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (316, 'Cindee', 'Wimes', '05 6th Junction', '1166601500', 'cwimes8r@accuweather.com', '5B', 6, 86, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (317, 'Bobbe', 'Pasticznyk', '32 Green Park', '1132643566', 'bpasticznyk8s@addtoany.com', '8A', 2, 35, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (318, 'Ogden', 'Zannolli', '823 Pawling Lane', '1120296223', 'ozannolli8t@redcross.org', '18A', 6, 33, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (319, 'Glenna', 'Eyeington', '347 Coolidge Center', '1142597100', 'geyeington8u@apple.com', '12F', 4, 98, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (320, 'Abbi', 'Terne', '75647 Pepper Wood Avenue', '1134867343', 'aterne8v@facebook.com', '21F', 2, 81, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (321, 'Art', 'Claris', '09 Bunting Way', '1169392717', 'aclaris8w@gov.uk', '29C', 7, 69, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (322, 'Carroll', 'Shortcliffe', '2 Norway Maple Hill', '1177051492', 'cshortcliffe8x@pen.io', '24F', 9, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (323, 'Jacinda', 'Roony', '9 American Drive', '1120480475', 'jroony8y@merriam-webster.com', '2E', 3, 49, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (324, 'Yard', 'Phizackarley', '685 Grover Place', '1175474811', 'yphizackarley8z@so-net.ne.jp', '7E', 10, 88, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (325, 'Jorie', 'Whyteman', '01 Onsgard Crossing', '1169387435', 'jwhyteman90@canalblog.com', '3D', 6, 72, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (326, 'Pavel', 'Bossingham', '2916 Village Crossing', '1115179813', 'pbossingham91@narod.ru', '8E', 5, 56, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (327, 'Aeriell', 'Kisting', '62107 Heffernan Alley', '1104268313', 'akisting92@forbes.com', '4B', 6, 101, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (328, 'Robinet', 'Blower', '4 Cascade Court', '1149304568', 'rblower93@feedburner.com', '17D', 6, 40, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (329, 'Rora', 'Hamill', '36907 Independence Avenue', '1149882614', 'rhamill94@instagram.com', '9D', 5, 10, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (330, 'Dionne', 'Gartenfeld', '65 Texas Street', '1129386940', 'dgartenfeld95@google.de', '7A', 5, 57, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (331, 'Giacomo', 'Fann', '6 Melrose Point', '1199143784', 'gfann96@umn.edu', '15A', 5, 36, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (332, 'Lana', 'Lott', '69270 Spenser Avenue', '1145619917', 'llott97@live.com', '26A', 8, 82, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (333, 'Talyah', 'Benditt', '98 Parkside Point', '1130238665', 'tbenditt98@dropbox.com', '14E', 5, 22, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (334, 'Goddart', 'De Carteret', '35 Scoville Park', '1128349608', 'gdecarteret99@craigslist.org', '3D', 7, 51, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (335, 'Ina', 'Tryme', '3 Caliangt Drive', '1104989897', 'itryme9a@sitemeter.com', '7A', 2, 14, '1.22');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (336, 'Rock', 'Wandrey', '01871 Claremont Park', '1180461045', 'rwandrey9b@webeden.co.uk', '27C', 8, 35, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (337, 'Leonardo', 'Jacquemy', '62409 Scoville Junction', '1185891180', 'ljacquemy9c@tmall.com', '4D', 1, 95, '1.35');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (338, 'Clem', 'Firbank', '78802 Novick Park', '1164327488', 'cfirbank9d@scientificamerican.com', '9E', 4, 92, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (339, 'Lacy', 'Pickthorne', '28548 Vahlen Alley', '1150814836', 'lpickthorne9e@twitpic.com', '8D', 2, 57, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (340, 'Blondelle', 'Dillestone', '06 Pennsylvania Terrace', '1172194711', 'bdillestone9f@bloomberg.com', '28A', 7, 76, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (341, 'Danice', 'Grigoliis', '3 Jenifer Plaza', '1161697813', 'dgrigoliis9g@webnode.com', '1D', 5, 72, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (342, 'Francois', 'Hambric', '5050 Melrose Point', '1120416727', 'fhambric9h@mozilla.org', '14A', 2, 117, '2.43');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (343, 'Ginger', 'Hughes', '6 Macpherson Point', '1188514619', 'ghughes9i@ihg.com', '6A', 8, 81, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (344, 'Gran', 'Melato', '7 Valley Edge Parkway', '1156952657', 'gmelato9j@sciencedirect.com', '4D', 7, 42, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (345, 'Hollyanne', 'Pavluk', '7 Nobel Center', '1146249530', 'hpavluk9k@google.com.au', '25A', 7, 52, '1.6');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (346, 'Mortie', 'Cullin', '394 Pine View Street', '1126638111', 'mcullin9l@oracle.com', '27A', 5, 91, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (347, 'Tonye', 'Duffyn', '4569 Amoth Plaza', '1121939226', 'tduffyn9m@wordpress.org', '5D', 2, 29, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (348, 'Jonis', 'Haslin', '88 Kedzie Street', '1149216627', 'jhaslin9n@imdb.com', '4B', 3, 56, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (349, 'Byran', 'Mingauld', '61 Dixon Court', '1195592646', 'bmingauld9o@unesco.org', '4B', 6, 88, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (350, 'Hector', 'Castillo', '70731 Russell Street', '1196777282', 'hcastillo9p@wordpress.org', '9D', 10, 13, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (351, 'Noah', 'Rikkard', '1 Vernon Road', '1155556186', 'nrikkard9q@symantec.com', '8E', 3, 54, '1.74');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (352, 'Ruggiero', 'Esslement', '3 Cherokee Plaza', '1106468890', 'resslement9r@marriott.com', '5E', 4, 27, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (353, 'Selia', 'Kingscott', '38 Parkside Avenue', '1154806964', 'skingscott9s@addthis.com', '26D', 1, 109, '2.09');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (354, 'Neala', 'Edgehill', '30 Pawling Circle', '1161498037', 'nedgehill9t@vinaora.com', '15D', 9, 18, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (355, 'Clemmie', 'Ales0', '2600 Merchant Street', '1124988030', 'cales9u@businessinsider.com', '16B', 1, 113, '2.44');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (356, 'Marchelle', 'Coxwell', '18 Nova Alley', '1187786044', 'mcoxwell9v@europa.eu', '24F', 7, 76, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (357, 'Pren', 'Klamp', '86684 South Point', '1185124579', 'pklamp9w@parallels.com', '5B', 2, 110, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (358, 'Elmer', 'Ullrich', '08 Mockingbird Drive', '1165052460', 'eullrich9x@noaa.gov', '29F', 2, 36, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (359, 'Bogey', 'Craster', '21 Del Sol Place', '1160805878', 'bcraster9y@i2i.jp', '24F', 1, 32, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (360, 'Rabi', 'Lindsley', '29329 Florence Lane', '1124017893', 'rlindsley9z@last.fm', '1A', 7, 65, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (361, 'Stephenie', 'Dotterill', '87 Upham Trail', '1168431381', 'sdotterilla0@barnesandnoble.com', '4A', 4, 25, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (362, 'Marty', 'Evered', '605 Coleman Pass', '1152812912', 'mevereda1@amazon.co.uk', '5C', 4, 27, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (363, 'Natka', 'Edmondson', '92 Sloan Circle', '1138084668', 'nedmondsona2@telegraph.co.uk', '4A', 3, 40, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (364, 'Terrye', 'Brackenridge', '11748 Loomis Pass', '1100261789', 'tbrackenridgea3@mlb.com', '18F', 10, 119, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (365, 'Meryl', 'Shwenn', '894 Morningstar Way', '1145799635', 'mshwenna4@ehow.com', '3F', 1, 80, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (366, 'Ely', 'Butcher', '6872 Gateway Hill', '1184352439', 'ebutchera5@springer.com', '27B', 6, 13, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (367, 'Camala', 'Cunningham', '336 Moose Way', '1155355095', 'ccunninghama6@furl.net', '5F', 5, 74, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (368, 'Ainsley', 'Slinger', '3 Hoepker Trail', '1120650670', 'aslingera7@tiny.cc', '16F', 10, 110, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (369, 'Che', 'Firby', '928 Gulseth Crossing', '1197403476', 'cfirbya8@ihg.com', '3E', 1, 48, '1.10');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (370, 'Kora', 'Mortell', '1 Burning Wood Terrace', '1176023805', 'kmortella9@hc360.com', '29D', 6, 120, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (371, 'Herschel', 'O''Hannay', '039 Summer Ridge Parkway', '1117649537', 'hohannayaa@tamu.edu', '1E', 6, 76, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (372, 'Ramonda', 'Riddock', '491 Bowman Pass', '1112406741', 'rriddockab@google.co.uk', '2C', 4, 115, '2.22');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (373, 'Lelah', 'Ible', '4253 Banding Road', '1113300928', 'libleac@yandex.ru', '2A', 2, 68, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (374, 'Stoddard', 'Rickerby', '349 Briar Crest Parkway', '1131150061', 'srickerbyad@feedburner.com', '3C', 4, 8, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (375, 'Ailbert', 'Coldwell', '9086 Continental Place', '1108556172', 'acoldwellae@gov.uk', '29A', 2, 87, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (376, 'Dorie', 'Eastbury', '30111 Everett Junction', '1108847079', 'deastburyaf@privacy.gov.au', '4F', 9, 75, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (377, 'Lambert', 'Driutti', '92 Carioca Junction', '1108750930', 'ldriuttiag@yahoo.com', '18D', 4, 55, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (378, 'Emelda', 'Szwarc', '180 Logan Terrace', '1185087368', 'eszwarcah@google.fr', '2D', 9, 91, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (379, 'Amalia', 'Soitoux', '5 Monument Crossing', '1197087216', 'asoitouxai@oakley.com', '15D', 5, 51, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (380, 'Karrah', 'Dunbobin', '45745 Chive Hill', '1135090583', 'kdunbobinaj@hugedomains.com', '27A', 1, 27, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (381, 'Evey', 'Brabon', '4329 Eliot Drive', '1190049293', 'ebrabonak@bluehost.com', '3F', 7, 43, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (382, 'Yorker', 'Antognetti', '2 John Wall Lane', '1117944989', 'yantognettial@google.ru', '14E', 6, 70, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (383, 'Prescott', 'Westmarland', '930 Hintze Junction', '1152636068', 'pwestmarlandam@pbs.org', '5E', 5, 118, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (384, 'Tremayne', 'Blything', '118 Express Place', '1150130698', 'tblythingan@instagram.com', '15B', 1, 110, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (385, 'Pattin', 'Corhard', '34390 Forest Dale Court', '1182178926', 'pcorhardao@ameblo.jp', '2A', 1, 114, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (386, 'Farlie', 'Seyers', '70 Mockingbird Alley', '1124609936', 'fseyersap@hugedomains.com', '25F', 7, 4, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (387, 'Chancey', 'Ellershaw', '3756 Nancy Plaza', '1155022714', 'cellershawaq@jiathis.com', '12D', 10, 50, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (388, 'Nicol', 'Abrahart', '11953 Farmco Crossing', '1153217104', 'nabrahartar@cafepress.com', '3D', 1, 38, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (389, 'Domenic', 'Galland', '64 Clemons Pass', '1162055562', 'dgallandas@walmart.com', '1E', 8, 29, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (390, 'Dorrie', 'Edmeades', '0791 Pleasure Pass', '1150709233', 'dedmeadesat@usatoday.com', '16F', 8, 88, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (391, 'Merill', 'Payne', '61643 Clove Parkway', '1115926908', 'mpayneau@scientificamerican.com', '6C', 5, 29, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (392, 'Emmery', 'Youd', '024 Clemons Court', '1136688983', 'eyoudav@imageshack.us', '1F', 6, 53, '1.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (393, 'Ilyse', 'Giovannilli', '52 Novick Plaza', '1190767237', 'igiovannilliaw@infoseek.co.jp', '18B', 10, 85, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (394, 'Missie', 'Shaul', '7 Sommers Street', '1167418526', 'mshaulax@stumbleupon.com', '28E', 6, 52, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (395, 'Dar', 'Alpine', '78005 Algoma Street', '1115478470', 'dalpineay@shutterfly.com', '13E', 9, 119, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (396, 'Heath', 'Spillane', '70 Fieldstone Circle', '1165361646', 'hspillaneaz@dion.ne.jp', '23B', 3, 95, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (397, 'Devina', 'MacKeague', '672 Village Way', '1132976152', 'dmackeagueb0@china.com.cn', '14C', 5, 58, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (398, 'Janie', 'Osbourn', '738 Columbus Circle', '1142882792', 'josbournb1@wp.com', '29D', 2, 95, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (399, 'Kizzie', 'Darinton', '92917 Oakridge Drive', '1154699246', 'kdarintonb2@xrea.com', '8B', 2, 39, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (400, 'Teddy', 'Rackham', '26039 Pankratz Avenue', '1193379479', 'trackhamb3@nydailynews.com', '6D', 9, 81, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (401, 'Ario', 'Orchart', '8 Little Fleur Avenue', '1143571198', 'aorchartb4@paypal.com', '4F', 5, 82, '1.13');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (402, 'Reeva', 'Danko', '129 Sycamore Pass', '1141265129', 'rdankob5@whitehouse.gov', '1B', 1, 78, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (403, 'Elisha', 'Purnell', '09853 Surrey Way', '1180069118', 'epurnellb6@sun.com', '28C', 8, 61, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (404, 'Fedora', 'Gent', '0 Division Avenue', '1163108894', 'fgentb7@washingtonpost.com', '4A', 9, 25, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (405, 'Shani', 'Ketton', '2 Cordelia Circle', '1130960679', 'skettonb8@theatlantic.com', '11B', 6, 113, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (406, 'Evvie', 'Donnellan', '3306 Independence Road', '1140416361', 'edonnellanb9@huffingtonpost.com', '1B', 1, 18, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (407, 'Di', 'Kinney', '99 Duke Trail', '1118836625', 'dkinneyba@shop-pro.jp', '3E', 9, 94, '1.17');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (408, 'Gayle', 'Crennell', '80619 Boyd Avenue', '1153620208', 'gcrennellbb@cpanel.net', '5B', 9, 94, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (409, 'Caldwell', 'Tythacott', '32 Vahlen Street', '1110599704', 'ctythacottbc@mozilla.org', '2C', 3, 91, '2.24');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (410, 'Hadley', 'Gealy', '3 Moulton Parkway', '1162897953', 'hgealybd@is.gd', '2B', 10, 30, '2.37');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (411, 'Faith', 'Haddleton', '176 Kedzie Court', '1102989299', 'fhaddletonbe@nymag.com', '16C', 2, 24, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (412, 'Carine', 'Beston', '8 Vidon Road', '1134803969', 'cbestonbf@tamu.edu', '19B', 1, 36, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (413, 'Coleman', 'Gland', '5 Atwood Center', '1188225950', 'cglandbg@moonfruit.com', '8B', 9, 52, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (414, 'Ced', 'Carroll', '92 Glacier Hill Crossing', '1149303388', 'ccarrollbh@oaic.gov.au', '6F', 5, 80, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (415, 'Karita', 'Brinklow', '932 Glendale Junction', '1111877667', 'kbrinklowbi@barnesandnoble.com', '9A', 6, 30, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (416, 'Rory', 'Holliar', '6 Northport Court', '1129900286', 'rholliarbj@mac.com', '19B', 5, 43, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (417, 'Alexi', 'Farryn', '6 Center Park', '1150123319', 'afarrynbk@godaddy.com', '3F', 10, 77, '1.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (418, 'Hercule', 'Peever', '05 Bayside Street', '1130257341', 'hpeeverbl@wikimedia.org', '11D', 5, 33, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (419, 'Heda', 'Bakesef', '929 Service Junction', '1106799200', 'hbakesefbm@cbc.ca', '13D', 5, 102, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (420, 'Edith', 'Chevis', '497 Sheridan Junction', '1137477659', 'echevisbn@dailymotion.com', '6E', 8, 21, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (421, 'Nonna', 'Coalbran', '39631 Lake View Place', '1113670908', 'ncoalbranbo@nationalgeographic.com', '22C', 10, 12, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (422, 'Dagmar', 'Sayers', '1 Bartillon Place', '1109401925', 'dsayersbp@ftc.gov', '7E', 1, 88, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (423, 'Ursa', 'Dabbes', '42 Transport Crossing', '1134788546', 'udabbesbq@lulu.com', '29B', 5, 106, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (424, 'Laurella', 'Morteo', '89 Starling Alley', '1118202335', 'lmorteobr@desdev.cn', '28D', 9, 81, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (425, 'Bruno', 'Ould', '6742 Westridge Junction', '1128875605', 'bouldbs@yahoo.co.jp', '2C', 1, 40, '1.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (426, 'Tilly', 'Locock', '664 Moland Way', '1110706876', 'tlocockbt@dedecms.com', '25C', 9, 8, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (427, 'Loleta', 'Roels', '1947 Texas Parkway', '1141596126', 'lroelsbu@examiner.com', '15A', 8, 60, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (428, 'Akim', 'Scatcher', '9037 Mcbride Park', '1186689708', 'ascatcherbv@bbc.co.uk', '29C', 1, 47, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (429, 'Jeremy', 'Nealon', '6449 Arapahoe Drive', '1161077769', 'jnealonbw@mysql.com', '2A', 7, 63, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (430, 'Ralina', 'Brothers', '227 Elmside Terrace', '1162485816', 'rbrothersbx@ebay.com', '2F', 4, 46, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (431, 'Sibeal', 'Burdikin', '17219 Manley Street', '1160632499', 'sburdikinby@chicagotribune.com', '1E', 4, 39, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (432, 'Eilis', 'Worssam', '9383 Springview Parkway', '1180809344', 'eworssambz@wufoo.com', '24D', 8, 4, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (433, 'Davide', 'Evelyn', '5440 Ludington Hill', '1189731196', 'develync0@cpanel.net', '3E', 5, 117, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (434, 'Elwira', 'Bark', '44 Ohio Hill', '1103924972', 'ebarkc1@vistaprint.com', '13C', 5, 35, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (435, 'Tull', 'Chugg', '035 Petterle Park', '1165707521', 'tchuggc2@java.com', '13D', 2, 3, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (436, 'Claiborne', 'Christopherson', '9 Garrison Crossing', '1154991421', 'cchristophersonc3@loc.gov', '7F', 10, 17, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (437, 'Claudetta', 'Yosselevitch', '73 Kim Trail', '1115100650', 'cyosselevitchc4@behance.net', '18E', 1, 18, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (438, 'Melinde', 'Biaggioli', '958 Little Fleur Trail', '1172824823', 'mbiaggiolic5@google.com', '13B', 2, 64, '1.26');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (439, 'Cindie', 'Airs', '31011 Vermont Center', '1180639520', 'cairsc6@tiny.cc', '6F', 6, 119, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (440, 'Doralia', 'Semmens', '19748 Forster Hill', '1129324223', 'dsemmensc7@squarespace.com', '5C', 3, 62, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (441, 'Wilmar', 'Longson', '40641 Hintze Parkway', '1178263014', 'wlongsonc8@phoca.cz', '4B', 6, 10, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (442, 'Phillip', 'Kierans', '23912 Moose Center', '1182806929', 'pkieransc9@nps.gov', '2E', 4, 105, '1.9');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (443, 'Eartha', 'Woodhall', '8155 Starling Avenue', '1107156997', 'ewoodhallca@whitehouse.gov', '5F', 2, 20, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (444, 'Marianne', 'McKirton', '730 Thackeray Junction', '1124259878', 'mmckirtoncb@weebly.com', '19B', 10, 119, '1.62');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (445, 'Leopold', 'De Bruyn', '49 Spaight Drive', '1113450756', 'ldebruyncc@redcross.org', '5A', 2, 39, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (446, 'Pietro', 'Tunny', '31802 Laurel Junction', '1153544941', 'ptunnycd@state.tx.us', '27E', 9, 32, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (447, 'Jake', 'Eltone', '8771 Dottie Way', '1118382609', 'jeltonece@indiatimes.com', '12D', 4, 89, '1.24');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (448, 'Tannie', 'Schmidt', '1 Starling Lane', '1127382122', 'tschmidtcf@pagesperso-orange.fr', '19D', 3, 94, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (449, 'Patti', 'Sheirlaw', '582 Brickson Park Terrace', '1123847542', 'psheirlawcg@w3.org', '9A', 6, 89, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (450, 'Lurleen', 'Scholcroft', '0850 Elmside Place', '1118416436', 'lscholcroftch@free.fr', '26D', 2, 34, '2.2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (451, 'Matty', 'Garlicke', '0 Nelson Park', '1188670700', 'mgarlickeci@cnet.com', '21E', 4, 27, '2.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (452, 'Lulu', 'Aleswell', '46561 Crowley Terrace', '1175169861', 'laleswellcj@home.pl', '5A', 10, 78, '1.12');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (453, 'Merrilee', 'Rushworth', '52013 Moose Pass', '1192143641', 'mrushworthck@w3.org', '19C', 3, 82, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (454, 'Arel', 'Tregoning', '8 Pearson Plaza', '1162608968', 'atregoningcl@mayoclinic.com', '1B', 4, 105, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (455, 'Etan', 'Bedenham', '90 Hintze Road', '1187986462', 'ebedenhamcm@fastcompany.com', '17A', 7, 32, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (456, 'Reid', 'Luto', '6784 Autumn Leaf Street', '1189651109', 'rlutocn@amazon.com', '13D', 8, 20, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (457, 'Prent', 'Stuttman', '7 Homewood Junction', '1130037709', 'pstuttmanco@techcrunch.com', '5B', 2, 6, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (458, 'Cherice', 'Garrique', '93 Veith Road', '1164682994', 'cgarriquecp@si.edu', '2B', 5, 5, '1.8');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (459, 'Jefferson', 'Caulder', '0 Butternut Avenue', '1156423358', 'jcauldercq@nbcnews.com', '3A', 3, 30, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (460, 'Vasily', 'Coy', '73532 Barby Pass', '1136841306', 'vcoycr@springer.com', '15B', 5, 113, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (461, 'Deni', 'Brownscombe', '654 Dahle Parkway', '1107999765', 'dbrownscombecs@slideshare.net', '2F', 7, 7, '1.7');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (462, 'Xenos', 'Galia', '7 Vidon Circle', '1133105921', 'xgaliact@soundcloud.com', '2A', 10, 119, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (463, 'Kynthia', 'Ferrie', '486 Melvin Trail', '1180767038', 'kferriecu@cafepress.com', '18A', 7, 61, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (464, 'Perla', 'Livermore', '9015 Prairieview Junction', '1125327916', 'plivermorecv@abc.net.au', '14F', 8, 24, '2.40');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (465, 'Hollie', 'Fawssett', '980 Eastwood Alley', '1157124672', 'hfawssettcw@marketwatch.com', '3C', 3, 120, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (466, 'Michelle', 'Vasilic', '02273 Morning Crossing', '1146797015', 'mvasiliccx@mozilla.org', '2C', 9, 59, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (467, 'Myrlene', 'Haseley', '97 Hermina Point', '1197287726', 'mhaseleycy@usatoday.com', '21F', 5, 5, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (468, 'Goran', 'De Andreis', '34 Londonderry Pass', '1199665942', 'gdeandreiscz@abc.net.au', '22F', 1, 16, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (469, 'Letitia', 'Allicock', '108 Thompson Pass', '1120903916', 'lallicockd0@desdev.cn', '28A', 7, 18, '2.1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (470, 'Esma', 'Coners', '7 Norway Maple Lane', '1154907965', 'econersd1@ehow.com', '7E', 7, 58, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (471, 'Wilden', 'Corballis', '32 Meadow Vale Court', '1109715685', 'wcorballisd2@twitpic.com', '9E', 2, 18, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (472, 'Elroy', 'Antushev', '4399 Bunting Avenue', '1144090201', 'eantushevd3@uiuc.edu', '14C', 3, 39, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (473, 'Rycca', 'Heimann', '8434 Bluejay Way', '1171840135', 'rheimannd4@123-reg.co.uk', '17A', 6, 17, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (474, 'Kristina', 'Garritley', '6 Lyons Pass', '1160965995', 'kgarritleyd5@businessinsider.com', '23F', 6, 108, '1.64');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (475, 'Ravid', 'Caneo', '401 Claremont Hill', '1136864792', 'rcaneod6@shutterfly.com', '2C', 3, 7, '2.06');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (476, 'Kyrstin', 'Eringey', '7 Acker Parkway', '1181286919', 'keringeyd7@amazonaws.com', '9E', 8, 27, '1.90');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (477, 'Tanny', 'Gerrill', '0814 David Lane', '1199216447', 'tgerrilld8@cocolog-nifty.com', '3B', 7, 72, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (478, 'Shawnee', 'Graveney', '9013 Porter Parkway', '1168696375', 'sgraveneyd9@printfriendly.com', '18A', 7, 64, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (479, 'Jeromy', 'Whitsun', '3499 Oneill Lane', '1147576689', 'jwhitsunda@stanford.edu', '16C', 4, 18, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (480, 'Fianna', 'Dreinan', '62 Sunbrook Street', '1198167163', 'fdreinandb@t.co', '4C', 3, 74, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (481, 'Ailis', 'Bowden', '1704 Warrior Way', '1133361741', 'abowdendc@tripadvisor.com', '13F', 4, 62, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (482, 'Binnie', 'Kempster', '34112 Orin Terrace', '1127711192', 'bkempsterdd@amazon.de', '29C', 7, 68, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (483, 'Terry', 'Eite', '836 Mandrake Way', '1137500370', 'teitede@blogger.com', '12A', 8, 10, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (484, 'Darcy', 'Spalton', '43 Mesta Parkway', '1177657369', 'dspaltondf@deviantart.com', '21B', 7, 20, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (485, 'Alisander', 'Claessens', '58939 Gulseth Trail', '1127393544', 'aclaessensdg@hc360.com', '8B', 8, 61, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (486, 'Maia', 'Whyley', '721 Russell Place', '1189387352', 'mwhyleydh@weebly.com', '17A', 3, 30, '1.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (487, 'Danila', 'Crosier', '06 Brickson Park Way', '1156692524', 'dcrosierdi@trellian.com', '19F', 7, 81, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (488, 'Chicky', 'Bottleson', '1870 Pawling Plaza', '1184968825', 'cbottlesondj@privacy.gov.au', '3A', 6, 89, '2.33');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (489, 'Rhonda', 'Kamena', '8286 Rowland Court', '1139642572', 'rkamenadk@ning.com', '2C', 6, 49, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (490, 'Milzie', 'Mugleston', '90 Vera Road', '1165246736', 'mmuglestondl@google.ca', '26A', 3, 12, '2.0');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (491, 'Luther', 'Dowrey', '044 Granby Lane', '1114310414', 'ldowreydm@microsoft.com', '21F', 3, 100, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (492, 'Ezequiel', 'Steels', '5 Wayridge Parkway', '1133434089', 'esteelsdn@storify.com', '13C', 3, 11, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (493, 'Ciel', 'De Bischop', '4649 Declaration Avenue', '1189834374', 'cdebischopdo@cdbaby.com', '11C', 4, 101, '1');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (494, 'Lenee', 'Chittock', '46 Anhalt Alley', '1125425012', 'lchittockdp@nih.gov', '24A', 6, 18, '2.4');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (495, 'Rosabel', 'Lippitt', '21 Aberg Avenue', '1113191756', 'rlippittdq@g.co', '26E', 1, 72, '2');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (496, 'Jermain', 'Libbe', '28 Kim Court', '1122872020', 'jlibbedr@sina.com.cn', '8D', 2, 106, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (497, 'Octavius', 'Rizzello', '58287 Beilfuss Way', '1144124984', 'orizzellods@foxnews.com', '28C', 2, 34, '2.5');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (498, 'Buddie', 'Pittock', '37 Scott Hill', '1159872246', 'bpittockdt@odnoklassniki.ru', '21E', 9, 89, '1.3');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (499, 'Adolf', 'Grocutt', '9 Meadow Vale Center', '1181940975', 'agrocuttdu@naver.com', '21C', 9, 13, '1.83');
insert into Propietarios (id_propietario, nombre, apellido, direccion, telefono, email, departamento, id_consorcio, unidad_funcional, porcentaje_fiscal) values (500, 'Joshuah', 'Conring', '288 Dennis Alley', '1171914680', 'jconringdv@redcross.org', '15D', 3, 101, '2');
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
-- Insertar Reparaciones (100)
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (1, 5, 7, '2471479.06', '2023-06-16', false, '19F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (2, 3, 10, '1523371.60', '2024-04-24', false, '19A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (3, 1, 6, '576802.41', '2024-02-12', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (4, 2, 8, '1972326.17', '2024-03-02', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (5, 1, 5, '2497127.56', '2023-08-14', false, '11E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (6, 7, 5, '826701.74', '2023-10-19', false, '11A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (7, 3, 4, '1561840.9', '2023-07-20', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (8, 2, 1, '2294242.54', '2024-05-11', false, '4F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (9, 2, 4, '1942329.3', '2023-11-19', false, '6E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (10, 5, 10, '2293221.7', '2023-11-02', false, '14A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (11, 2, 1, '579889.3', '2023-08-08', false, '16F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (12, 3, 5, '845491.2', '2024-05-11', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (13, 2, 6, '871151.4', '2023-11-02', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (14, 4, 8, '2188487', '2023-09-30', false, '23A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (15, 8, 10, '587167.29', '2023-07-08', false, '5E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (16, 9, 8, '1775379', '2023-11-30', false, '5E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (17, 10, 2, '317677', '2024-04-07', false, '9B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (18, 10, 1, '2132061.9', '2023-06-21', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (19, 7, 3, '1890262', '2023-09-28', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (20, 7, 10, '2117469', '2024-05-15', false, '15E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (21, 9, 8, '2466790.63', '2024-05-06', false, '23C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (22, 8, 7, '204438.9', '2024-02-27', false, '5B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (23, 6, 4, '1220896', '2024-04-14', false, '22A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (24, 1, 1, '284134.84', '2024-01-18', false, '8C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (25, 7, 10, '2508036', '2023-11-10', false, '8F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (26, 3, 4, '2432961.00', '2024-04-28', false, '24C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (27, 7, 3, '483442', '2023-10-21', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (28, 9, 6, '997527.6', '2023-10-04', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (29, 5, 8, '856072.90', '2023-09-15', false, '15A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (30, 10, 9, '378874', '2023-10-16', false, '23E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (31, 4, 5, '2479525', '2024-04-30', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (32, 8, 10, '552831', '2024-04-10', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (33, 6, 8, '1524753.94', '2024-03-11', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (34, 8, 2, '863145', '2023-10-05', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (35, 2, 1, '703615', '2023-09-18', false, '7A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (36, 7, 8, '2599662', '2023-11-08', false, '7A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (37, 9, 4, '482400', '2023-06-23', false, '3D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (38, 1, 8, '716270.9', '2024-04-22', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (39, 2, 8, '686434.55', '2023-10-03', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (40, 2, 10, '113227.83', '2023-09-23', false, '21C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (41, 10, 2, '911559', '2024-04-16', false, '26F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (42, 9, 10, '412717.93', '2024-04-10', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (43, 8, 2, '618909.10', '2023-07-06', false, '23A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (44, 5, 8, '2974405.67', '2024-04-06', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (45, 10, 2, '2635568.46', '2024-02-29', false, '21F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (46, 7, 2, '1322226', '2024-06-08', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (47, 5, 8, '956043', '2024-04-01', false, '14F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (48, 6, 8, '1336427.87', '2024-02-02', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (49, 5, 2, '931230.49', '2023-12-03', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (50, 5, 9, '452909.3', '2023-07-01', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (51, 6, 3, '1778637', '2024-05-23', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (52, 9, 6, '979439.09', '2024-01-27', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (53, 5, 2, '479174.8', '2024-01-15', false, '8B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (54, 9, 1, '697951.02', '2024-02-06', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (55, 9, 3, '467871', '2024-04-15', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (56, 1, 8, '1743124', '2024-06-02', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (57, 4, 8, '1950682.6', '2023-12-08', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (58, 10, 2, '667471', '2023-11-21', false, '4D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (59, 9, 8, '2903668.27', '2024-03-19', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (60, 10, 5, '2534771', '2023-06-29', false, '5C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (61, 7, 7, '790815', '2024-04-03', false, '3F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (62, 5, 4, '174309', '2024-02-06', false, '11E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (63, 9, 3, '555325.84', '2024-01-05', false, '22B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (64, 9, 6, '2285480.08', '2024-04-05', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (65, 10, 7, '2247806', '2023-12-28', false, '1E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (66, 3, 2, '972239.83', '2023-07-18', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (67, 6, 8, '1578141.8', '2023-09-06', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (68, 10, 7, '1645880.8', '2023-08-03', false, '26A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (69, 1, 2, '975630.59', '2023-07-09', false, '6C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (70, 2, 5, '1131246', '2023-09-06', false, '13D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (71, 4, 9, '2238685', '2024-04-02', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (72, 1, 8, '597178.48', '2023-12-17', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (73, 9, 1, '2618286', '2024-01-04', false, '7B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (74, 1, 3, '2305970.6', '2024-04-30', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (75, 6, 3, '703708.0', '2023-10-24', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (76, 9, 6, '912030.72', '2023-06-20', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (77, 10, 4, '592804.6', '2024-01-20', false, '1B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (78, 7, 5, '539660.16', '2024-05-20', false, '19F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (79, 2, 7, '1184287.4', '2024-01-12', false, '18D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (80, 3, 1, '1897221', '2024-04-27', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (81, 2, 7, '2964263.52', '2023-11-09', false, '6E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (82, 9, 7, '1181754.3', '2024-05-17', false, '21A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (83, 4, 8, '1182143.41', '2024-04-25', false, '5D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (84, 4, 9, '530820', '2023-12-09', false, '4E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (85, 6, 4, '2251466.49', '2024-03-20', false, '26D');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (86, 9, 6, '418225', '2023-10-06', false, '6C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (87, 1, 8, '534665', '2023-10-20', false, '3B');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (88, 1, 8, '995220', '2023-06-23', false, '13F');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (89, 2, 1, '985360', '2024-06-07', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (90, 7, 4, '859230.00', '2024-02-01', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (91, 1, 6, '2185552.6', '2023-08-18', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (92, 1, 5, '2264560.0', '2023-06-26', false, '12A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (93, 8, 5, '1471180', '2023-09-22', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (94, 4, 3, '925962', '2023-08-16', false, '2C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (95, 8, 5, '2914017', '2024-04-19', false, '14E');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (96, 8, 3, '1218221', '2024-01-30', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (97, 9, 7, '1155082', '2023-11-08', true, null);
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (98, 10, 5, '334542.84', '2023-10-12', false, '7A');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (99, 4, 6, '850437.16', '2024-05-19', false, '28C');
insert into Reparaciones (id_reparacion, id_proveedor, id_consorcio, costo_total, fecha, reparacion_comun, departamento) values (100, 10, 4, '2546066', '2024-01-03', true, null);
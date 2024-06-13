-- Creación de la base de datos
CREATE DATABASE AdministracionConsorcios;

-- Selección de la base de datos
USE AdministracionConsorcios;

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
    expensas_total DECIMAL(10,2) NOT NULL,
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
    expensas DECIMAL(10,2) NOT NULL,
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
CREATE FUNCTION CalcularExpensasPropietario(
    total_expensas DECIMAL(10,2),
    porcentaje_fiscal DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN (total_expensas * porcentaje_fiscal / 100);
END //

-- Función para calcular el total gastado en reparaciones del consorcio
CREATE FUNCTION ObtenerTotalReparacionesConsorcio(consorcio_id INT) RETURNS DECIMAL(10,2)
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
CREATE FUNCTION ObtenerTotalExpensas(id_administrador INT) RETURNS DECIMAL(10,2)
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
CREATE VIEW Vista_Propietarios_Consorcios AS
SELECT 
    p.id_propietario,
    p.nombre AS nombre_propietario,
    p.apellido,
    p.telefono,
    p.email,
    p.expensas,
    c.razon_social AS consorcio,
    c.direccion AS direccion_consorcio
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista para ver las expensas totales de un consorcio asociado a sus administradores
CREATE VIEW Vista_Expensas_Consorcios AS
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
CREATE VIEW Vista_Expensas_Propietarios AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    p.departamento,
    p.unidad_funcional,
    p.expensas,
    c.id_consorcio,
    c.razon_social AS consorcio,
    c.expensas_total
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista que muestra las reparaciones realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW Vista_Reparaciones AS
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

-- Vista para ver el salario de los encargados de cada consorcio
CREATE VIEW Vista_Salarios_Encargados AS
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
CREATE VIEW Vista_TotalExpensasPorAdministrador AS
SELECT 
    a.id_administrador,
    a.nombre AS nombre_administrador,
    a.email AS email_administrador,
    ObtenerTotalExpensas(a.id_administrador) AS total_expensas
FROM 
    Administradores a;

-- Creación de Stored Procedures
DELIMITER //

-- SP para la inserción de un nuevo propietario.
CREATE PROCEDURE InsertarNuevoPropietario(
    IN nombre VARCHAR(50),
    IN apellido VARCHAR(50),
    IN direccion VARCHAR(75),
    IN telefono VARCHAR(12),
    IN email VARCHAR(50),
    IN id_consorcio INT,
    IN unidad_funcional INT,
    IN departamento VARCHAR(3),
    IN porcentaje_fiscal DECIMAL(5,2)
)
BEGIN
    DECLARE expensas DECIMAL(10,2);
    SELECT (expensas_total * porcentaje_fiscal / 100) INTO expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio;

    INSERT INTO Propietarios (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, expensas, porcentaje_fiscal)
    VALUES (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, expensas, porcentaje_fiscal);
END //

-- SP para actualizar el salario de un encargado específico.
CREATE PROCEDURE ActualizarSalarioEncargado(
    IN id_encargado INT,
    IN nuevo_salario DECIMAL(10,2)
)
BEGIN
    UPDATE Encargados
    SET salario = nuevo_salario
    WHERE id_encargado = id_encargado;
END //

-- Nuevo SP para actualizar el total de expensas de un consorcio
CREATE PROCEDURE ActualizarExpensasConsorcio(
    IN id_consorcio INT,
    IN nuevas_expensas_total DECIMAL(10,2)
)
BEGIN
    UPDATE Consorcios
    SET expensas_total = nuevas_expensas_total
    WHERE id_consorcio = id_consorcio;

    CALL RecalcularExpensasPropietarios(id_consorcio);
END //

-- SP para recalcular las expensas de cada propietario en un consorcio
CREATE PROCEDURE RecalcularExpensasPropietarios(
    IN id_consorcio INT
)
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    
    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio;

    -- Actualizar las expensas de cada propietario usando la función
    UPDATE Propietarios
    SET expensas = CalcularExpensasPropietario(total_expensas, porcentaje_fiscal)
    WHERE id_consorcio = id_consorcio;
END //

DELIMITER ;

-- TRIGGERS
DELIMITER //

-- Trigger para actualizar las expensas de cada propietario cuando se actualiza el valor total de las expensas de un consorcio
CREATE TRIGGER ActualizarExpensasPropietariosTrigger
AFTER UPDATE ON Consorcios
FOR EACH ROW
BEGIN
    IF NEW.expensas_total <> OLD.expensas_total THEN
        CALL RecalcularExpensasPropietarios(NEW.id_consorcio);
    END IF;
END //

-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
CREATE TRIGGER SumarCostoReparacionExpensas
AFTER INSERT ON Reparaciones
FOR EACH ROW
BEGIN
    -- Actualizar las expensas totales del consorcio
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
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (1, '66 Walton Crossing', '33-75759115-3', '66 Walton Crossing', 572, 10, 4, '2228183.7');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (2, '857 Muir Trail', '30-78335263-3', '857 Muir Trail', 483, 9, 2, '2105359');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (3, '35 Lake View Pass', '30-54927417-1', '35 Lake View Pass', 598, 2, 7, '9587543.9');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (4, '11330 Johnson Street', '30-32286770-1', '11330 Johnson Street', 539, 1, 7, '6265013');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (5, '2 Nobel Place', '23-13590496-2', '2 Nobel Place', 390, 2, 4, '7506970');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (6, '28 Anniversary Terrace', '20-65346667-0', '28 Anniversary Terrace', 648, 3, 3, '3667265.06');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (7, '59 Mifflin Hill', '20-26751285-1', '59 Mifflin Hill', 496, 8, 10, '9658523');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (8, '83 Haas Trail', '30-50642535-2', '83 Haas Trail', 380, 3, 6, '4824371');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (9, '73 Lindbergh Drive', '20-08965651-3', '73 Lindbergh Drive', 626, 2, 6, '9104857.0');
insert into Consorcios (id_consorcio, razon_social, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado, expensas_total) values (10, '678 Thackeray Terrace', '23-78074622-1', '678 Thackeray Terrace', 641, 3, 2, '6248796.8');
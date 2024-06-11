-- Creación de la base de datos
CREATE DATABASE AdministracionConsorcios;

-- Selección de la base de datos
USE AdministracionConsorcios;

-- Creación de la tabla Administradores
CREATE TABLE Administradores (
    id_administrador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    CUIT VARCHAR(11) NOT NULL,
    telefono VARCHAR(12) NOT NULL,
    email VARCHAR(50) NOT NULL
);

-- Creación de la tabla Encargados
CREATE TABLE Encargados (
    id_encargado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    CUIL VARCHAR(11) NOT NULL,
    salario DECIMAL(10,2) NOT NULL
);

-- Creación de la tabla Consorcios
CREATE TABLE Consorcios (
    id_consorcio INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(75) NOT NULL,
    CUIT VARCHAR(11) NOT NULL,
    direccion VARCHAR(75) NOT NULL,
    unidades_funcionales INT NOT NULL,
    id_administrador INT NOT NULL,
    id_encargado INT NOT NULL,
    expensas_total INT NOT NULL,
    FOREIGN KEY (id_administrador) REFERENCES Administradores(id_administrador),
    FOREIGN KEY (id_encargado) REFERENCES Encargados(id_encargado)
);

-- Creación de la tabla Propietarios
CREATE TABLE Propietarios (
    id_propietario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    direccion VARCHAR(75) NOT NULL,
    telefono VARCHAR(12) NOT NULL,
    email VARCHAR(50) NOT NULL,
	departamento VARCHAR(3),
    id_consorcio INT NOT NULL,
    unidad_funcional INT NOT NULL,
    expensas INT NOT NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de la tabla Proveedores
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(75) NOT NULL,
    telefono VARCHAR(12) NOT NULL,
    email VARCHAR(50) NOT NULL,
    descripcion_servicio VARCHAR(100) NOT NULL
);

-- Creación de la tabla Reparaciones
CREATE TABLE Reparaciones (
    id_reparacion INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    costo_total INT NOT NULL,
    fecha DATE NOT NULL,
    reparacion_comun BOOL NOT NULL,
    departamento VARCHAR(3),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

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

DELIMITER //
-- Creación de Funciones
-- Función para calcular el total gastado en reparaciones del consorcio (scripts de creación de las funciones)

CREATE FUNCTION ObtenerTotalReparacionesConsorcio(consorcio_id INT) RETURNS INT
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total
    FROM Reparaciones
    WHERE id_consorcio = consorcio_id;
    RETURN total;
END //


-- Creación de Stored Procedures
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
    IN expensas INT
)
BEGIN
    INSERT INTO Propietarios (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, expensas)
    VALUES (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, 0);
END //

-- SP para actualizar las expensas a pagar de un propietario.
CREATE PROCEDURE ActualizarExpensasPropietario(
    IN id_propietario INT,
    IN nuevas_expensas INT
)
BEGIN
    UPDATE Propietarios
    SET expensas = nuevas_expensas
    WHERE id_propietario = id_propietario;
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
END;

-- TRIGGERS.
-- Trigger para actualizar el total de expensas del consorcio cuando se actualiza el valor de las expensas de un propietario
CREATE TRIGGER ActualizarTotalExpensasConsorcio
AFTER UPDATE ON Propietarios
FOR EACH ROW
BEGIN
    IF NEW.expensas <> OLD.expensas THEN
        DECLARE total INT;
        
        -- Recalcular el total de expensas para el consorcio al que pertenece el propietario
        SELECT SUM(expensas) INTO total
        FROM Propietarios
        WHERE id_consorcio = NEW.id_consorcio;
        
        -- Actualizar el total de expensas en la tabla Consorcios
        UPDATE Consorcios
        SET expensas_total = total
        WHERE id_consorcio = NEW.id_consorcio;
    END IF;
END //


DELIMITER ;

-- Inserción de datos
-- ... (scripts de inserción de datos)



-- Inserción de datos
-- ... (scripts de inserción de datos)

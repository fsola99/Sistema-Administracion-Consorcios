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
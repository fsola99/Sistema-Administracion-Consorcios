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

-- Creación de la tabla Seguros
CREATE TABLE Seguros (
    id_seguro INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_encargado INT DEFAULT NULL,
    costo_mensual DECIMAL(10,2) NOT NULL,
    tipo_seguro ENUM('integral', 'vida', 'art') NOT NULL,
    vigencia BOOL NOT NULL,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
    FOREIGN KEY (id_encargado) REFERENCES Encargados(id_encargado) ON DELETE SET NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
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
    reparacion_comun BOOL NOT NULL,
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
    FOREIGN KEY (id_propietario) REFERENCES Propietarios(id_propietario),
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio),
	FOREIGN KEY (id_administrador) REFERENCES Administradores(id_administrador)
);

-- Tabla intermedia
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
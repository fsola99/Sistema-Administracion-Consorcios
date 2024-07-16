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

-- Creación tabla de Pagos por Período (asociados a un consorcio en un mes y año)
CREATE TABLE h_Pagos_Periodo (
	id_pagos_periodo INT AUTO_INCREMENT PRIMARY KEY,
    id_consorcio INT NOT NULL,
	mes ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre') NOT NULL,
    anio YEAR NOT NULL,
    monto_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

-- Creación de la tabla de hechos de Gastos
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
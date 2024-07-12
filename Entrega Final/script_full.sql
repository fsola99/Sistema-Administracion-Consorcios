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
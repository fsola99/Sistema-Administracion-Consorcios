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

-- Funcion para obtener el más reciente período (en formato: mes-anio) de pago por período cargado respecto a un ID consorcio pasado como parametro.
CREATE FUNCTION funcion_obtener_periodo_reciente(id_consorcio INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo VARCHAR(20);

    SELECT CONCAT(mes, '-', anio)
    INTO periodo
    FROM h_Pagos_Periodo
    WHERE id_consorcio = id_consorcio
    ORDER BY anio DESC, 
             FIELD(mes, 'Diciembre', 'Noviembre', 'Octubre', 'Septiembre', 'Agosto', 'Julio', 'Junio', 'Mayo', 'Abril', 'Marzo', 'Febrero', 'Enero') DESC
    LIMIT 1;

    RETURN periodo;
END //

-- Función para calcular el total de gastos desde una fecha específica de un consorcio (REVISAR POSIBLE USO DE h_Pagos_Periodo)
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

-- Función para obtener el período de un pago por período en varchar(20) con formato Mes-XXXX (con XXXX siendo el anio)
CREATE FUNCTION funcion_obtener_periodo(id_pagos_periodo INT) 
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo VARCHAR(20);
    
    SELECT CONCAT(mes, '-', anio)
    INTO periodo
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pagos_periodo;

    RETURN periodo;
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

    -- Obtener el mes y el año de la fecha proporcionada
    SET mes_actual = MONTHNAME(fecha);
    SET anio_actual = YEAR(fecha);

    -- Ajustar el mes y el año según la lógica de los períodos
    IF DAY(fecha) >= 26 THEN
        SET mes = MONTH(fecha) + 1;
        SET anio = anio_actual;
        
        IF mes = 13 THEN
            SET mes = 1;
            SET anio = anio_actual + 1;
        END IF;
    ELSE
        SET mes = MONTH(fecha);
        SET anio = anio_actual;
    END IF;

    -- Formatear el mes al nombre en español
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

    -- Formatear el resultado en el formato "Mes-año"
    SET periodo = CONCAT(mes_actual, '-', anio);

    RETURN periodo;
END //

-- Función para obtener la fecha de vencimiento en base a un ID de h_pagos_periodo
CREATE FUNCTION funcion_obtener_fecha_vencimiento_por_id(id_pagos_periodo_nuevo INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_vencimiento_nuevo DATE;
    DECLARE mes_nuevo ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');
    DECLARE anio_nuevo YEAR;

    -- Obtener el mes y el año del período de pagos
    SELECT
        mes,
        anio
    INTO
        mes_nuevo,
        anio_nuevo
    FROM
        h_Pagos_Periodo
    WHERE
        id_pagos_periodo = id_pagos_periodo_nuevo;

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

-- Función para obtener la última expensa de un propietario
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

-- Vista para obtener las expensas de todos los propietarios de un consorcio en un período dado
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
    pp.mes,
    pp.anio,
    pp.monto_total
FROM 
    Consorcios c
JOIN 
    h_Pagos_Periodo pp ON c.id_consorcio = pp.id_consorcio
WHERE 
    CONCAT(pp.mes, '-', pp.anio) = funcion_obtener_periodo_reciente(c.id_consorcio);

-- Vista que muestra los últimos 100 gastos (h_Gastos) para cada consorcio, ordenados por sus períodos
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

DELIMITER //

-- Stored Procedure que crea expensas con sus valores correspondientes, para los propietarios del consorcio en base a un id_pago_periodo.
CREATE PROCEDURE sp_crear_expensas_para_propietarios(IN id_pago_periodo INT)
BEGIN
    DECLARE id_consorcio_val INT;
    DECLARE nuevo_monto_total DECIMAL(10,2);
    DECLARE expensa_monto DECIMAL(10,2);
    DECLARE periodo_mes VARCHAR(20);
    DECLARE periodo_anio INT;

    -- Obtener el id_consorcio, monto_total y periodo del h_Pagos_Periodo
    SELECT id_consorcio, monto_total, mes, anio
    INTO id_consorcio_val, nuevo_monto_total, periodo_mes, periodo_anio
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pago_periodo;

    -- Calcular las expensas para todos los propietarios del consorcio
    INSERT INTO h_Expensas (id_propietario, id_pagos_periodo, fecha_vencimiento, pagado, monto)
    SELECT 
        p.id_propietario,
        id_pago_periodo,
        funcion_obtener_fecha_vencimiento(periodo_mes, periodo_anio),
        FALSE,
        funcion_calcular_expensas_propietario(nuevo_monto_total, p.porcentaje_fiscal)
    FROM 
        Propietarios p
    WHERE 
        p.id_consorcio = id_consorcio_val;
END //

-- Stored Procedure que actualiza las expensas para todos los propietarios del consorcio en base a un id_pago_periodo.
CREATE PROCEDURE sp_actualizar_expensas_propietarios(IN id_pago_periodo INT)
BEGIN
    DECLARE id_consorcio_val INT;
    DECLARE nuevo_monto_total DECIMAL(10,2);
    DECLARE expensa_monto DECIMAL(10,2);

    -- Obtener el id_consorcio y monto_total del h_Pagos_Periodo
    SELECT id_consorcio, monto_total
    INTO id_consorcio_val, nuevo_monto_total
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pago_periodo;

    -- Actualizar las expensas para todos los propietarios del consorcio
    UPDATE h_Expensas e
    JOIN Propietarios p ON e.id_propietario = p.id_propietario
    SET e.monto = funcion_calcular_expensas_propietario(nuevo_monto_total, p.porcentaje_fiscal)
    WHERE e.id_pagos_periodo = id_pago_periodo;
END //

DELIMITER ;

-- Creación de Triggers
DELIMITER //

-- Trigger que antes de insertar un gasto comprueba si existe una entrada de h_pagos_periodo asociada. Si no existe (si id_pagos_periodo = 0 y si para el periodo obtenido
-- en base a la fecha no hay ya una entrada creada para ese consorcio) entonces la crea. Si ya hay una con ese periodo para ese consorcio, utiliza la que ya existe.
CREATE TRIGGER trigger_previo_insertar_gasto
BEFORE INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE periodo VARCHAR(20);
    DECLARE mes VARCHAR(20);
    DECLARE anio INT;
    DECLARE id_pago_periodo_existente INT;

    -- Verificar si id_pagos_periodo es 0
    IF NEW.id_pagos_periodo = 0 THEN
        -- Obtener el período utilizando la función
        SET periodo = funcion_obtener_periodo_por_fecha(NEW.fecha);

        -- Extraer mes y año del período
        SET mes = SUBSTRING_INDEX(periodo, '-', 1);
        SET anio = CAST(SUBSTRING_INDEX(periodo, '-', -1) AS UNSIGNED);

        -- Verificar si ya existe un registro en h_Pagos_Periodo para el consorcio y el período
        SELECT id_pagos_periodo INTO id_pago_periodo_existente
        FROM h_Pagos_Periodo
        WHERE id_consorcio = NEW.id_consorcio
          AND mes = mes
          AND anio = anio;

        -- Si no existe, crear uno nuevo
        IF id_pago_periodo_existente IS NULL THEN
            INSERT INTO h_Pagos_Periodo (id_consorcio, mes, anio, monto_total)
            VALUES (NEW.id_consorcio, mes, anio, 0);

            -- Obtener el ID del nuevo registro de h_Pagos_Periodo
            SET NEW.id_pagos_periodo = LAST_INSERT_ID();
        ELSE
            -- Usar el ID existente
            SET NEW.id_pagos_periodo = id_pago_periodo_existente;
        END IF;
    END IF;
END //

-- Trigger que despues de ingresar un gasto actualiza el monto total existente de la entrada de h_pagos_periodo asociada. 
-- Si el monto_total de esa entrada de h_pagos_periodo era 0, llama al sp_crear_expensas_para_propietarios.
-- Si el monto_total de esa entrada de h_pagos_periodo era diferente de 0, llama al sp_actualizar_expensas_propietarios.
CREATE TRIGGER trigger_post_insertar_gasto
AFTER INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE monto_total_existente DECIMAL(10,2);
    
    -- Verificar el monto_total del h_Pagos_Periodo
    SELECT monto_total INTO monto_total_existente
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = NEW.id_pagos_periodo;

    IF monto_total_existente = 0 THEN
        -- Actualizar el monto_total del h_Pagos_Periodo
        UPDATE h_Pagos_Periodo
        SET monto_total = NEW.costo_total
        WHERE id_pagos_periodo = NEW.id_pagos_periodo;

        -- Llamar al procedimiento para crear las expensas
        CALL sp_crear_expensas_para_propietarios(NEW.id_pagos_periodo);
    ELSE
        -- Actualizar el monto_total del h_Pagos_Periodo sumando el nuevo gasto
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total + NEW.costo_total
        WHERE id_pagos_periodo = NEW.id_pagos_periodo;
        
        -- Llamar al procedimiento para actualizar las expensas
        CALL sp_actualizar_expensas_propietarios(NEW.id_pagos_periodo);
    END IF;
END //

-- Trigger para que ante el cambio de un gasto, se actualice el monto_total en h_pagos_periodo y llame al sp_actualizar_expensas_propietarios.
CREATE TRIGGER trigger_post_actualizar_gasto
AFTER UPDATE ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE diferencia DECIMAL(10,2);
    DECLARE monto_total_actual DECIMAL(10,2);
    
    -- Calcular la diferencia entre el nuevo costo total y el costo total anterior
    SET diferencia = NEW.costo_total - OLD.costo_total;

    -- Actualizar el monto_total en h_Pagos_Periodo sumando la diferencia
    UPDATE h_Pagos_Periodo
    SET monto_total = monto_total + diferencia
    WHERE id_pagos_periodo = NEW.id_pagos_periodo;
    
    -- Obtener el nuevo monto_total
    SELECT monto_total INTO monto_total_actual
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = NEW.id_pagos_periodo;

    -- Llamar al procedimiento para actualizar las expensas
    CALL sp_actualizar_expensas_propietarios(NEW.id_pagos_periodo);
END //

DELIMITER ;
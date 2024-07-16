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

-- Función para obtener la fecha de vencimiento en base a un período (mes y anio por separados).
CREATE FUNCTION funcion_obtener_fecha_vencimiento(mes ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'), anio YEAR) 
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_vencimiento DATE;
    
    -- Si el mes es Diciembre, la fecha de vencimiento será el 10 de Enero del siguiente año
    CASE mes
        WHEN 'Enero' THEN SET fecha_vencimiento = CONCAT(anio, '-02-10');
        WHEN 'Febrero' THEN SET fecha_vencimiento = CONCAT(anio, '-03-10');
        WHEN 'Marzo' THEN SET fecha_vencimiento = CONCAT(anio, '-04-10');
        WHEN 'Abril' THEN SET fecha_vencimiento = CONCAT(anio, '-05-10');
        WHEN 'Mayo' THEN SET fecha_vencimiento = CONCAT(anio, '-06-10');
        WHEN 'Junio' THEN SET fecha_vencimiento = CONCAT(anio, '-07-10');
        WHEN 'Julio' THEN SET fecha_vencimiento = CONCAT(anio, '-08-10');
        WHEN 'Agosto' THEN SET fecha_vencimiento = CONCAT(anio, '-09-10');
        WHEN 'Septiembre' THEN SET fecha_vencimiento = CONCAT(anio, '-10-10');
        WHEN 'Octubre' THEN SET fecha_vencimiento = CONCAT(anio, '-11-10');
        WHEN 'Noviembre' THEN SET fecha_vencimiento = CONCAT(anio, '-12-10');
        WHEN 'Diciembre' THEN SET fecha_vencimiento = CONCAT(anio + 1, '-01-10');
    END CASE;

    RETURN fecha_vencimiento;
END //

DELIMITER ;
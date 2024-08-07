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

-- Función para obtener el período de un pago por período en varchar(20) con formato Mes-XXXX (con XXXX siendo el anio)
CREATE FUNCTION funcion_obtener_periodo_reciente(id_consorcio_pasado INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo_buscado VARCHAR(20);

    SELECT periodo
    INTO periodo_buscado
    FROM h_Pagos_Periodo
    WHERE id_consorcio = id_consorcio_pasado
    ORDER BY STR_TO_DATE(periodo, '%M-%Y') DESC
    LIMIT 1;

    RETURN periodo_buscado;
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
CREATE FUNCTION funcion_obtener_periodo(id_pagos_periodo_nuevo INT) 
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE periodo_nuevo VARCHAR(20);
    
    SELECT periodo
    INTO periodo_nuevo
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;

    RETURN periodo_nuevo;
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
    SET mes = MONTH(fecha);
    SET anio = YEAR(fecha);
    
    SET anio_actual = anio;

    -- Ajustar el mes y el año según la lógica de los períodos
    IF DAY(fecha) >= 26 THEN
        SET mes = mes + 1;        
        IF mes = 13 THEN
            SET mes = 1;
            SET anio_actual = anio + 1;
        END IF;
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
    SET periodo = CONCAT(mes_actual, '-', anio_actual);

    RETURN periodo;
END //

-- Función para obtener la fecha de vencimiento en base a un ID de h_pagos_periodo
CREATE FUNCTION funcion_obtener_fecha_vencimiento_por_id(id_pagos_periodo_nuevo INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE fecha_vencimiento_nuevo DATE;
    DECLARE periodo_nuevo VARCHAR(20);
    
	DECLARE mes_nuevo ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');
    DECLARE anio_nuevo YEAR;
    
	SELECT periodo INTO periodo_nuevo
    FROM h_Pagos_periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;
    
	SET mes_nuevo = SUBSTRING_INDEX(periodo_nuevo, '-', 1);
    SET anio_nuevo = CAST(SUBSTRING_INDEX(periodo_nuevo, '-', -1) AS UNSIGNED);

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
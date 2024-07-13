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
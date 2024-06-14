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

-- Función para calcular el total gastado en reparaciones del consorcio
CREATE FUNCTION funcion_obtener_total_reparaciones_consorcio(consorcio_id INT) RETURNS DECIMAL(10,2)
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
CREATE FUNCTION funcion_obtener_total_expensas_administrador(id_administrador INT) RETURNS DECIMAL(10,2)
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
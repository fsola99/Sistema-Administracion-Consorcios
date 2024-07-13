-- Creación de Funciones
DELIMITER //

-- Función para calcular las expensas de un propietario.
CREATE FUNCTION funcion_calcular_expensas_propietario(
    monto_total DECIMAL(10,2),
    porcentaje_fiscal DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN (monto_total * porcentaje_fiscal / 100);
END //

-- Funcion para obtener el porcentaje fiscal del propietario cuyo ID es pasado como parametro.
CREATE FUNCTION obtener_porcentaje_fiscal(id INT)
RETURNS DECIMAL(5,2)
BEGIN
    DECLARE porcentaje DECIMAL(5,2);

    SELECT porcentaje_fiscal
    INTO porcentaje
    FROM Propietarios
    WHERE id_propietario = id;

    RETURN porcentaje;
END //

-- Funcion para obtener el más reciente período (en formato: mes-anio) de pago por período cargado respecto a un ID consorcio pasado como parametro.
CREATE FUNCTION obtener_periodo_reciente(id_consorcio INT)
RETURNS VARCHAR(20)
BEGIN
    DECLARE periodo VARCHAR(20);

    SELECT CONCAT(mes, '-', anio)
    INTO periodo
    FROM h_Pagos_Período
    WHERE id_consorcio = id_consorcio
    ORDER BY anio DESC, 
             FIELD(mes, 'Diciembre', 'Noviembre', 'Octubre', 'Septiembre', 'Agosto', 'Julio', 'Junio', 'Mayo', 'Abril', 'Marzo', 'Febrero', 'Enero') DESC
    LIMIT 1;

    RETURN periodo;
END//

-- Función para calcular el total de gastos desde una fecha específica de un consorcio (REVISAR POSIBLE USO DE h_Pagos_Período)
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


DELIMITER ;
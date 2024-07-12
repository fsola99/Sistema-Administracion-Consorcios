DELIMITER //

-- Trigger que ante el agregado de una entrada en la tabla de Expensas_por_Consorcio, agrega las expensas correspondientes para cada propietario del Consorcio.
CREATE TRIGGER trigger_after_insert_expensas_por_consorcio
AFTER INSERT ON Expensas_por_Consorcio
FOR EACH ROW
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    DECLARE fecha DATE;

    -- Obtener el monto de la expensa desde h_Expensas
    SELECT monto_expensas INTO total_expensas
    FROM h_Expensas
    WHERE id_expensa = NEW.id_expensa;
    
	-- Obtener la fecha de vencimiento de la expensa desde h_Expensas
    SELECT fecha_vencimiento INTO fecha
    FROM h_Expensas
    WHERE id_expensa = NEW.id_expensa;

    -- Llamar al procedimiento para crear expensas de propietarios
    CALL sp_crear_expensas_propietarios(NEW.id_expensa, NEW.id_consorcio, total_expensas, fecha);
END //

-- Trigger que ante la modificación de una entrada en la tabla h_Expensas, actualiza las expensas correspondientes de los propietarios del Consorcio.
CREATE TRIGGER trigger_after_update_expensas
AFTER UPDATE ON h_Expensas
FOR EACH ROW
BEGIN
    DECLARE consorcio_id INT;

    -- Verificar si la expensa modificada está asociada a algún consorcio
    SELECT id_consorcio INTO consorcio_id
    FROM Expensas_por_Consorcio
    WHERE id_expensa = NEW.id_expensa;
    
    -- Si se encuentra el consorcio asociado, llamar al SP para actualizar las expensas de los propietarios
    IF consorcio_id IS NOT NULL THEN
        CALL sp_actualizar_expensas_propietarios(NEW.id_expensa, consorcio_id, NEW.monto_expensas, NEW.fecha_vencimiento);
    END IF;
END //

-- >
-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
--
-- TRIGGERS
DELIMITER //

-- Trigger para actualizar las expensas de cada propietario cuando se actualiza el valor total de las expensas de un consorcio
CREATE TRIGGER trigger_actualizar_expensas_propietarios
AFTER UPDATE ON Consorcios
FOR EACH ROW
BEGIN
    IF NEW.expensas_total <> OLD.expensas_total THEN
        CALL sp_actualizar_expensas_propietarios(NEW.id_consorcio);
    END IF;
END //

-- Trigger para calcular automaticamente el valor de las expensas del propietario antes de ser insertado en la base (sirve para creacion base de propietario)
CREATE TRIGGER trigger_calcular_expensas_propietario
BEFORE INSERT ON Propietarios
FOR EACH ROW
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    DECLARE cuota_parte_propietario DECIMAL(5,2);

    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = NEW.id_consorcio;

    -- Calcular la cuota parte del propietario
    -- SET cuota_parte_propietario = NEW.porcentaje_fiscal / 100;

    -- Calcular las expensas del propietario
    -- SET NEW.expensas = total_expensas * cuota_parte_propietario;
    SET NEW.expensas = funcion_calcular_expensas_propietario(total_expensas, NEW.porcentaje_fiscal);
END //

-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
CREATE TRIGGER trigger_sumar_costo_reparacion_expensas_consorcio
AFTER INSERT ON Reparaciones
FOR EACH ROW
BEGIN
    UPDATE Consorcios
    SET expensas_total = expensas_total + NEW.costo_total
    WHERE id_consorcio = NEW.id_consorcio;
END //

DELIMITER ;
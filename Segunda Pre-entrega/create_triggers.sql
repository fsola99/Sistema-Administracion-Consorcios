-- TRIGGERS
DELIMITER //

-- Trigger para actualizar las expensas de cada propietario cuando se actualiza el valor total de las expensas de un consorcio
CREATE TRIGGER ActualizarExpensasPropietariosTrigger
AFTER UPDATE ON Consorcios
FOR EACH ROW
BEGIN
    IF NEW.expensas_total <> OLD.expensas_total THEN
        CALL RecalcularExpensasPropietarios(NEW.id_consorcio);
    END IF;
END //

-- Trigger para actualizar las expensas totales de un consorcio al momento de agregarse una reparacion asociada al mismo
CREATE TRIGGER SumarCostoReparacionExpensas
AFTER INSERT ON Reparaciones
FOR EACH ROW
BEGIN
    -- Actualizar las expensas totales del consorcio
    UPDATE Consorcios
    SET expensas_total = expensas_total + NEW.costo_total
    WHERE id_consorcio = NEW.id_consorcio;
END //

DELIMITER ;
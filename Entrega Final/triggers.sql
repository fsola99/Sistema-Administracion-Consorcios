-- Triggers para asegurar que los seguros integrales no tengan un id_encargado asociado en la tabla Seguros. Lo contrario en caso de que sean Seguros de Vida o de ART.
DELIMITER //
CREATE TRIGGER validar_seguros_ins BEFORE INSERT ON Seguros
FOR EACH ROW
BEGIN
    IF NEW.tipo_seguro = 'integral' AND NEW.id_encargado IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los seguros integrales no deben tener id_encargado.';
    END IF;
    IF (NEW.tipo_seguro = 'vida' OR NEW.tipo_seguro = 'art') AND NEW.id_encargado IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los seguros de vida o ART deben tener id_encargado.';
    END IF;
END;
//

CREATE TRIGGER validar_seguros_upd BEFORE UPDATE ON Seguros
FOR EACH ROW
BEGIN
    IF NEW.tipo_seguro = 'integral' AND NEW.id_encargado IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los seguros integrales no deben tener id_encargado.';
    END IF;
    IF (NEW.tipo_seguro = 'vida' OR NEW.tipo_seguro = 'art') AND NEW.id_encargado IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los seguros de vida o ART deben tener id_encargado.';
    END IF;
END;
//
DELIMITER ;
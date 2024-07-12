-- La siguiente tabla queda suspendida hasta próximos releases, ya que la implementación inicial no es correcta, 
-- y aplicarla bien correría el foco principal, que son los propietarios, consorcios y las expensas que deben pagar.
-- Creación de la tabla Seguros.
 CREATE TABLE Seguros (
    id_seguro INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_encargado INT DEFAULT NULL,
   costo_mensual DECIMAL(10,2) NOT NULL,
    tipo_seguro ENUM('integral', 'vida', 'art') NOT NULL,
    vigencia BOOL NOT NULL,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
    FOREIGN KEY (id_encargado) REFERENCES Encargados(id_encargado) ON DELETE SET NULL,
    FOREIGN KEY (id_consorcio) REFERENCES Consorcios(id_consorcio)
);

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
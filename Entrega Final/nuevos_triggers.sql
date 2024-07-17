DELIMITER //

CREATE TRIGGER after_insert_h_gastos
AFTER INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE id_pagos_periodo_actual INT;
    
    -- Llamar al stored procedure para asignar el gasto a un pago por período
    CALL procedimiento_asignar_gasto_a_pagos_periodo(NEW.id_gasto);
    
	-- Obtener el id_pagos_periodo actualizado    
    SELECT id_pagos_periodo INTO id_pagos_periodo_actual FROM h_Gastos WHERE id_gasto = NEW.id_gasto;

    -- Actualizar el monto total en la tabla h_Pagos_Periodo
    UPDATE h_Pagos_Periodo
    SET monto_total = monto_total + NEW.costo_total
    WHERE id_pagos_periodo = id_pagos_periodo_actual;

    -- Llamar al procedimiento para actualizar las expensas de los propietarios
    CALL procedimiento_actualizar_expensas_propietarios(NEW.id_consorcio, id_pagos_periodo_actual);
END //

CREATE TRIGGER after_update_h_gastos
AFTER UPDATE ON h_Gastos
FOR EACH ROW
BEGIN
    -- Verificar si el costo_total ha cambiado
    IF OLD.costo_total != NEW.costo_total THEN
        -- Actualizar el monto total en la tabla h_Pagos_Periodo
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total - OLD.costo_total + NEW.costo_total
        WHERE id_pagos_periodo = OLD.id_pagos_periodo;

        -- Llamar al procedimiento para actualizar las expensas de los propietarios
        CALL procedimiento_actualizar_expensas_propietarios(OLD.id_consorcio, OLD.id_pagos_periodo);
    END IF;
END //

DELIMITER ;


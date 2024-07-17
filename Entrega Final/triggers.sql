-- Creacion de Triggers.
DELIMITER  //

-- Actualización del trigger before_insert_h_gastos
CREATE TRIGGER before_insert_h_gastos
BEFORE INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE id_pago_periodo_existente INT;
    DECLARE mes_nuevo VARCHAR(20);
    DECLARE anio_nuevo YEAR;
    DECLARE nuevo_periodo VARCHAR(20);

    -- Obtener el período basado en la fecha del nuevo gasto
    SET nuevo_periodo = funcion_obtener_periodo_por_fecha(NEW.fecha);
    SET mes_nuevo = SUBSTRING_INDEX(nuevo_periodo, '-', 1);
    SET anio_nuevo = SUBSTRING_INDEX(nuevo_periodo, '-', -1);

    -- Verificar si ya existe un registro en h_Pagos_Periodo para el consorcio y el período
    SELECT id_pagos_periodo INTO id_pago_periodo_existente
    FROM h_Pagos_Periodo
    WHERE id_consorcio = NEW.id_consorcio
      AND mes = mes_nuevo
      AND anio = anio_nuevo;

    -- Si existe un registro, actualizar id_pagos_periodo del nuevo gasto y el monto total del período
    IF id_pago_periodo_existente IS NOT NULL THEN
        SET NEW.id_pagos_periodo = id_pago_periodo_existente;
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total + NEW.costo_total
        WHERE id_pagos_periodo = id_pago_periodo_existente;
    ELSE
        -- Si no existe un registro, crear una nueva entrada en h_Pagos_Periodo
        INSERT INTO h_Pagos_Periodo (id_consorcio, mes, anio, monto_total)
        VALUES (NEW.id_consorcio, mes_nuevo, anio_nuevo, NEW.costo_total);
        
        -- Obtener el id_pagos_periodo recién creado
        SET NEW.id_pagos_periodo = LAST_INSERT_ID();
    END IF;

    -- Llamar al stored procedure para actualizar o crear las expensas de los propietarios
    CALL sp_crear_actualizar_expensas_propietarios(NEW.id_consorcio, NEW.id_pagos_periodo);
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
        CALL sp_crear_actualizar_expensas_propietarios(OLD.id_consorcio, OLD.id_pagos_periodo);
    END IF;
END //

DELIMITER  ;
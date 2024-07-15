-- Creación de Triggers
DELIMITER //

CREATE TRIGGER before_insert_h_gastos
BEFORE INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE periodo VARCHAR(20);
    DECLARE mes VARCHAR(20);
    DECLARE anio INT;
    DECLARE id_pago_periodo_existente INT;

    -- Verificar si id_pagos_periodo es 0
    IF NEW.id_pagos_periodo = 0 THEN
        -- Obtener el período utilizando la función
        SET periodo = funcion_obtener_periodo_por_fecha(NEW.fecha);

        -- Extraer mes y año del período
        SET mes = SUBSTRING_INDEX(periodo, '-', 1);
        SET anio = CAST(SUBSTRING_INDEX(periodo, '-', -1) AS UNSIGNED);

        -- Verificar si ya existe un registro en h_Pagos_Periodo para el consorcio y el período
        SELECT id_pagos_periodo INTO id_pago_periodo_existente
        FROM h_Pagos_Periodo
        WHERE id_consorcio = NEW.id_consorcio
          AND mes = mes
          AND anio = anio;

        -- Si no existe, crear uno nuevo
        IF id_pago_periodo_existente IS NULL THEN
            INSERT INTO h_Pagos_Periodo (id_consorcio, mes, anio, monto_total)
            VALUES (NEW.id_consorcio, mes, anio, 0);

            -- Obtener el ID del nuevo registro de h_Pagos_Periodo
            SET NEW.id_pagos_periodo = LAST_INSERT_ID();
        ELSE
            -- Usar el ID existente
            SET NEW.id_pagos_periodo = id_pago_periodo_existente;
        END IF;
    END IF;
END //

CREATE TRIGGER after_insert_h_gastos
AFTER INSERT ON h_Gastos
FOR EACH ROW
BEGIN
    DECLARE monto_total_existente DECIMAL(10,2);
    
    -- Verificar el monto_total del h_Pagos_Periodo
    SELECT monto_total INTO monto_total_existente
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = NEW.id_pagos_periodo;

    IF monto_total_existente = 0 THEN
        -- Actualizar el monto_total del h_Pagos_Periodo
        UPDATE h_Pagos_Periodo
        SET monto_total = NEW.costo_total
        WHERE id_pagos_periodo = NEW.id_pagos_periodo;

        -- Llamar al procedimiento para crear las expensas
        CALL crear_expensas_para_propietarios(NEW.id_pagos_periodo);
    ELSE
        -- Actualizar el monto_total del h_Pagos_Periodo sumando el nuevo gasto
        UPDATE h_Pagos_Periodo
        SET monto_total = monto_total + NEW.costo_total
        WHERE id_pagos_periodo = NEW.id_pagos_periodo;
        
        -- Llamar al procedimiento para actualizar las expensas
        CALL actualizar_expensas_para_propietarios(NEW.id_pagos_periodo);
    END IF;
END //

DELIMITER ;
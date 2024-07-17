-- Creacion de SPs.

DELIMITER  //

CREATE PROCEDURE sp_crear_actualizar_expensas_propietarios(
    IN id_consorcio_nuevo INT,
    IN id_pagos_periodo_nuevo INT
)
BEGIN
    DECLARE monto_total_nuevo DECIMAL(10,2);

    -- Obtener el monto total del periodo de pagos
    SELECT monto_total INTO monto_total_nuevo
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pagos_periodo_nuevo;

    -- Actualizar las expensas existentes para cada propietario
    UPDATE h_Expensas e
    JOIN propietarios p ON e.id_propietario = p.id_propietario
    SET e.monto = funcion_calcular_expensas_propietario(monto_total_nuevo, p.porcentaje_fiscal)
    WHERE e.id_pagos_periodo = id_pagos_periodo_nuevo AND p.id_consorcio = id_consorcio_nuevo;

    -- Insertar expensas para los propietarios que no tienen una entrada para el periodo
    INSERT INTO h_Expensas (id_propietario, id_pagos_periodo, fecha_vencimiento, pagado, monto)
    SELECT p.id_propietario, id_pagos_periodo_nuevo, funcion_obtener_fecha_vencimiento_por_id(id_pagos_periodo_nuevo), FALSE, funcion_calcular_expensas_propietario(monto_total_nuevo, p.porcentaje_fiscal)
    FROM propietarios p
    WHERE p.id_consorcio = id_consorcio_nuevo
      AND NOT EXISTS (
          SELECT 1
          FROM h_Expensas e
          WHERE e.id_propietario = p.id_propietario AND e.id_pagos_periodo = id_pagos_periodo_nuevo
      );
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE procedimiento_asignar_gasto_a_pagos_periodo(IN id_gasto_nuevo INT)
BEGIN
    DECLARE id_consorcio_nuevo INT;
    DECLARE fecha_nuevo DATE;
    DECLARE periodo_nuevo VARCHAR(20);
    DECLARE id_pagos_periodo_nuevo INT;
    DECLARE mes_nuevo ENUM('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');
    DECLARE anio_nuevo YEAR;

    -- Obtener la fecha y el id_consorcio del gasto
    SELECT id_consorcio, fecha
    INTO id_consorcio_nuevo, fecha_nuevo
    FROM h_Gastos
    WHERE id_gasto = id_gasto_nuevo;

    -- Obtener el período en base a la fecha del gasto
    SET periodo_nuevo = funcion_obtener_periodo_por_fecha(fecha_nuevo);

    -- Dividir el período en mes y año
    SET mes_nuevo = LEFT(periodo_nuevo, LOCATE('-', periodo_nuevo) - 1);
    SET anio_nuevo = RIGHT(periodo_nuevo, 4);

    -- Obtener el id_pagos_periodo correspondiente al período del gasto
    SELECT id_pagos_periodo
    INTO id_pagos_periodo_nuevo
    FROM h_Pagos_Periodo
    WHERE id_consorcio = id_consorcio_nuevo
    AND mes = mes_nuevo
    AND anio = anio_nuevo;

    -- Si no existe un id_pagos_periodo para ese consorcio y período, crearlo
    IF id_pagos_periodo_nuevo IS NULL THEN
        INSERT INTO h_Pagos_Periodo (id_consorcio, mes, anio, monto_total)
        VALUES (id_consorcio_nuevo, mes_nuevo, anio_nuevo, 0);
        SET id_pagos_periodo_nuevo = LAST_INSERT_ID();
    END IF;

    -- Asignar el id_pagos_periodo al gasto
    UPDATE h_Gastos
    SET id_pagos_periodo = id_pagos_periodo_nuevo
    WHERE id_gasto = id_gasto_nuevo;
END //

CREATE PROCEDURE procedimiento_actualizar_expensas_propietarios(
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
    SET e.monto_expensa = funcion_calcular_expensas_propietario(monto_total_nuevo, p.procentaje_fical)
    WHERE e.id_pagos_periodo = id_pagos_periodo_nuevo AND p.id_consorcio = id_consorcio_nuevo;

    -- Insertar expensas para los propietarios que no tienen una entrada para el periodo
    INSERT INTO h_Expensas (id_propietario, id_pagos_periodo, fecha_vencimiento, pagado, monto)
    SELECT p.id_propietario, id_pagos_periodo_nuevo, funcion_obtener_fecha_vencimiento_segun_id(id_pagos_periodo_nuevo), FALSE, funcion_calcular_expensas_propietario(monto_total_nuevo, p.procentaje_fical)
    FROM propietarios p
    WHERE p.id_consorcio = id_consorcio_nuevo
      AND NOT EXISTS (
          SELECT 1
          FROM h_Expensas e
          WHERE e.id_propietario = p.id_propietario AND e.id_pagos_periodo = id_pagos_periodo_nuevo
      );
END //

DELIMITER ;

-- Creacion de SPs.

DELIMITER //

-- Stored Procedure que crea expensas con sus valores correspondientes, para los propietarios del consorcio en base a un id_pago_periodo.
CREATE PROCEDURE sp_crear_expensas_para_propietarios(IN id_pago_periodo INT)
BEGIN
    DECLARE id_consorcio_val INT;
    DECLARE nuevo_monto_total DECIMAL(10,2);
    DECLARE expensa_monto DECIMAL(10,2);
    DECLARE periodo_mes VARCHAR(20);
    DECLARE periodo_anio INT;

    -- Obtener el id_consorcio, monto_total y periodo del h_Pagos_Periodo
    SELECT id_consorcio, monto_total, mes, anio
    INTO id_consorcio_val, nuevo_monto_total, periodo_mes, periodo_anio
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pago_periodo;

    -- Calcular las expensas para todos los propietarios del consorcio
    INSERT INTO h_Expensas (id_propietario, id_pagos_periodo, fecha_vencimiento, pagado, monto)
    SELECT 
        p.id_propietario,
        id_pago_periodo,
        funcion_obtener_fecha_vencimiento(periodo_mes, periodo_anio),
        FALSE,
        funcion_calcular_expensas_propietario(nuevo_monto_total, p.porcentaje_fiscal)
    FROM 
        Propietarios p
    WHERE 
        p.id_consorcio = id_consorcio_val;
END //

-- Stored Procedure que actualiza las expensas para todos los propietarios del consorcio en base a un id_pago_periodo.
CREATE PROCEDURE sp_actualizar_expensas_propietarios(IN id_pago_periodo INT)
BEGIN
    DECLARE id_consorcio_val INT;
    DECLARE nuevo_monto_total DECIMAL(10,2);
    DECLARE expensa_monto DECIMAL(10,2);

    -- Obtener el id_consorcio y monto_total del h_Pagos_Periodo
    SELECT id_consorcio, monto_total
    INTO id_consorcio_val, nuevo_monto_total
    FROM h_Pagos_Periodo
    WHERE id_pagos_periodo = id_pago_periodo;

    -- Actualizar las expensas para todos los propietarios del consorcio
    UPDATE h_Expensas e
    JOIN Propietarios p ON e.id_propietario = p.id_propietario
    SET e.monto = funcion_calcular_expensas_propietario(nuevo_monto_total, p.porcentaje_fiscal)
    WHERE e.id_pagos_periodo = id_pago_periodo;
END //

DELIMITER ;
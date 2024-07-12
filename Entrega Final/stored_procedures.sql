-- Creación de Stored Procedures.
DELIMITER //

-- Stored Procedure principal para insercion de una expensa de un consorcio, insertando entrada en h_Expensas y Expensas_por_Consorcio.
CREATE PROCEDURE sp_insertar_expensa_consorcio(
    IN consorcio_id INT,
    IN monto_expensas DECIMAL(10,2),
    IN fecha_vencimiento DATE
)
BEGIN
    DECLARE nueva_expensa_id INT;

    -- Insertar nueva expensa para el consorcio
    INSERT INTO h_Expensas (monto_expensas, fecha_vencimiento, pagada)
    VALUES (monto_expensas, fecha_vencimiento, FALSE);

    -- Obtener el id de la nueva expensa insertada
    SET nueva_expensa_id = LAST_INSERT_ID();

    -- Insertar en Expensas_por_Consorcio
    INSERT INTO Expensas_por_Consorcio (id_expensa, id_consorcio)
    VALUES (nueva_expensa_id, consorcio_id);
    
END //

-- Stored Procedure para crear las expensas de un propietario, insertando entrada en h_Expensas y Expensas_por_Propietario.
CREATE PROCEDURE sp_insertar_expensa_propietario(
    IN propietario_id INT,
    IN fecha_vencimiento DATE,
    IN monto_expensas DECIMAL(10,2)
)
BEGIN
    DECLARE new_expensa_id INT;

    -- Insertar nueva expensa para el propietario
    INSERT INTO h_Expensas (monto_expensas, fecha_vencimiento, pagada)
    VALUES (monto_expensas, fecha_vencimiento, FALSE);

    -- Obtener el id de la nueva expensa insertada
    SET new_expensa_id = LAST_INSERT_ID();

    -- Insertar en Expensas_por_Propietario
    INSERT INTO Expensas_por_Propietario (id_expensa, id_propietario)
    VALUES (new_expensa_id, propietario_id);
END //

-- Stored Procedure para Crear Expensas para Todos los Propietarios de un Consorcio, invocando.
CREATE PROCEDURE sp_crear_expensas_propietarios(
    IN expensa_id INT,
    IN consorcio_id INT,
    IN total_expensas DECIMAL(10,2),
    IN fecha DATE
)
BEGIN
    DECLARE propietario_id INT;
    DECLARE porcentaje_fiscal DECIMAL(5,2);
    
    -- Iterar sobre los propietarios del consorcio y calcular expensas
    SET @propietario_id = 0;
    WHILE EXISTS (SELECT id_propietario FROM Propietarios WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id LIMIT 1) DO
        SELECT id_propietario, porcentaje_fiscal INTO @propietario_id, porcentaje_fiscal
        FROM Propietarios 
        WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id
        LIMIT 1;
        
        -- Calcular expensa para el propietario y llamar al SP intermedio
        CALL sp_insertar_expensa_propietario(
            @propietario_id,
            fecha,
            funcion_calcular_expensas_propietario(total_expensas, porcentaje_fiscal)
        );
    END WHILE;
END //

-- Stored Procedure para actualizar las expensas de todos los propietarios de un consorcio
CREATE PROCEDURE sp_actualizar_expensas_propietarios(
    IN expensa_id INT,
    IN consorcio_id INT,
    IN nuevo_total_expensas DECIMAL(10,2),
    IN nueva_fecha DATE
)
BEGIN
    DECLARE propietario_id INT;
    DECLARE porcentaje_fiscal DECIMAL(5,2);

    -- Iterar sobre los propietarios del consorcio y actualizar expensas
    SET @propietario_id = 0;
    WHILE EXISTS (SELECT id_propietario FROM Propietarios WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id LIMIT 1) DO
        SELECT id_propietario, porcentaje_fiscal INTO @propietario_id, porcentaje_fiscal
        FROM Propietarios 
        WHERE id_consorcio = consorcio_id AND id_propietario > @propietario_id
        LIMIT 1;

        -- Calcular nueva expensa para el propietario y actualizarla en h_Expensas y Expensas_por_Propietario
        UPDATE h_Expensas he
        JOIN Expensas_por_Propietario epp ON he.id_expensa = epp.id_expensa
        SET he.monto_expensas = funcion_calcular_expensas_propietario(nuevo_total_expensas, porcentaje_fiscal), 
            he.fecha_vencimiento = nueva_fecha
        WHERE epp.id_propietario = @propietario_id 
          AND he.id_expensa = expensa_id;
    END WHILE;
END //

-- SP para actualizar el salario de un encargado específico.
CREATE PROCEDURE sp_actualizar_salario_encargado(
    IN id_encargado INT,
    IN nuevo_salario DECIMAL(10,2)
)
BEGIN
    UPDATE Encargados
    SET salario = nuevo_salario
    WHERE id_encargado = id_encargado;
END //

DELIMITER ;
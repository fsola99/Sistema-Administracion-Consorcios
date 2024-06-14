-- Creación de Stored Procedures
DELIMITER //

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

-- SP para actualizar el total de expensas de un consorcio
CREATE PROCEDURE sp_actualizar_expensas_consorcio(
    IN id_consorcio_param INT,
    IN nuevas_expensas_total DECIMAL(10,2)
)
BEGIN
    -- Variable para almacenar el total de expensas
    DECLARE total_expensas DECIMAL(10,2);

    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio_param;
    -- LIMIT 1;

    -- Verificar si se encontró un resultado
    IF total_expensas IS NOT NULL THEN
        -- Actualizar el total de expensas del consorcio
        UPDATE Consorcios
        SET expensas_total = nuevas_expensas_total
        WHERE id_consorcio = id_consorcio_param;

        -- Llamar a la función para recalcular las expensas de los propietarios
        CALL sp_actualizar_expensas_propietarios(id_consorcio_param);
    ELSE
        -- Si no se encontró ningún consorcio con ese id, mostrar un mensaje o manejar el error según sea necesario
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se encontró ningún consorcio con el ID especificado.';
    END IF;
END //

-- SP para recalcular las expensas de cada propietario en un consorcio
CREATE PROCEDURE sp_actualizar_expensas_propietarios(
    IN id_consorcio_param INT
)
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    
    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio_param;
    -- LIMIT 1;

    -- Actualizar las expensas de cada propietario usando la función
    UPDATE Propietarios
    SET expensas = funcion_calcular_expensas_propietario(total_expensas, porcentaje_fiscal)
    WHERE id_consorcio = id_consorcio_param;
END //

DELIMITER ;
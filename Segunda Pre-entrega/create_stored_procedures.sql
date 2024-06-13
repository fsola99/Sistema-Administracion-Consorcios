-- Creación de Stored Procedures
DELIMITER //

-- SP para la inserción de un nuevo propietario.
CREATE PROCEDURE InsertarNuevoPropietario(
    IN nombre VARCHAR(50),
    IN apellido VARCHAR(50),
    IN direccion VARCHAR(75),
    IN telefono VARCHAR(12),
    IN email VARCHAR(50),
    IN id_consorcio INT,
    IN unidad_funcional INT,
    IN departamento VARCHAR(3),
    IN porcentaje_fiscal DECIMAL(5,2)
)
BEGIN
    DECLARE expensas DECIMAL(10,2);
    SELECT (expensas_total * porcentaje_fiscal / 100) INTO expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio;

    INSERT INTO Propietarios (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, expensas, porcentaje_fiscal)
    VALUES (nombre, apellido, direccion, telefono, email, id_consorcio, unidad_funcional, departamento, expensas, porcentaje_fiscal);
END //

-- SP para actualizar el salario de un encargado específico.
CREATE PROCEDURE ActualizarSalarioEncargado(
    IN id_encargado INT,
    IN nuevo_salario DECIMAL(10,2)
)
BEGIN
    UPDATE Encargados
    SET salario = nuevo_salario
    WHERE id_encargado = id_encargado;
END //

-- Nuevo SP para actualizar el total de expensas de un consorcio
CREATE PROCEDURE ActualizarExpensasConsorcio(
    IN id_consorcio INT,
    IN nuevas_expensas_total DECIMAL(10,2)
)
BEGIN
    UPDATE Consorcios
    SET expensas_total = nuevas_expensas_total
    WHERE id_consorcio = id_consorcio;

    CALL RecalcularExpensasPropietarios(id_consorcio);
END //

-- SP para recalcular las expensas de cada propietario en un consorcio
CREATE PROCEDURE RecalcularExpensasPropietarios(
    IN id_consorcio INT
)
BEGIN
    DECLARE total_expensas DECIMAL(10,2);
    
    -- Obtener el total de expensas del consorcio
    SELECT expensas_total INTO total_expensas
    FROM Consorcios
    WHERE id_consorcio = id_consorcio;

    -- Actualizar las expensas de cada propietario usando la función
    UPDATE Propietarios
    SET expensas = CalcularExpensasPropietario(total_expensas, porcentaje_fiscal)
    WHERE id_consorcio = id_consorcio;
END //

DELIMITER ;

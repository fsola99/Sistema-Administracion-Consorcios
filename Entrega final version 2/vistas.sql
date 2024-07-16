-- Creación de Vistas
-- Vista que brinda información general de los propietarios de un consorcio.
CREATE VIEW vista_general_propietarios_consorcios AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    c.direccion AS consorcio
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;
    
-- Vista que muestra el histórico de expensas de un propietario de un consorcio para cada período contabilizado.
CREATE VIEW vista_historico_expensas_propietario AS
SELECT 
    p.id_propietario,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
    c.id_consorcio,
    c.direccion AS consorcio,
    funcion_obtener_periodo(e.id_pagos_periodo) AS periodo,
    e.monto,
    e.fecha_vencimiento,
    e.pagado
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    p.id_propietario, c.id_consorcio, e.id_pagos_periodo;

-- Vista para obtener las expensas de todos los propietarios de un consorcio en un período dado
CREATE VIEW vista_expensas_consorcio_periodo AS
SELECT 
    c.direccion AS consorcio,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
    funcion_obtener_periodo(e.id_pagos_periodo) AS periodo,
    e.monto,
    e.pagado
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    c.id_consorcio, e.id_pagos_periodo;
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
    
-- Vista para ver el salario de los encargados de cada consorcio
CREATE VIEW vista_salarios_encargados_consorcio AS
SELECT
    c.id_consorcio,
    c.direccion,
    e.id_encargado,
    e.nombre AS nombre_encargado,
    e.apellido,
    e.salario
FROM
    Consorcios c
JOIN
    Encargados e ON c.id_encargado = e.id_encargado;
    
-- Vista que muestra el histórico de reclamos de un consorcio.
CREATE VIEW vista_historico_reclamos_consorcio AS
SELECT 
    hr.id_reclamo,
    hr.descripcion,
    hr.fecha,
    c.id_consorcio,
    c.direccion AS consorcio,
    a.id_administrador,
    a.nombre AS nombre_administrador
FROM 
    h_Reclamos hr
JOIN 
    Consorcios c ON hr.id_consorcio = c.id_consorcio
JOIN 
    Administradores a ON hr.id_administrador = a.id_administrador
ORDER BY 
    hr.fecha DESC;
    
-- Vista que muestre el historíco de reclamos de los consorcios de un administrador.
CREATE VIEW vista_historico_reclamos_administrador AS
SELECT 
    hr.id_reclamo,
    hr.descripcion,
    hr.fecha,
    c.direccion AS consorcio
FROM 
    h_Reclamos hr
JOIN 
    Consorcios c ON hr.id_consorcio = c.id_consorcio
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador
ORDER BY 
    hr.fecha DESC;

-- Vista para obtener la última expensa de cada propietario.
CREATE VIEW vista_ultima_expensa_propietarios AS
SELECT 
    e.id_propietario,
    CONCAT(p.nombre, ' ', p.apellido) AS propietario,
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
WHERE 
    e.id_expensa = funcion_obtener_ultima_expensa(e.id_propietario);

-- Vista que brinda información general de los propietarios morosos (aquellos que tienen expensas sin pagar).
CREATE VIEW vista_propietarios_morosos AS
SELECT 
    e.id_propietario,
    p.nombre,
    p.apellido,
    e.monto,
    e.fecha_vencimiento,
    c.id_consorcio,
    c.direccion AS consorcio,
    e.id_pagos_periodo
FROM 
    h_Expensas e
JOIN 
    Propietarios p ON e.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
WHERE 
    e.pagado = FALSE
ORDER BY 
    e.fecha_vencimiento DESC;

-- Vista que muestra el pago por período (h_Pagos_Periodo) más reciente asociado a cada consorcio.    
CREATE VIEW vista_pago_periodo_reciente AS
SELECT 
    c.id_consorcio,
    c.direccion AS consorcio,
    pp.id_pagos_periodo,
    pp.periodo,
    pp.monto_total
FROM 
    Consorcios c
JOIN 
    h_Pagos_Periodo pp ON c.id_consorcio = pp.id_consorcio
WHERE 
    pp.periodo = funcion_obtener_periodo_reciente(c.id_consorcio);

-- Vista que muestra los últimos 100 gastos (h_Gastos) para cada consorcio, ordenados por sus períodos
CREATE VIEW vista_ultimos_100_gastos_consorcio AS
SELECT 
    g.id_gasto,
    g.id_proveedor,
    g.id_consorcio,
    c.direccion AS consorcio,
    g.id_pagos_periodo,
    g.costo_total,
    g.fecha,
    g.concepto
FROM 
    h_Gastos g
JOIN 
    Consorcios c ON g.id_consorcio = c.id_consorcio
ORDER BY 
    g.id_consorcio, g.fecha DESC
LIMIT 100;
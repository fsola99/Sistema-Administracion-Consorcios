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

-- Vista que muestra el histórico de expensas de un propietario con detalles del consorcio
CREATE VIEW vista_historico_expensas_propietario_consorcio AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
	c.direccion AS direccion_consorcio,
    c.CUIT AS cuit_consorcio,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
JOIN 
    Expensas_por_Propietario epp ON p.id_propietario = epp.id_propietario
JOIN 
    h_Expensas he ON epp.id_expensa = he.id_expensa
ORDER BY 
    p.id_propietario, he.fecha_vencimiento;
    
-- Vista para obtener la última expensa de cada propietario utilizando
CREATE VIEW vista_ultima_expensa_por_propietario AS
SELECT 
    epp.id_propietario,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Expensas_por_Propietario epp
JOIN 
    h_Expensas he ON epp.id_expensa = he.id_expensa
WHERE 
    he.fecha_vencimiento = funcion_obtener_fecha_vencimiento_mas_reciente_propietario(epp.id_propietario);

-- Vista que brinda información general de los propietarios de un consorcio con las últimas expensas que deben pagar
CREATE VIEW vista_propietarios_consorcio_ultimas_expensas AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    p.departamento,
    c.direccion AS direccion_consorcio,
    c.CUIT AS cuit_consorcio,
    ue.monto_expensas,
    ue.fecha_vencimiento,
    ue.pagada
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
LEFT JOIN 
    vista_ultima_expensa_por_propietario ue ON p.id_propietario = ue.id_propietario
ORDER BY 
    p.id_propietario;

-- Vista para ver las ultimas expensas de cada consorcio
CREATE VIEW vista_ultima_expensa_por_consorcio AS
SELECT 
    epc.id_consorcio,
    he.monto_expensas,
    he.fecha_vencimiento,
    he.pagada
FROM 
    Expensas_por_Consorcio epc
JOIN 
    h_Expensas he ON epc.id_expensa = he.id_expensa
WHERE 
    he.fecha_vencimiento = funcion_obtener_fecha_vencimiento_mas_reciente_consorcio(epc.id_consorcio);

-- Vista para ver las ultimas expensas totales de un consorcio asociado a sus administradores
CREATE VIEW vista_consorcios_administradores_ultimas_expensas AS
SELECT 
    c.id_consorcio,
    c.direccion,
    c.CUIT AS cuit_consorcio,
    c.unidades_funcionales,
    a.nombre AS nombre_administrador,
    a.CUIT AS cuit_administrador,
    a.telefono AS telefono_administrador,
    a.email AS email_administrador,
    ue.monto_expensas,
    ue.fecha_vencimiento,
    ue.pagada
FROM 
    Consorcios c
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador
LEFT JOIN 
    vista_ultima_expensa_por_consorcio ue ON c.id_consorcio = ue.id_consorcio
ORDER BY 
    c.id_consorcio;

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

-- Vista que muestra el total de las expensas a pagar por administrador
CREATE VIEW vista_total_expensas_administrador AS
SELECT 
    a.id_administrador,
    a.nombre AS nombre_administrador,
    funcion_obtener_total_ultimas_expensas_administrador(a.id_administrador) AS total_expensas
FROM 
    Administradores a;
    
-- Vista que muestra el histórico de gastos con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.costo_total,
    hg.fecha,
    hg.comun
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
ORDER BY 
    hg.fecha DESC;
    
-- vista que muestre el histórico de gastos comunes (para todo el consorcio) con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos_comunes AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.costo_total,
    hg.fecha
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
WHERE 
    hg.comun = true
ORDER BY 
    hg.fecha DESC;

-- Vista que muestra el histórico de gastos específicos de un departamento con su proveedor y consorcio asociado.
CREATE VIEW vista_historico_gastos_especificos_departamento AS
SELECT 
    hg.id_gasto,
    pr.razon_social AS proveedor,
    c.direccion AS consorcio,
    c.CUIT AS cuit_consorcio,
    hg.departamento,
    hg.costo_total,
    hg.fecha
FROM 
    h_Gastos hg
JOIN 
    Proveedores pr ON hg.id_proveedor = pr.id_proveedor
JOIN 
    Consorcios c ON hg.id_consorcio = c.id_consorcio
WHERE 
    hg.comun = false
ORDER BY 
    hg.fecha DESC;
    
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
    
-- vista que muestre el historíco de reclamos de los consorcios de un administrador.
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

-- Vista que muestra el histórico de expensas de propietarios.
CREATE VIEW vista_historico_expensas_propietarios AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.departamento,
    e.monto_expensas,
    e.fecha_vencimiento,
    e.pagada,
    c.direccion AS consorcio
FROM 
    h_Expensas e
JOIN 
    Expensas_por_Propietario ep ON e.id_expensa = ep.id_expensa
JOIN 
    Propietarios p ON ep.id_propietario = p.id_propietario
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio
ORDER BY 
    p.id_propietario, e.fecha_vencimiento DESC;
    
-- Vista que muestra el histórico de expensas de consorcios.
CREATE VIEW vista_historico_expensas_consorcios AS
SELECT 
    c.id_consorcio,
    c.direccion AS consorcio,
    e.monto_expensas,
    e.fecha_vencimiento,
    e.pagada
FROM 
    h_Expensas e
JOIN 
    Expensas_por_Consorcio ec ON e.id_expensa = ec.id_expensa
JOIN 
    Consorcios c ON ec.id_consorcio = c.id_consorcio
ORDER BY 
    c.id_consorcio, e.fecha_vencimiento DESC;
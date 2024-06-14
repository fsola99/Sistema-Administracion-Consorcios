-- Creación de Vistas
-- Vista que brinda información general de los propietarios de un consorcio.
CREATE VIEW vista_general_propietarios_consorcios AS
SELECT 
    p.id_propietario,
    p.nombre AS nombre_propietario,
    p.apellido,
    p.telefono,
    p.email,
    p.expensas,
    c.razon_social AS consorcio
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista para ver las expensas totales de un consorcio asociado a sus administradores
CREATE VIEW vista_expensas_consorcios_adminstrador AS
SELECT 
    c.id_consorcio,
    c.razon_social,
    c.unidades_funcionales,
    c.expensas_total,
    a.id_administrador,
    a.nombre AS nombre_administrador,
    a.email AS email_administrador
FROM 
    Consorcios c
JOIN 
    Administradores a ON c.id_administrador = a.id_administrador;
    
-- Vista que muestra las expensas de cada propietario con detalles del consorcio
CREATE VIEW vista_expensas_propietarios_consorcio AS
SELECT 
    p.id_propietario,
    p.nombre,
    p.apellido,
    p.telefono,
    p.email,
    p.departamento,
    p.unidad_funcional,
	p.porcentaje_fiscal,
    p.expensas,
    c.id_consorcio,
    c.razon_social AS nombre_consorcio,
    c.expensas_total
FROM 
    Propietarios p
JOIN 
    Consorcios c ON p.id_consorcio = c.id_consorcio;

-- Vista que muestra las reparaciones realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones AS
SELECT 
    r.id_reparacion,
    r.fecha,
    r.reparacion_comun,
    r.departamento,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio;
    
-- Vista que muestra las reparaciones comunes realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones_comunes AS
SELECT 
    r.id_reparacion,
    r.fecha,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio
WHERE
    r.reparacion_comun = true;
    
-- Vista que muestra las reparaciones no comunes realizadas, incluyendo información del proveedor y del consorcio en las que se hicieron.
CREATE VIEW vista_reparaciones_particulares AS
SELECT 
    r.id_reparacion,
    r.fecha,
    r.departamento,
    p.razon_social AS proveedor,
    c.razon_social AS consorcio
FROM 
    Reparaciones r
JOIN 
    Proveedores p ON r.id_proveedor = p.id_proveedor
JOIN 
    Consorcios c ON r.id_consorcio = c.id_consorcio
WHERE
    r.reparacion_comun = false;

-- Vista para ver el salario de los encargados de cada consorcio
CREATE VIEW vista_salarios_encargados_consorcio AS
SELECT
    c.id_consorcio,
    c.razon_social,
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
    a.email AS email_administrador,
    funcion_obtener_total_expensas_administrador(a.id_administrador) AS total_expensas
FROM 
    Administradores a;
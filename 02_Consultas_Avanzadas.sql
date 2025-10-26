
-- CONSULTAS AVANZADAS PARA E-COMMERCE


USE `proyecto_ecommerce`;

-- 1. TOP 10 PRODUCTOS MaS VENDIDOS
-- Quiero ver cuales son los productos que mas se venden

SELECT 
    p.id_producto,
    p.nombre,
    p.sku,
    p.precio,
    SUM(dv.cantidad) as total_vendido,
    COUNT(DISTINCT dv.id_venta_fk) as numero_ventas,
    SUM(dv.total_linea) as ingresos_totales
FROM productos p
INNER JOIN detalle_ventas dv ON p.id_producto = dv.id_producto_fk
INNER JOIN ventas v ON dv.id_venta_fk = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre, p.sku, p.precio
ORDER BY total_vendido DESC
LIMIT 10;

-- 2. PRODUCTOS CON BAJAS VENTAS
-- Para identificar productos que no se venden mucho

SELECT 
    p.id_producto,
    p.nombre,
    p.sku,
    p.precio,
    p.stock,
    p.stock_minimo,
    COALESCE(SUM(dv.cantidad), 0) as total_vendido,
    COALESCE(COUNT(DISTINCT dv.id_venta_fk), 0) as numero_ventas
FROM productos p
LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto_fk
LEFT JOIN ventas v ON dv.id_venta_fk = v.id_venta AND v.estado != 'Cancelado'
WHERE p.activo = 1
GROUP BY p.id_producto, p.nombre, p.sku, p.precio, p.stock, p.stock_minimo
HAVING total_vendido < 5 OR total_vendido = 0
ORDER BY total_vendido ASC;

-- 3. CLIENTES VIP
-- Los clientes que mas han gastado en mi tienda

SELECT 
    c.id_cliente,
    CONCAT(c.nombre, ' ', c.apellido) as nombre_completo,
    c.email,
    c.total_gastado,
    COUNT(DISTINCT v.id_venta) as total_compras,
    AVG(v.total) as promedio_compra
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente_fk AND v.estado != 'Cancelado'
GROUP BY c.id_cliente, c.nombre, c.apellido, c.email, c.total_gastado
HAVING c.total_gastado >= 1000
ORDER BY c.total_gastado DESC;

-- 4. ANaLISIS DE VENTAS MENSUALES
-- Para ver como van las ventas cada mes

SELECT 
    YEAR(v.fecha_venta) as año,
    MONTH(v.fecha_venta) as mes,
    MONTHNAME(v.fecha_venta) as nombre_mes,
    COUNT(DISTINCT v.id_venta) as total_ventas,
    SUM(v.total) as ingresos_totales,
    AVG(v.total) as promedio_venta
FROM ventas v
WHERE v.estado != 'Cancelado'
    AND v.fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(v.fecha_venta), MONTH(v.fecha_venta), MONTHNAME(v.fecha_venta)
ORDER BY año DESC, mes DESC;

-- 5. CRECIMIENTO DE CLIENTES
-- Para ver cuantos clientes nuevos tengo cada mes

SELECT 
    YEAR(c.fecha_registro) as año,
    MONTH(c.fecha_registro) as mes,
    MONTHNAME(c.fecha_registro) as nombre_mes,
    COUNT(*) as nuevos_clientes
FROM clientes c
WHERE c.fecha_registro >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(c.fecha_registro), MONTH(c.fecha_registro), MONTHNAME(c.fecha_registro)
ORDER BY año DESC, mes DESC;

-- 6. TASA DE COMPRA REPETIDA
-- Para ver cuantos clientes compran mas de una vez

SELECT 
    COUNT(*) as total_clientes,
    SUM(CASE WHEN COUNT(DISTINCT v.id_venta) > 1 THEN 1 ELSE 0 END) as clientes_repetidos,
    SUM(CASE WHEN COUNT(DISTINCT v.id_venta) = 1 THEN 1 ELSE 0 END) as clientes_una_compra
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente_fk AND v.estado != 'Cancelado'
GROUP BY c.id_cliente;

-- 7. PRODUCTOS COMPRADOS JUNTOS FRECUENTEMENTE
-- Para ver que productos se compran juntos (esta consulta es mas compleja)

SELECT 
    dv1.id_producto_fk as producto1,
    dv2.id_producto_fk as producto2,
    COUNT(*) as veces_juntos,
    p1.nombre as nombre_producto1,
    p2.nombre as nombre_producto2
FROM detalle_ventas dv1
INNER JOIN detalle_ventas dv2 ON dv1.id_venta_fk = dv2.id_venta_fk 
    AND dv1.id_producto_fk < dv2.id_producto_fk
INNER JOIN productos p1 ON dv1.id_producto_fk = p1.id_producto
INNER JOIN productos p2 ON dv2.id_producto_fk = p2.id_producto
INNER JOIN ventas v ON dv1.id_venta_fk = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY dv1.id_producto_fk, dv2.id_producto_fk, p1.nombre, p2.nombre
HAVING COUNT(*) >= 2
ORDER BY veces_juntos DESC
LIMIT 10;
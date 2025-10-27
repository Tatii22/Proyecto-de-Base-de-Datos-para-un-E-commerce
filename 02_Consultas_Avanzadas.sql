
-- CONSULTAS AVANZADAS PARA E-COMMERCE


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

-- Rotación de Inventario: Calcular la tasa de rotación de stock para cada categoría de producto.
SELECT 
    p.id_producto,
    p.nombre,
    SUM(d.cantidad * p.costo) AS costo_ventas,
    AVG(p.stock * p.costo) AS inventario_promedio_valor,
    CASE 
        WHEN AVG(p.stock * p.costo) > 0 THEN 
            ROUND(SUM(d.cantidad * p.costo) / AVG(p.stock * p.costo), 2)
        ELSE 0
    END AS rotacion_inventario
FROM productos p
JOIN detalle_ventas d ON p.id_producto = d.id_producto_fk
GROUP BY p.id_producto, p.nombre
ORDER BY rotacion_inventario DESC;


-- Productos que Necesitan Reabastecimiento: Listar productos cuyo stock actual está por debajo de su umbral mínimo.
SELECT 
    p.id_producto,
    p.nombre,
    p.stock,
    p.stock_minimo,
    (p.stock_minimo - p.stock) AS cantidad_a_reponer
FROM productos p
WHERE p.stock_minimo IS NOT NULL
  AND p.stock < p.stock_minimo
ORDER BY cantidad_a_reponer DESC;


-- Análisis de Carrito Abandonado (Simulado): Identificar clientes que agregaron productos pero no completaron una venta en un período determinado.
SELECT 
    c.id_carrito,
    c.fecha_creacion,
    c.fecha_cierre,
    c.id_cliente_fk,
    COUNT(pc.id_producto_fk) AS total_productos,
    SUM(pc.cantidad) AS cantidad_total_articulos
FROM carritos c
LEFT JOIN productos_carritos pc 
    ON c.id_carrito = pc.id_carrito_fk
WHERE c.estado = 'Abandonado'
GROUP BY 
    c.id_carrito,
    c.fecha_creacion,
    c.fecha_cierre,
    c.id_cliente_fk
ORDER BY c.fecha_creacion DESC;

-- Rendimiento de Proveedores: Clasificar a los proveedores según el volumen de ventas de sus productos.

SELECT p.id_proveedor_fk AS proveedor,
       pr.nombre AS nombre_proveedor,
       SUM(p.costo * p.stock) AS total_inventario
FROM productos p
JOIN proveedores pr ON p.id_proveedor_fk = pr.id_proveedor
GROUP BY p.id_proveedor_fk;

SELECT pr.nombre AS proveedor,
       AVG(p.precio - p.costo) AS margen_promedio
FROM productos p
JOIN proveedores pr ON p.id_proveedor_fk = pr.id_proveedor
GROUP BY pr.id_proveedor;

-- Análisis Geográfico de Ventas: Agrupar las ventas por ciudad o región del cliente.

SELECT pa.pais,
       SUM(pc.cantidad * p.precio) AS total_ventas
FROM carritos ca
JOIN clientes cl ON ca.id_cliente_fk = cl.id_cliente
JOIN barrios b ON cl.id_barrio_fk = b.id_barrio
JOIN ciudades ci ON b.id_ciudad_fk = ci.id_ciudad
JOIN paises pa ON ci.id_pais_fk = pa.id_pais
JOIN productos_carritos pc ON ca.id_carrito = pc.id_carrito_fk
JOIN productos p ON pc.id_producto_fk = p.id_producto
WHERE ca.estado = 'Convertido'
GROUP BY pa.id_pais
ORDER BY total_ventas DESC;

SELECT ci.ciudad,
       SUM(pc.cantidad * p.precio) AS total_ventas
FROM carritos ca
JOIN clientes cl ON ca.id_cliente_fk = cl.id_cliente
JOIN barrios b ON cl.id_barrio_fk = b.id_barrio
JOIN ciudades ci ON b.id_ciudad_fk = ci.id_ciudad
JOIN productos_carritos pc ON ca.id_carrito = pc.id_carrito_fk
JOIN productos p ON pc.id_producto_fk = p.id_producto
WHERE ca.estado = 'Convertido'
GROUP BY ci.id_ciudad
ORDER BY total_ventas DESC;

-- Ventas por Hora del Día: Determinar las horas pico de compras para optimizar campañas de marketing.

SELECT 
    HOUR(v.fecha_venta) AS hora_del_dia,
    COUNT(v.id_venta) AS cantidad_ventas,
    SUM(v.total) AS total_facturado
FROM ventas v
GROUP BY HOUR(v.fecha_venta)
ORDER BY cantidad_ventas DESC;

-- Impacto de Promociones: Comparar las ventas de un producto antes, durante y después de una campaña de descuento.

SELECT 
    CASE 
        WHEN pp.id_promocion_fk IS NOT NULL THEN 'Con Promoción'
        ELSE 'Sin Promoción'
    END AS tipo_venta,
    COUNT(*) AS cantidad_ventas,
    SUM(dv.total_linea) AS total_facturado
FROM detalle_ventas dv
LEFT JOIN promociones_producto pp ON dv.id_producto_fk = pp.id_producto_fk
LEFT JOIN promociones p 
       ON pp.id_promocion_fk = p.id_promocion 
      AND dv.precio_unitario_congelado < (SELECT precio FROM productos WHERE id_producto = dv.id_producto_fk)
GROUP BY tipo_venta
ORDER BY cantidad_ventas DESC;

SELECT 
    promo.nombre AS campaña,
    COUNT(*) AS ventas_campaña,
    SUM(dv.cantidad) AS unidades_vendidas,
    SUM(dv.total_linea) AS ingresos_campaña
FROM promociones promo
JOIN promociones_producto pp ON promo.id_promocion = pp.id_promocion_fk
JOIN detalle_ventas dv ON pp.id_producto_fk = dv.id_producto_fk
GROUP BY promo.id_promocion
ORDER BY ingresos_campaña DESC;

-- Análisis de Cohort: Analizar la retención de clientes mes a mes desde su primera compra.
SELECT
    CONCAT(
        YEAR(c.fecha_minima),
        '-',
        LPAD(MONTH(c.fecha_minima), 2, '0')
    ) AS cohorte,
    TIMESTAMPDIFF(
        MONTH,
        c.fecha_minima,
        v.fecha_venta
    ) AS meses_despues,
    COUNT(DISTINCT v.id_cliente_fk) AS clientes_activos
FROM ventas v
    INNER JOIN (
        SELECT id_cliente_fk, MIN(fecha_venta) AS fecha_minima
        FROM ventas
        GROUP BY
            id_cliente_fk
    ) c ON v.id_cliente_fk = c.id_cliente_fk
WHERE
    v.estado = 'Entregado'
GROUP BY
    cohorte,
    meses_despues
ORDER BY cohorte, meses_despues;

-- Margen de Beneficio por Producto: Calcular el margen de beneficio para cada producto (requiere añadir un campo costo a la tabla productos).
SELECT
    p.id_producto,
    p.nombre AS producto,
    p.precio AS precio_venta,
    p.costo AS costo_producto,
    (p.precio - p.costo) AS margen_absoluto,
    ROUND(((p.precio - p.costo) / p.precio) * 100, 2) AS margen_porcentual
FROM productos p
ORDER BY margen_porcentual DESC;
-- Tiempo Promedio Entre Compras: Calcular el tiempo medio que tarda un cliente en volver a comprar.
SELECT 
    v.id_cliente_fk,
    c.nombre AS nombre_cliente,
    c.apellido AS apellido_cliente,
    ROUND(AVG(DATEDIFF(v.fecha_venta, v_prev.fecha_venta)), 2) AS dias_promedio
FROM ventas v
JOIN ventas v_prev ON v.id_cliente_fk = v_prev.id_cliente_fk AND v.fecha_venta > v_prev.fecha_venta
JOIN clientes c ON v.id_cliente_fk = c.id_cliente
WHERE v.estado = 'Entregado' 
GROUP BY v.id_cliente_fk, c.nombre, c.apellido
HAVING COUNT(v.id_cliente_fk) > 1 
ORDER BY dias_promedio;
-- Productos Más Vistos vs. Comprados: Comparar los productos más visitados con los más comprados.
SELECT 
    p.id_producto,
    p.nombre AS producto,
    p.visto AS veces_visto,
    COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas,
    (p.visto - COALESCE(SUM(dv.cantidad), 0)) AS diferencia_vistas_compras
FROM productos p
LEFT JOIN detalle_ventas dv 
    ON p.id_producto = dv.id_producto_fk
GROUP BY p.id_producto, p.nombre, p.visto
ORDER BY p.visto DESC, unidades_vendidas DESC;
-- Segmentación de Clientes (RFM): Clasificar a los clientes en segmentos (Recencia, Frecuencia, Monetario).
CREATE VIEW segmentacion_rfm AS
SELECT
    v.id_cliente_fk,
    DATEDIFF(
        (SELECT MAX(fecha_venta) FROM ventas),
        MAX(v.fecha_venta)
    ) AS recencia,                      
    COUNT(v.id_venta) AS frecuencia,    
    SUM(v.total) AS valor_monetario,     
    CASE
        WHEN DATEDIFF((SELECT MAX(fecha_venta) FROM ventas), MAX(v.fecha_venta)) <= 30 THEN 'R1 - Muy reciente'
        WHEN DATEDIFF((SELECT MAX(fecha_venta) FROM ventas), MAX(v.fecha_venta)) <= 90 THEN 'R2 - Reciente'
        WHEN DATEDIFF((SELECT MAX(fecha_venta) FROM ventas), MAX(v.fecha_venta)) <= 180 THEN 'R3 - Inactivo'
        ELSE 'R4 - Perdido'
    END AS categoria_recencia,
    CASE
        WHEN COUNT(v.id_venta) >= 10 THEN 'F1 - Frecuente'
        WHEN COUNT(v.id_venta) >= 5 THEN 'F2 - Ocasional'
        ELSE 'F3 - Esporádico'
    END AS categoria_frecuencia,
    CASE
        WHEN SUM(v.total) >= 1000000 THEN 'M1 - Alto valor'
        WHEN SUM(v.total) >= 500000 THEN 'M2 - Medio valor'
        ELSE 'M3 - Bajo valor'
    END AS categoria_monetaria
FROM ventas v
WHERE v.estado = 'Entregado'
GROUP BY v.id_cliente_fk;
SELECT * FROM segmentacion_rfm;
-- Predicción de Demanda Simple: Utilizar datos de ventas pasadas para proyectar las ventas del próximo mes para una categoría específica.
SELECT 
    c.id_categoria,
    c.nombre AS nombre_categoria,
    ROUND(AVG(ventas_mensuales.total_ventas), 2) AS promedio_mensual,
    ROUND(AVG(ventas_mensuales.total_ventas), 2) AS proyeccion_mes
FROM (
    SELECT 
        p.id_categoria_fk AS id_categoria,
        YEAR(v.fecha_venta) AS anio,
        MONTH(v.fecha_venta) AS mes,
        SUM(dv.cantidad * dv.precio_unitario_congelado) AS total_ventas
    FROM ventas v
        INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta_fk
        INNER JOIN productos p ON dv.id_producto_fk = p.id_producto
    WHERE v.estado = 'Entregado'
    GROUP BY p.id_categoria_fk, anio, mes
) AS ventas_mensuales
INNER JOIN categorias c ON c.id_categoria = ventas_mensuales.id_categoria
GROUP BY c.id_categoria, c.nombre
ORDER BY promedio_mensual DESC;



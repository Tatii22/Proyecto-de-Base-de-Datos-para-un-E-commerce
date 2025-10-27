    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    -- Top 10 Productos Más Vendidos: Generar un ranking con los 10 productos que han generado más ingresos.
    -- Productos con Bajas Ventas: Identificar los productos en el 10% inferior de ventas para considerar su descontinuación.
    -- Clientes VIP: Listar los 5 clientes con el mayor valor de vida (LTV), basado en su gasto total histórico.
    -- Análisis de Ventas Mensuales: Mostrar las ventas totales agrupadas por mes y año.
    -- Crecimiento de Clientes: Calcular el número de nuevos clientes registrados por trimestre.
    -- Tasa de Compra Repetida: Determinar qué porcentaje de clientes ha realizado más de una compra.
    -- Productos Comprados Juntos Frecuentemente: Identificar pares de productos que a menudo se compran en la misma transacción.
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



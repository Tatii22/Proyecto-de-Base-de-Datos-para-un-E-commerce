-- FUNCIONALIDADES ADICIONALES PARA MI TIENDA


USE `proyecto_ecommerce`;

-- VISTAS UTILES
-- Estas vistas me ayudan a ver la informacion mas facil

-- Vista para productos con informacion completa
CREATE VIEW vw_ProductosCompletos AS
SELECT 
    p.id_producto,
    p.nombre,
    p.descripcion,
    p.precio,
    p.costo,
    p.stock,
    p.stock_minimo,
    p.sku,
    p.activo,
    pr.nombre as proveedor,
    c.nombre as categoria,
    (p.precio - p.costo) as margen_unitario
FROM productos p
INNER JOIN proveedores pr ON p.id_proveedor_fk = pr.id_proveedor
INNER JOIN categorias c ON p.id_categoria_fk = c.id_categoria;

-- Vista para clientes con informacion de ubicacion
CREATE VIEW vw_ClientesCompletos AS
SELECT 
    c.id_cliente,
    c.nombre,
    c.apellido,
    c.email,
    c.telefono_contacto,
    c.fecha_registro,
    c.total_gastado,
    b.barrio,
    ci.ciudad,
    pa.pais,
    fn_FormatearNombreCompleto(c.nombre, c.apellido) as nombre_completo
FROM clientes c
INNER JOIN barrios b ON c.id_barrio_fk = b.id_barrio
INNER JOIN ciudades ci ON b.id_ciudad_fk = ci.id_ciudad
INNER JOIN paises pa ON ci.id_pais_fk = pa.id_pais;

-- Vista para ventas con informacion detallada
CREATE VIEW vw_VentasDetalladas AS
SELECT 
    v.id_venta,
    v.fecha_venta,
    v.estado,
    v.total,
    CONCAT(c.nombre, ' ', c.apellido) as cliente,
    s.nombre as sucursal,
    COUNT(dv.id_producto_fk) as productos_comprados,
    SUM(dv.cantidad) as unidades_totales
FROM ventas v
INNER JOIN clientes c ON v.id_cliente_fk = c.id_cliente
INNER JOIN sucursales s ON v.id_sucursal_fk = s.id_sucursal
INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta_fk
GROUP BY v.id_venta, v.fecha_venta, v.estado, v.total, c.nombre, c.apellido, s.nombre;

-- INDICES PARA MEJORAR RENDIMIENTO
-- Estos indices hacen que las consultas sean mas rapidas

CREATE INDEX idx_ventas_fecha_estado ON ventas(fecha_venta, estado);
CREATE INDEX idx_ventas_cliente ON ventas(id_cliente_fk);
CREATE INDEX idx_detalle_ventas_producto ON detalle_ventas(id_producto_fk);
CREATE INDEX idx_productos_activo ON productos(activo);
CREATE INDEX idx_clientes_email ON clientes(email);

-- FUNCIONES UTILES ADICIONALES

-- Funcion para formatear moneda
DELIMITER $$
CREATE FUNCTION fn_FormatearMoneda(
    p_cantidad DECIMAL(10,2),
    p_moneda VARCHAR(3)
) RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_formato VARCHAR(20);
    
    CASE p_moneda
        WHEN 'USD' THEN
            SET v_formato = CONCAT('$', FORMAT(p_cantidad, 2));
        WHEN 'EUR' THEN
            SET v_formato = CONCAT('€', FORMAT(p_cantidad, 2));
        WHEN 'COP' THEN
            SET v_formato = CONCAT('$', FORMAT(p_cantidad, 0));
        ELSE
            SET v_formato = CONCAT(p_moneda, ' ', FORMAT(p_cantidad, 2));
    END CASE;
    
    RETURN v_formato;
END$$
DELIMITER ;

-- CONSULTAS UTILES PARA ANALISIS

-- Analisis de productos mas rentables
SELECT 
    p.id_producto,
    p.nombre,
    p.precio,
    p.costo,
    (p.precio - p.costo) as margen_unitario,
    SUM(dv.cantidad) as unidades_vendidas,
    SUM(dv.total_linea) as ingresos_totales,
    (SUM(dv.total_linea) - SUM(dv.cantidad * p.costo)) as ganancia_total
FROM productos p
INNER JOIN detalle_ventas dv ON p.id_producto = dv.id_producto_fk
INNER JOIN ventas v ON dv.id_venta_fk = v.id_venta
WHERE v.estado = 'Entregado'
GROUP BY p.id_producto, p.nombre, p.precio, p.costo
HAVING ganancia_total > 0
ORDER BY ganancia_total DESC
LIMIT 10;

-- Analisis de abandono de carritos
SELECT 
    DATE(fecha_creacion) as fecha,
    COUNT(*) as carritos_creados,
    SUM(CASE WHEN estado = 'Convertido' THEN 1 ELSE 0 END) as carritos_convertidos,
    SUM(CASE WHEN estado = 'Abandonado' THEN 1 ELSE 0 END) as carritos_abandonados
FROM carritos
WHERE fecha_creacion >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(fecha_creacion)
ORDER BY fecha DESC;
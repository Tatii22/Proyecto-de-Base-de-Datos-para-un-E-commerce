
-- EVENTOS PROGRAMADOS PARA MI TIENDA


USE `proyecto_ecommerce`;

-- Primero habilito el programador de eventos
SET GLOBAL event_scheduler = ON;

-- 1. evt_generate_weekly_sales_report
-- Este evento genera un reporte semanal automaticamente

DELIMITER $$
CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS '2024-01-01 08:00:00'
DO
BEGIN
    DECLARE v_fecha_inicio DATE;
    DECLARE v_fecha_fin DATE;
    DECLARE v_total_ventas DECIMAL(10,2);
    DECLARE v_numero_ventas INT;
    
    -- Calculo las fechas de la semana pasada
    SET v_fecha_inicio = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 7 DAY);
    SET v_fecha_fin = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 1 DAY);
    
    -- Cuento las ventas de esa semana
    SELECT 
        COALESCE(SUM(total), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_ventas, v_numero_ventas
    FROM ventas
    WHERE fecha_venta BETWEEN v_fecha_inicio AND v_fecha_fin
    AND estado != 'Cancelado';
    
    -- Guardo el reporte
    INSERT INTO reportes_semanales (fecha_inicio, fecha_fin, total_ventas, numero_ventas)
    VALUES (v_fecha_inicio, v_fecha_fin, v_total_ventas, v_numero_ventas);
END$$
DELIMITER ;

-- 2. evt_cleanup_temp_tables_daily

DELIMITER $$
CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2024-01-01 02:00:00'
DO
BEGIN
    -- Limpiar tablas temporales y logs antiguos
    DELETE FROM permisos_log 
    WHERE fecha_evento < DATE_SUB(NOW(), INTERVAL 90 DAY);
    
    DELETE FROM alertas_stock 
    WHERE fecha < DATE_SUB(NOW(), INTERVAL 30 DAY) 
    AND estado = 'Atendida';
    
    -- Limpiar carritos abandonados (mas de 30 dias)
    DELETE FROM productos_carritos 
    WHERE id_carritos_fk IN (
        SELECT id_carritos FROM carritos 
        WHERE estado = 'Abandonado' 
        AND fecha_creacion < DATE_SUB(NOW(), INTERVAL 30 DAY)
    );
    
    DELETE FROM carritos 
    WHERE estado = 'Abandonado' 
    AND fecha_creacion < DATE_SUB(NOW(), INTERVAL 30 DAY);
    
    -- Registrar en log
    INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
    VALUES ('SYSTEM', 'DAILY_CLEANUP', 'Limpieza diaria de tablas temporales completada', 1);
END$$
DELIMITER ;

-- 3. evt_archive_old_logs_monthly

DELIMITER $$
CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-01-01 03:00:00'
DO
BEGIN
    DECLARE v_fecha_archivo DATE;
    
    SET v_fecha_archivo = DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    
    
    
    -- Archivar logs de precios antiguos
    INSERT INTO auditoria_precios_archivo 
    SELECT * FROM auditoria_precios 
    WHERE fecha_cambio < v_fecha_archivo;
    
    DELETE FROM auditoria_precios 
    WHERE fecha_cambio < v_fecha_archivo;
    
    -- Archivar logs de permisos antiguos
    INSERT INTO permisos_log_archivo 
    SELECT * FROM permisos_log 
    WHERE fecha_evento < v_fecha_archivo;
    
    DELETE FROM permisos_log 
    WHERE fecha_evento < v_fecha_archivo;
    
    -- Registrar en log
    INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
    VALUES ('SYSTEM', 'MONTHLY_ARCHIVE', CONCAT('Archivo mensual completado para fecha: ', v_fecha_archivo), 1);
END$$
DELIMITER ;

-- 4. evt_deactivate_expired_promotions_hourly

DELIMITER $$
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS '2024-01-01 00:00:00'
DO
BEGIN
    DECLARE v_promociones_desactivadas INT DEFAULT 0;
    
    -- Desactivar promociones expiradas
    UPDATE promociones 
    SET activa = 0 
    WHERE activa = 1 
    AND fecha_fin < NOW();
    
    SET v_promociones_desactivadas = ROW_COUNT();
    
    -- Registrar en log si hubo cambios
    IF v_promociones_desactivadas > 0 THEN
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES ('SYSTEM', 'DEACTIVATE_PROMOTIONS', CONCAT('Promociones desactivadas: ', v_promociones_desactivadas), 1);
    END IF;
END$$
DELIMITER ;

-- 5. evt_recalculate_customer_loyalty_tiers_nightly

DELIMITER $$
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2024-01-01 01:00:00'
DO
BEGIN
    DECLARE v_clientes_actualizados INT DEFAULT 0;
    
    
    
    -- Insertar niveles si no existen
    INSERT IGNORE INTO niveles_lealtad (nombre, total_gastado_minimo, numero_compras_minimo, descuento_porcentaje)
    VALUES 
        ('VIP Oro', 10000.00, 10, 15.00),
        ('VIP Plata', 5000.00, 5, 10.00),
        ('VIP Bronce', 2000.00, 3, 5.00),
        ('Cliente Frecuente', 500.00, 1, 2.00);
    
    -- Actualizar total gastado de clientes basado en ventas entregadas
    UPDATE clientes c
    SET total_gastado = (
        SELECT COALESCE(SUM(v.total), 0)
        FROM ventas v
        WHERE v.id_cliente_fk = c.id_cliente
        AND v.estado = 'Entregado'
    );
    
    SET v_clientes_actualizados = ROW_COUNT();
    
    -- Registrar en log
    INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
    VALUES ('SYSTEM', 'RECALCULATE_LOYALTY', CONCAT('Niveles de lealtad recalculados para ', v_clientes_actualizados, ' clientes'), 1);
END$$
DELIMITER ;

-- 6. evt_generate_reorder_list_daily

DELIMITER $$
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2024-01-01 07:00:00'
DO
BEGIN
    DECLARE v_productos_reorden INT DEFAULT 0;
    
    
    -- Limpiar lista anterior
    DELETE FROM lista_reorden WHERE estado = 'Pendiente';
    
    -- Generar nueva lista de reorden
    INSERT INTO lista_reorden (id_producto, nombre_producto, stock_actual, stock_minimo, cantidad_sugerida)
    SELECT 
        p.id_producto,
        p.nombre,
        p.stock,
        p.stock_minimo,
        CEIL(p.stock_minimo * 2) as cantidad_sugerida
    FROM productos p
    WHERE p.activo = 1
    AND p.stock <= p.stock_minimo
    AND p.stock_minimo IS NOT NULL;
    
    SET v_productos_reorden = ROW_COUNT();
    
    -- Registrar en log
    INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
    VALUES ('SYSTEM', 'GENERATE_REORDER', CONCAT('Lista de reorden generada con ', v_productos_reorden, ' productos'), 1);
END$$
DELIMITER ;
 
-- evt_rebuild_indexes_weekly: Reconstruye los índices de las tablas más usadas para optimizar el rendimiento.
DELIMITER $$

CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    OPTIMIZE TABLE
        productos,
        ventas,
        detalle_ventas,
        clientes,
        proveedores,
        categorias;
END$$

DELIMITER ;

-- evt_suspend_inactive_accounts_quarterly: Desactiva cuentas de clientes sin actividad en más de un año.
SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE clientes c
    SET c.estado = 'Inactivo'
    WHERE c.estado = 'Activo'
      AND c.id_cliente IN (
            SELECT v.id_cliente_fk
            FROM ventas v
            GROUP BY v.id_cliente_fk
            HAVING MAX(v.fecha_venta) < DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
      );
END$$

DELIMITER ;

-- evt_aggregate_daily_sales_data: Agrega los datos de ventas del día en una tabla de resumen para acelerar reportes.



DELIMITER $$

CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY)
DO
BEGIN
    INSERT INTO ventas_resumen_diario (fecha, total_ventas, cantidad_transacciones, cantidad_productos_vendidos)
    SELECT 
        DATE(v.fecha_venta) AS fecha,
        SUM(v.total) AS total_ventas,
        COUNT(DISTINCT v.id_venta) AS cantidad_transacciones,
        SUM(dv.cantidad) AS cantidad_productos_vendidos
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta_fk
    WHERE v.fecha_venta >= CURDATE() - INTERVAL 1 DAY
      AND v.fecha_venta < CURDATE()
    GROUP BY DATE(v.fecha_venta)
    ON DUPLICATE KEY UPDATE
        total_ventas = VALUES(total_ventas),
        cantidad_transacciones = VALUES(cantidad_transacciones),
        cantidad_productos_vendidos = VALUES(cantidad_productos_vendidos);
END$$

DELIMITER ;

-- evt_check_data_consistency_nightly: Busca inconsistencias en los datos (ej. ventas sin detalles).

SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY) + INTERVAL 2 HOUR
DO
BEGIN
    DECLARE v_count INT;


    SELECT COUNT(*) INTO v_count FROM ventas WHERE total < 0;
    IF v_count > 0 THEN
        INSERT INTO auditoria_inconsistencias (descripcion, registros_afectados)
        VALUES ('Ventas con total negativo', v_count);
    END IF;


    SELECT COUNT(*) INTO v_count FROM productos WHERE stock < 0;
    IF v_count > 0 THEN
        INSERT INTO auditoria_inconsistencias (descripcion, registros_afectados)
        VALUES ('Productos con stock negativo', v_count);
    END IF;


    SELECT COUNT(*) INTO v_count
    FROM detalle_ventas dv
    LEFT JOIN productos p ON dv.id_producto_fk = p.id_producto
    WHERE p.id_producto IS NULL;
    IF v_count > 0 THEN
        INSERT INTO auditoria_inconsistencias (descripcion, registros_afectados)
        VALUES ('Detalle de ventas sin producto asociado', v_count);
    END IF;


    SELECT COUNT(*) INTO v_count
    FROM clientes
    WHERE email NOT LIKE '%@%.%';
    IF v_count > 0 THEN
        INSERT INTO auditoria_inconsistencias (descripcion, registros_afectados)
        VALUES ('Clientes con email de formato inválido', v_count);
    END IF;

END$$

DELIMITER ;

-- evt_send_birthday_greetings_daily: Genera una lista de clientes que cumplen años para enviarles un cupón.
-- Crear tabla auxiliar para almacenar los envíos de felicitaciones



SET GLOBAL event_scheduler = ON;


CREATE EVENT IF NOT EXISTS evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
INSERT INTO greetings_logs (id_cliente, fecha_envio, mensaje)
SELECT id_cliente, NOW(), CONCAT('Feliz cumpleaños ', nombre, '!')
FROM clientes
WHERE DATE_FORMAT(fecha_nacimiento, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d');

-- evt_update_product_rankings_hourly: Actualiza una tabla con el ranking de los productos más populares.

SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
DO
BEGIN

    DELETE FROM rankings_productos;


    INSERT INTO rankings_productos (id_producto_fk, total_vendido, calificacion_promedio)
    SELECT 
        p.id_producto,
        COALESCE(SUM(dv.cantidad), 0) AS total_vendido,
        COALESCE(AVG(r.calificacion), 0) AS calificacion_promedio
    FROM productos p
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto_fk
    LEFT JOIN reseñas r ON p.id_producto = r.id_producto_fk
    GROUP BY p.id_producto;


    UPDATE rankings_productos rp
    JOIN (
        SELECT id, ROW_NUMBER() OVER (ORDER BY total_vendido DESC) AS rn
        FROM rankings_productos
    ) AS x ON rp.id = x.id
    SET rp.ranking_ventas = x.rn;


    UPDATE rankings_productos rp
    JOIN (
        SELECT id, ROW_NUMBER() OVER (ORDER BY calificacion_promedio DESC) AS rn
        FROM rankings_productos
    ) AS y ON rp.id = y.id
    SET rp.ranking_valoracion = y.rn;
END$$

DELIMITER ;

-- evt_backup_critical_tables_daily: Realiza un backup lógico de las tablas más importantes cada noche.
DELIMITER $$

CREATE EVENT evt_backup_critical_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN

    CREATE TABLE IF NOT EXISTS backup_pedidos LIKE pedidos;
    INSERT INTO backup_pedidos SELECT * FROM pedidos;


    CREATE TABLE IF NOT EXISTS backup_clientes LIKE clientes;
    INSERT INTO backup_clientes SELECT * FROM clientes;
END $$

DELIMITER ;
    
-- evt_clear_abandoned_carts_daily: Vacía los carritos de compra abandonados hace más de 72 horas.
SET GLOBAL event_scheduler = ON;
CREATE EVENT IF NOT EXISTS evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DELETE FROM carritos
    WHERE estado = 'Abandonado'
      AND fecha_creacion < NOW() - INTERVAL 72 HOUR;
END;

-- evt_calculate_monthly_kpis: Calcula los KPIs (Key Performance Indicators) del mes y los guarda en una tabla.

SET GLOBAL event_scheduler = ON;



CREATE EVENT IF NOT EXISTS evt_calculate_monthly_kpis
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    DECLARE v_mes INT;
    DECLARE v_anio INT;

    SET v_mes = MONTH(CURRENT_DATE - INTERVAL 1 MONTH); -- mes anterior
    SET v_anio = YEAR(CURRENT_DATE - INTERVAL 1 MONTH);

    INSERT INTO kpis_mensuales (mes, anio, total_ventas, total_clientes, promedio_venta)
    SELECT
        v_mes,
        v_anio,
        SUM(total) AS total_ventas,
        COUNT(DISTINCT id_cliente_fk) AS total_clientes,
        AVG(total) AS promedio_venta
    FROM ventas
    WHERE MONTH(fecha_venta) = v_mes AND YEAR(fecha_venta) = v_anio;
END;

-- evt_refresh_materialized_views_nightly: Actualiza las vistas materializadas (si se usan).

SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS evt_refresh_materialized_views_nightly
ON SCHEDULE EVERY 1 DAY
STARTS CONCAT(CURDATE(), ' 02:00:00')
DO
BEGIN
    TRUNCATE TABLE vista_ejemplo;
    INSERT INTO vista_ejemplo (id_cliente, total_ventas, total_compras)
    SELECT
        id_cliente_fk,
        SUM(total) AS total_ventas,
        COUNT(*) AS total_compras
    FROM ventas
    GROUP BY id_cliente_fk;

END;

-- evt_log_database_size_weekly: Registra el tamaño de la base de datos para monitorear su crecimiento.
-- Activar el scheduler de eventos si no está activo
SET GLOBAL event_scheduler = ON;

-- Crear la tabla para almacenar el historial de tamaño



CREATE EVENT IF NOT EXISTS evt_log_database_size_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CONCAT(CURDATE(), ' 00:00:00')
DO
BEGIN
    DECLARE db_name VARCHAR(100);
    DECLARE db_size DECIMAL(10,2);

    SET db_name = DATABASE();

    SELECT SUM(data_length + index_length)/1024/1024
    INTO db_size
    FROM information_schema.tables
    WHERE table_schema = db_name;
    INSERT INTO historial_tamano_db (nombre_db, tamano_mb)
    VALUES (db_name, db_size);
END;

-- evt_detect_fraudulent_activity_hourly: Busca patrones de actividad sospechosa (ej. múltiples pedidos fallidos).

SET GLOBAL event_scheduler = ON;




CREATE EVENT IF NOT EXISTS evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    INSERT INTO historial_actividad_sospechosa (id_cliente, tipo_actividad, detalle)
    SELECT v.id_cliente_fk, 'Pedidos Fallidos Repetidos', 
           CONCAT('Cliente con ', COUNT(*) , ' pedidos fallidos en la última hora')
    FROM ventas v
    WHERE v.estado = 'Cancelado'
      AND v.fecha_venta >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    GROUP BY v.id_cliente_fk
    HAVING COUNT(*) >= 3;
END;

-- evt_generate_supplier_performance_report_monthly: Crea un reporte mensual sobre el rendimiento de los proveedores.
-- Activar el scheduler si no está activo
SET GLOBAL event_scheduler = ON;



CREATE EVENT IF NOT EXISTS evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-11-01 00:00:00'
DO
BEGIN
    INSERT INTO reporte_rendimiento_proveedores (id_proveedor, total_productos_vendidos, total_ingresos, fecha_reporte)
    SELECT p.id_proveedor_fk,
           SUM(d.cantidad) AS total_productos_vendidos,
           SUM(d.total_linea) AS total_ingresos,
           CURDATE() AS fecha_reporte
    FROM detalle_ventas d
    JOIN productos p ON d.id_producto_fk = p.id_producto
    WHERE d.fecha_venta BETWEEN DATE_FORMAT(CURDATE() - INTERVAL 1 MONTH, '%Y-%m-01')
                             AND LAST_DAY(CURDATE() - INTERVAL 1 MONTH)
    GROUP BY p.id_proveedor_fk;
END;

-- -- evt_purge_soft_deleted_records_weekly: Elimina permanentemente los registros marcados para borrado hace más de 30 días.

SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS '2025-11-01 00:00:00'
DO
BEGIN

    DELETE FROM usuarios_soft_delete
    WHERE borrado = 1
      AND fecha_eliminado <= NOW() - INTERVAL 30 DAY;

END;

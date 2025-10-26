
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
    
    -- Creo la tabla si no existe
    CREATE TABLE IF NOT EXISTS reportes_semanales (
        id_reporte INT AUTO_INCREMENT PRIMARY KEY,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NOT NULL,
        total_ventas DECIMAL(10,2) NOT NULL,
        numero_ventas INT NOT NULL,
        fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;
    
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
    
    -- Crear tabla de archivo si no existe
    CREATE TABLE IF NOT EXISTS auditoria_precios_archivo LIKE auditoria_precios;
    CREATE TABLE IF NOT EXISTS permisos_log_archivo LIKE permisos_log;
    
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
    
    -- Crear tabla de niveles de lealtad si no existe
    CREATE TABLE IF NOT EXISTS niveles_lealtad (
        id_nivel INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        total_gastado_minimo DECIMAL(10,2) NOT NULL,
        numero_compras_minimo INT NOT NULL,
        descuento_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0
    ) ENGINE=InnoDB;
    
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
    
    -- Crear tabla de lista de reorden si no existe
    CREATE TABLE IF NOT EXISTS lista_reorden (
        id_reorden INT AUTO_INCREMENT PRIMARY KEY,
        id_producto INT NOT NULL,
        nombre_producto VARCHAR(50) NOT NULL,
        stock_actual DECIMAL(10,2) NOT NULL,
        stock_minimo DECIMAL(10,2) NOT NULL,
        cantidad_sugerida INT NOT NULL,
        fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        estado ENUM('Pendiente', 'Procesada', 'Cancelada') NOT NULL DEFAULT 'Pendiente',
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    ) ENGINE=InnoDB;
    
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
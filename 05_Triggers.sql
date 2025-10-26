
-- TRIGGERS PARA MI TIENDA


USE `proyecto_ecommerce`;

-- 1. trg_audit_precio_producto_after_update
-- Este trigger guarda cuando cambio el precio de un producto

DELIMITER $$
CREATE TRIGGER trg_audit_precio_producto_after_update
    AFTER UPDATE ON productos
    FOR EACH ROW
BEGIN
    -- Solo guardo si el precio realmente cambio
    IF OLD.precio != NEW.precio THEN
        INSERT INTO auditoria_precios (
            precio_anterior,
            precio_nuevo,
            fecha_cambio,
            usuario,
            id_producto_fk
        ) VALUES (
            OLD.precio,
            NEW.precio,
            NOW(),
            USER(),
            NEW.id_producto
        );
    END IF;
END$$
DELIMITER ;

-- 2. trg_check_stock_before_insert_venta
-- Este trigger revisa que haya stock antes de vender

DELIMITER $$
CREATE TRIGGER trg_check_stock_before_insert_venta
    BEFORE INSERT ON detalle_ventas
    FOR EACH ROW
BEGIN
    DECLARE v_stock_disponible DECIMAL(10,2);
    DECLARE v_nombre_producto VARCHAR(50);
    
    -- Busco cuanto stock hay del producto
    SELECT stock, nombre INTO v_stock_disponible, v_nombre_producto
    FROM productos
    WHERE id_producto = NEW.id_producto_fk;
    
    -- Si no hay suficiente stock, no dejo que se venda
    IF v_stock_disponible < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('No hay suficiente stock para: ', v_nombre_producto);
    END IF;
    
    -- Tambien verifico que el producto este activo
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = NEW.id_producto_fk AND activo = 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('El producto ', v_nombre_producto, ' no esta activo');
    END IF;
END$$
DELIMITER ;

-- 3. trg_update_stock_after_insert_venta

DELIMITER $$
CREATE TRIGGER trg_update_stock_after_insert_venta
    AFTER INSERT ON detalle_ventas
    FOR EACH ROW
BEGIN
    DECLARE v_estado_venta ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado');
    
    -- Obtener estado de la venta
    SELECT estado INTO v_estado_venta
    FROM ventas
    WHERE id_venta = NEW.id_venta_fk;
    
    -- Solo actualizar stock si la venta no esta cancelada
    IF v_estado_venta != 'Cancelado' THEN
        UPDATE productos
        SET stock = stock - NEW.cantidad
        WHERE id_producto = NEW.id_producto_fk;
        
        -- Verificar si el stock esta por debajo del minimo
        IF (SELECT stock FROM productos WHERE id_producto = NEW.id_producto_fk) <= 
           (SELECT stock_minimo FROM productos WHERE id_producto = NEW.id_producto_fk) THEN
            
            INSERT INTO alertas_stock (mensaje, fecha, id_producto_fk)
            VALUES (
                CONCAT('Stock bajo para producto: ', (SELECT nombre FROM productos WHERE id_producto = NEW.id_producto_fk)),
                NOW(),
                NEW.id_producto_fk
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- 4. trg_prevent_delete_categoria_with_products

DELIMITER $$
CREATE TRIGGER trg_prevent_delete_categoria_with_products
    BEFORE DELETE ON categorias
    FOR EACH ROW
BEGIN
    DECLARE v_productos_count INT;
    
    -- Contar productos asociados a la categoria
    SELECT COUNT(*) INTO v_productos_count
    FROM productos
    WHERE id_categoria_fk = OLD.id_categoria;
    
    -- Prevenir eliminacion si hay productos asociados
    IF v_productos_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('No se puede eliminar la categoria "', OLD.nombre, 
                                '" porque tiene ', v_productos_count, ' productos asociados');
    END IF;
END$$
DELIMITER ;

-- 5. trg_log_new_customer_after_insert

DELIMITER $$
CREATE TRIGGER trg_log_new_customer_after_insert
    AFTER INSERT ON clientes
    FOR EACH ROW
BEGIN
    -- Registrar nuevo cliente en auditoria
    INSERT INTO auditoria_clientes (accion, fecha_evento, usuario, id_cliente_fk, id_usuario_fk)
    VALUES (
        'INSERT',
        NOW(),
        USER(),
        NEW.id_cliente,
        1  -- Usuario por defecto para registros automaticos
    );
    
    -- Registrar en log de permisos
    INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
    VALUES (
        USER(),
        'NEW_CUSTOMER',
        CONCAT('Nuevo cliente registrado: ', NEW.nombre, ' ', NEW.apellido, ' (ID: ', NEW.id_cliente, ')'),
        1
    );
END$$
DELIMITER ;

-- 6. trg_update_total_gastado_cliente

DELIMITER $$
CREATE TRIGGER trg_update_total_gastado_cliente
    AFTER UPDATE ON ventas
    FOR EACH ROW
BEGIN
    DECLARE v_total_cliente DECIMAL(10,2);
    
    -- Solo actualizar si el estado cambio a 'Entregado'
    IF OLD.estado != 'Entregado' AND NEW.estado = 'Entregado' THEN
        -- Calcular total gastado por el cliente
        SELECT COALESCE(SUM(total), 0) INTO v_total_cliente
        FROM ventas
        WHERE id_cliente_fk = NEW.id_cliente_fk 
        AND estado = 'Entregado';
        
        -- Actualizar total gastado del cliente
        UPDATE clientes
        SET total_gastado = v_total_cliente
        WHERE id_cliente = NEW.id_cliente_fk;
    END IF;
END$$
DELIMITER ;

-- 7. trg_set_fecha_modificacion_producto

DELIMITER $$
CREATE TRIGGER trg_set_fecha_modificacion_producto
    BEFORE UPDATE ON productos
    FOR EACH ROW
BEGIN
    -- Actualizar fecha de modificacion
    SET NEW.fecha_creacion = OLD.fecha_creacion; -- Mantener fecha original
    
    -- Si se esta desactivando el producto, registrar en log
    IF OLD.activo = 1 AND NEW.activo = 0 THEN
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (
            USER(),
            'DEACTIVATE_PRODUCT',
            CONCAT('Producto desactivado: ', NEW.nombre, ' (ID: ', NEW.id_producto, ')'),
            1
        );
    END IF;
    
    -- Si se esta activando el producto, registrar en log
    IF OLD.activo = 0 AND NEW.activo = 1 THEN
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (
            USER(),
            'ACTIVATE_PRODUCT',
            CONCAT('Producto activado: ', NEW.nombre, ' (ID: ', NEW.id_producto, ')'),
            1
        );
    END IF;
END$$
DELIMITER ;
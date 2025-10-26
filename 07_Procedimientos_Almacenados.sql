
-- PROCEDIMIENTOS ALMACENADOS PARA MI TIENDA


USE `proyecto_ecommerce`;

-- 1. sp_RealizarNuevaVenta
-- Este procedimiento procesa una nueva venta

DELIMITER $$
CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_id_cliente INT,
    IN p_id_sucursal INT,
    IN p_productos JSON,
    OUT p_id_venta INT,
    OUT p_total_venta DECIMAL(10,2),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_cantidad_productos INT;
    DECLARE v_id_producto INT;
    DECLARE v_cantidad INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_iva DECIMAL(5,2);
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_total_linea DECIMAL(10,2);
    DECLARE v_stock_disponible DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al procesar la venta';
        SET p_id_venta = 0;
        SET p_total_venta = 0;
    END;
    
    START TRANSACTION;
    
    -- Primero verifico que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = p_id_cliente) THEN
        SET p_mensaje = 'Cliente no encontrado';
        SET v_error = TRUE;
    END IF;
    
    -- Tambien verifico que la sucursal existe
    IF NOT EXISTS (SELECT 1 FROM sucursales WHERE id_sucursal = p_id_sucursal) THEN
        SET p_mensaje = 'Sucursal no encontrada';
        SET v_error = TRUE;
    END IF;
    
    -- Obtener cantidad de productos
    SET v_cantidad_productos = JSON_LENGTH(p_productos);
    
    -- Validar stock para cada producto
    WHILE v_contador < v_cantidad_productos AND NOT v_error DO
        SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad')));
        
        -- Verificar stock disponible
        SELECT stock INTO v_stock_disponible
        FROM productos
        WHERE id_producto = v_id_producto AND activo = 1;
        
        IF v_stock_disponible < v_cantidad THEN
            SET p_mensaje = CONCAT('Stock insuficiente para producto ID: ', v_id_producto);
            SET v_error = TRUE;
        END IF;
        
        SET v_contador = v_contador + 1;
    END WHILE;
    
    IF NOT v_error THEN
        -- Crear la venta
        INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
        VALUES (NOW(), 'Pendiente de Pago', 0, p_id_cliente, p_id_sucursal);
        
        SET p_id_venta = LAST_INSERT_ID();
        
        -- Procesar cada producto
        SET v_contador = 0;
        WHILE v_contador < v_cantidad_productos DO
            SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].id_producto')));
            SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad')));
            
            -- Obtener precio e IVA del producto
            SELECT precio, iva INTO v_precio, v_iva
            FROM productos
            WHERE id_producto = v_id_producto;
            
            -- Calcular subtotal y total de linea
            SET v_subtotal = v_cantidad * v_precio;
            SET v_total_linea = v_subtotal + (v_subtotal * (v_iva / 100));
            
            -- Insertar detalle de venta
            INSERT INTO detalle_ventas (
                id_venta_fk, id_producto_fk, cantidad, 
                precio_unitario_congelado, iva_porcentaje_aplicado, 
                subtotal, total_linea
            ) VALUES (
                p_id_venta, v_id_producto, v_cantidad,
                v_precio, v_iva, v_subtotal, v_total_linea
            );
            
            -- Actualizar stock
            UPDATE productos
            SET stock = stock - v_cantidad
            WHERE id_producto = v_id_producto;
            
            SET v_total = v_total + v_total_linea;
            SET v_contador = v_contador + 1;
        END WHILE;
        
        -- Actualizar total de la venta
        UPDATE ventas
        SET total = v_total
        WHERE id_venta = p_id_venta;
        
        SET p_total_venta = v_total;
        SET p_mensaje = 'Venta procesada exitosamente';
        
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$
DELIMITER ;

-- 2. sp_AgregarNuevoProducto

DELIMITER $$
CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_nombre VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_precio DECIMAL(10,2),
    IN p_iva DECIMAL(6,2),
    IN p_costo DECIMAL(10,2),
    IN p_stock DECIMAL(10,2),
    IN p_stock_minimo DECIMAL(10,2),
    IN p_sku VARCHAR(50),
    IN p_peso DECIMAL(5,3),
    IN p_id_proveedor INT,
    IN p_id_categoria INT,
    OUT p_id_producto INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al agregar el producto';
        SET p_id_producto = 0;
    END;
    
    START TRANSACTION;
    
    -- Validar que el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id_proveedor = p_id_proveedor) THEN
        SET p_mensaje = 'Proveedor no encontrado';
        SET v_error = TRUE;
    END IF;
    
    -- Validar que la categoria existe
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        SET p_mensaje = 'Categoria no encontrada';
        SET v_error = TRUE;
    END IF;
    
    -- Validar que el SKU no existe
    IF EXISTS (SELECT 1 FROM productos WHERE sku = p_sku) THEN
        SET p_mensaje = 'El SKU ya existe';
        SET v_error = TRUE;
    END IF;
    
    -- Validar que el nombre no existe
    IF EXISTS (SELECT 1 FROM productos WHERE nombre = p_nombre) THEN
        SET p_mensaje = 'El nombre del producto ya existe';
        SET v_error = TRUE;
    END IF;
    
    -- Validar precios
    IF p_precio <= p_costo THEN
        SET p_mensaje = 'El precio debe ser mayor que el costo';
        SET v_error = TRUE;
    END IF;
    
    IF NOT v_error THEN
        -- Insertar el producto
        INSERT INTO productos (
            nombre, descripcion, precio, iva, costo, stock, stock_minimo,
            sku, fecha_creacion, activo, peso, id_proveedor_fk, id_categoria_fk
        ) VALUES (
            p_nombre, p_descripcion, p_precio, p_iva, p_costo, p_stock, p_stock_minimo,
            p_sku, NOW(), 1, p_peso, p_id_proveedor, p_id_categoria
        );
        
        SET p_id_producto = LAST_INSERT_ID();
        SET p_mensaje = 'Producto agregado exitosamente';
        
        -- Registrar en log
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (USER(), 'ADD_PRODUCT', CONCAT('Producto agregado: ', p_nombre, ' (ID: ', p_id_producto, ')'), 1);
        
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$
DELIMITER ;

-- 3. sp_ActualizarDireccionCliente

DELIMITER $$
CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente INT,
    IN p_id_barrio INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al actualizar la direccion';
    END;
    
    START TRANSACTION;
    
    -- Validar que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = p_id_cliente) THEN
        SET p_mensaje = 'Cliente no encontrado';
        SET v_error = TRUE;
    END IF;
    
    -- Validar que el barrio existe
    IF NOT EXISTS (SELECT 1 FROM barrios WHERE id_barrio = p_id_barrio) THEN
        SET p_mensaje = 'Barrio no encontrado';
        SET v_error = TRUE;
    END IF;
    
    IF NOT v_error THEN
        -- Actualizar direccion del cliente
        UPDATE clientes
        SET id_barrio_fk = p_id_barrio
        WHERE id_cliente = p_id_cliente;
        
        SET p_mensaje = 'Direccion actualizada exitosamente';
        
        -- Registrar en log
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (USER(), 'UPDATE_ADDRESS', CONCAT('Direccion actualizada para cliente ID: ', p_id_cliente), 1);
        
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$
DELIMITER ;

-- 4. sp_ProcesarDevolucion

DELIMITER $$
CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad INT,
    IN p_motivo VARCHAR(255),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE v_cantidad_original INT;
    DECLARE v_precio_unitario DECIMAL(10,2);
    DECLARE v_total_devolucion DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al procesar la devolucion';
    END;
    
    START TRANSACTION;
    
    -- Validar que la venta existe y esta entregada
    IF NOT EXISTS (SELECT 1 FROM ventas WHERE id_venta = p_id_venta AND estado = 'Entregado') THEN
        SET p_mensaje = 'La venta no existe o no esta entregada';
        SET v_error = TRUE;
    END IF;
    
    -- Validar que el producto esta en la venta
    IF NOT EXISTS (SELECT 1 FROM detalle_ventas WHERE id_venta_fk = p_id_venta AND id_producto_fk = p_id_producto) THEN
        SET p_mensaje = 'El producto no esta en esta venta';
        SET v_error = TRUE;
    END IF;
    
    -- Obtener cantidad original y precio
    SELECT cantidad, precio_unitario_congelado INTO v_cantidad_original, v_precio_unitario
    FROM detalle_ventas
    WHERE id_venta_fk = p_id_venta AND id_producto_fk = p_id_producto;
    
    -- Validar cantidad a devolver
    IF p_cantidad > v_cantidad_original THEN
        SET p_mensaje = 'La cantidad a devolver excede la cantidad comprada';
        SET v_error = TRUE;
    END IF;
    
    IF NOT v_error THEN
        -- Calcular total de devolucion
        SET v_total_devolucion = p_cantidad * v_precio_unitario;
        
        -- Actualizar stock del producto
        UPDATE productos
        SET stock = stock + p_cantidad
        WHERE id_producto = p_id_producto;
        
        -- Actualizar cantidad en detalle de venta
        UPDATE detalle_ventas
        SET cantidad = cantidad - p_cantidad,
            subtotal = (cantidad - p_cantidad) * precio_unitario_congelado,
            total_linea = subtotal + (subtotal * (iva_porcentaje_aplicado / 100))
        WHERE id_venta_fk = p_id_venta AND id_producto_fk = p_id_producto;
        
        -- Actualizar total de la venta
        UPDATE ventas
        SET total = total - v_total_devolucion
        WHERE id_venta = p_id_venta;
        
        -- Registrar devolucion en log
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (USER(), 'PROCESS_RETURN', CONCAT('Devolucion procesada - Venta: ', p_id_venta, ', Producto: ', p_id_producto, ', Cantidad: ', p_cantidad, ', Motivo: ', p_motivo), 1);
        
        SET p_mensaje = 'Devolucion procesada exitosamente';
        
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$
DELIMITER ;

-- 5. sp_ObtenerHistorialComprasCliente

DELIMITER $$
CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(
    IN p_id_cliente INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_limite INT
)
BEGIN
    SELECT 
        v.id_venta,
        v.fecha_venta,
        v.estado,
        v.total,
        s.nombre as sucursal,
        COUNT(dv.id_producto_fk) as productos_comprados,
        GROUP_CONCAT(
            CONCAT(p.nombre, ' (', dv.cantidad, ' unidades)')
            SEPARATOR ', '
        ) as productos
    FROM ventas v
    INNER JOIN sucursales s ON v.id_sucursal_fk = s.id_sucursal
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta_fk
    INNER JOIN productos p ON dv.id_producto_fk = p.id_producto
    WHERE v.id_cliente_fk = p_id_cliente
    AND (p_fecha_inicio IS NULL OR v.fecha_venta >= p_fecha_inicio)
    AND (p_fecha_fin IS NULL OR v.fecha_venta <= p_fecha_fin)
    GROUP BY v.id_venta, v.fecha_venta, v.estado, v.total, s.nombre
    ORDER BY v.fecha_venta DESC
    LIMIT IFNULL(p_limite, 50);
END$$
DELIMITER ;

-- 6. sp_AjustarNivelStock

DELIMITER $$
CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_cantidad_ajuste DECIMAL(10,2),
    IN p_tipo_ajuste ENUM('INCREMENTO', 'DECREMENTO', 'AJUSTE_DIRECTO'),
    IN p_motivo VARCHAR(255),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE v_stock_actual DECIMAL(10,2);
    DECLARE v_nuevo_stock DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al ajustar el stock';
    END;
    
    START TRANSACTION;
    
    -- Validar que el producto existe
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SET p_mensaje = 'Producto no encontrado';
        SET v_error = TRUE;
    END IF;
    
    -- Validar cantidad de ajuste
    IF p_cantidad_ajuste <= 0 THEN
        SET p_mensaje = 'La cantidad de ajuste debe ser mayor que 0';
        SET v_error = TRUE;
    END IF;
    
    IF NOT v_error THEN
        -- Obtener stock actual
        SELECT stock INTO v_stock_actual
        FROM productos
        WHERE id_producto = p_id_producto;
        
        -- Calcular nuevo stock segun tipo de ajuste
        CASE p_tipo_ajuste
            WHEN 'INCREMENTO' THEN
                SET v_nuevo_stock = v_stock_actual + p_cantidad_ajuste;
            WHEN 'DECREMENTO' THEN
                SET v_nuevo_stock = v_stock_actual - p_cantidad_ajuste;
                IF v_nuevo_stock < 0 THEN
                    SET p_mensaje = 'No se puede reducir el stock por debajo de 0';
                    SET v_error = TRUE;
                END IF;
            WHEN 'AJUSTE_DIRECTO' THEN
                SET v_nuevo_stock = p_cantidad_ajuste;
        END CASE;
        
        IF NOT v_error THEN
            -- Actualizar stock
            UPDATE productos
            SET stock = v_nuevo_stock
            WHERE id_producto = p_id_producto;
            
            -- Registrar ajuste en log
            INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
            VALUES (USER(), 'STOCK_ADJUSTMENT', CONCAT('Stock ajustado - Producto: ', p_id_producto, ', Tipo: ', p_tipo_ajuste, ', Cantidad: ', p_cantidad_ajuste, ', Motivo: ', p_motivo), 1);
            
            SET p_mensaje = CONCAT('Stock ajustado exitosamente. Nuevo stock: ', v_nuevo_stock);
            
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;
    ELSE
        ROLLBACK;
    END IF;
END$$
DELIMITER ;
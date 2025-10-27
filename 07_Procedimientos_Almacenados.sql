

















































































































































































































































































































































































































































































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
    -- sp_RealizarNuevaVenta: Procesa una nueva venta de forma transaccional.
    -- sp_AgregarNuevoProducto: Inserta un nuevo producto y sus atributos iniciales.
    -- sp_ActualizarDireccionCliente: Actualiza la dirección de un cliente en todas las tablas relevantes.
    -- sp_ProcesarDevolucion: Gestiona la devolución de un producto, ajustando el stock y generando un crédito.
    -- sp_ObtenerHistorialComprasCliente: Devuelve el historial completo de compras de un cliente.
    -- sp_AjustarNivelStock: Permite ajustar manualmente el stock de un producto, registrando el motivo.
-- sp_EliminarClienteDeFormaSegura: Anonimiza los datos de un cliente en lugar de borrarlos, para mantener la integridad referencial.
DELIMITER //

CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(
    IN p_id_cliente INT,
    IN p_usuario VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error eliminando cliente';
    END;

    START TRANSACTION;


    INSERT INTO auditoria_clientes (id_auditoria, accion, fecha_evento, usuario, id_cliente_fk, id_usuario_fk)
    SELECT IFNULL(MAX(id_auditoria),0)+1, 'DELETE', NOW(), p_usuario, id_cliente, 1
    FROM clientes
    WHERE id_cliente = p_id_cliente;


    DELETE FROM reseñas WHERE id_cliente_fk = p_id_cliente;


    DELETE pc FROM productos_carritos pc
    JOIN carritos c ON pc.id_carritos_fk = c.id_carritos
    WHERE c.id_cliente_fk = p_id_cliente;


    DELETE FROM carritos WHERE id_cliente_fk = p_id_cliente;

    UPDATE ventas SET estado = 'Cancelado' WHERE id_cliente_fk = p_id_cliente;


    DELETE FROM clientes WHERE id_cliente = p_id_cliente;

    COMMIT;
END //

DELIMITER ;

-- sp_AplicarDescuentoPorCategoria: Aplica un descuento a todos los productos de una categoría específica.
DELIMITER //

CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria INT,
    IN p_descuento_porcentaje DECIMAL(5,2),
    IN p_usuario VARCHAR(100)
)
BEGIN

    DECLARE done INT DEFAULT 0;
    DECLARE v_id_producto INT;
    DECLARE v_precio_actual DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT id_producto, precio FROM productos WHERE id_categoria_fk = p_id_categoria;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error aplicando descuento';
    END;

    START TRANSACTION;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_id_producto, v_precio_actual;
        IF done THEN
            LEAVE read_loop;
        END IF;


        INSERT INTO auditoria_precios(precio_anterior, precio_nuevo, fecha_cambio, usuario, id_producto_fk)
        VALUES (
            v_precio_actual,
            v_precio_actual * (1 - p_descuento_porcentaje / 100),
            NOW(),
            p_usuario,
            v_id_producto
        );


        UPDATE productos
        SET precio = v_precio_actual * (1 - p_descuento_porcentaje / 100)
        WHERE id_producto = v_id_producto;

    END LOOP;

    CLOSE cur;

    COMMIT;
END //

DELIMITER ;

-- sp_GenerarReporteMensualVentas: Genera un reporte completo de ventas para un mes y año dados.
DELIMITER //

CREATE PROCEDURE sp_GenerarReporteMensualVentasx(
    IN p_anyo INT,
    IN p_mes INT
)
BEGIN
    DECLARE v_anyo INT;
    DECLARE v_mes INT;

    IF p_anyo IS NULL OR p_mes IS NULL THEN
        SET v_anyo = YEAR(CURRENT_DATE);
        SET v_mes = MONTH(CURRENT_DATE);
    ELSE
        SET v_anyo = p_anyo;
        SET v_mes = p_mes;
    END IF;

    SELECT 
        CONCAT(v_anyo, '-', LPAD(v_mes, 2, '0')) AS mes,
        COUNT(v.id_venta) AS total_ventas,
        IFNULL(SUM(v.total), 0) AS total_vendido,
        IFNULL(ROUND(AVG(v.total),2),0) AS promedio_venta,
        COUNT(DISTINCT v.id_cliente_fk) AS clientes_unicos
    FROM (SELECT * FROM ventas) v
    WHERE YEAR(v.fecha_venta) = v_anyo
      AND MONTH(v.fecha_venta) = v_mes;
END //

DELIMITER ;



CALL sp_GenerarReporteMensualVentas(2025, 1);


-- sp_CambiarEstadoPedido: Cambia el estado de un pedido (ej. 'Procesando' a 'Enviado') y notifica a otros sistemas.
DELIMITER //

CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_id_venta INT,
    IN p_nuevo_estado ENUM('Pendiente de Pago','Procesando','Enviado','Entregado','Cancelado')
)
BEGIN

    IF EXISTS (SELECT 1 FROM ventas WHERE id_venta = p_id_venta) THEN
        UPDATE ventas
        SET estado = p_nuevo_estado
        WHERE id_venta = p_id_venta;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no existe';
    END IF;
END //

DELIMITER ;

CALL sp_CambiarEstadoPedido(3, 'Entregado');

-- sp_RegistrarNuevoCliente: Registra un nuevo cliente validando que el email no exista.
DELIMITER //

CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(45),
    IN p_apellido VARCHAR(45),
    IN p_email VARCHAR(45),
    IN p_telefono VARCHAR(15),
    IN p_contrasena VARCHAR(45),
    IN p_fecha_nacimiento DATE,
    IN p_id_barrio_fk INT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count 
    FROM clientes
    WHERE email = p_email;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'El email ya está registrado';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM barrios
    WHERE id_barrio = p_id_barrio_fk;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El barrio seleccionado no existe';
    END IF;

    INSERT INTO clientes (
        nombre, apellido, email, telefono_contacto, contrasena, fecha_nacimiento, id_barrio_fk, fecha_registro
    ) VALUES (
        p_nombre, p_apellido, p_email, p_telefono, p_contrasena, p_fecha_nacimiento, p_id_barrio_fk, NOW()
    );
END //

DELIMITER ;

CALL sp_RegistrarNuevoCliente(
    'Steven', 
    'Blanco', 
    'steven@example.com', 
    '3151234567', 
    'miContrasena123', 
    '1995-05-20', 
    1
);

-- sp_ObtenerDetallesProductoCompleto: Devuelve toda la información de un producto, incluyendo datos de su proveedor y categoría.
DELIMITER //

CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(
    IN p_id_producto INT
)
BEGIN
    SELECT 
        p.id_producto,
        p.nombre AS producto_nombre,
        p.descripcion AS producto_descripcion,
        p.precio,
        p.iva,
        p.costo,
        p.stock,
        p.stock_minimo,
        p.sku,
        p.fecha_creacion,
        p.activo,
        p.visto,
        p.peso,
        c.id_categoria,
        c.nombre AS categoria_nombre,
        c.descripcion AS categoria_descripcion,
        pr.id_proveedor,
        pr.nombre AS proveedor_nombre,
        pr.email_contacto,
        pr.telefono_contacto,
        (SELECT COUNT(*) FROM alertas_stock a WHERE a.id_producto_fk = p.id_producto AND a.estado = 'Pendiente') AS alertas_pendientes,
        (SELECT GROUP_CONCAT(DISTINCT promo.nombre) 
         FROM promociones_producto pp 
         JOIN promociones promo ON pp.id_promocion_fk = promo.id_promocion
         WHERE pp.id_producto_fk = p.id_producto AND promo.activa = 1) AS promociones_activas
    FROM productos p
    JOIN categorias c ON p.id_categoria_fk = c.id_categoria
    JOIN proveedores pr ON p.id_proveedor_fk = pr.id_proveedor
    WHERE p.id_producto = p_id_producto;
END //

DELIMITER ;

CALL sp_ObtenerDetallesProductoCompleto(1);

-- sp_FusionarCuentasCliente: Fusiona dos cuentas de cliente duplicadas en una sola.
DELIMITER //

CREATE PROCEDURE sp_FusionarCuentasCliente(
    IN p_id_cliente_principal INT,
    IN p_id_cliente_secundario INT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count FROM clientes WHERE id_cliente = p_id_cliente_principal;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente principal no existe';
    END IF;

    SELECT COUNT(*) INTO v_count FROM clientes WHERE id_cliente = p_id_cliente_secundario;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente secundario no existe';
    END IF;

    START TRANSACTION;

    UPDATE ventas
    SET id_cliente_fk = p_id_cliente_principal
    WHERE id_cliente_fk = p_id_cliente_secundario;


    UPDATE carritos
    SET id_cliente_fk = p_id_cliente_principal
    WHERE id_cliente_fk = p_id_cliente_secundario;


    UPDATE reseñas
    SET id_cliente_fk = p_id_cliente_principal
    WHERE id_cliente_fk = p_id_cliente_secundario;

    UPDATE auditoria_clientes
    SET id_cliente_fk = p_id_cliente_principal
    WHERE id_cliente_fk = p_id_cliente_secundario;


    UPDATE envios
    SET id_venta_fk = (SELECT id_venta FROM ventas WHERE id_cliente_fk = p_id_cliente_principal AND id_venta = envios.id_venta_fk)
    WHERE id_venta_fk IN (SELECT id_venta FROM ventas WHERE id_cliente_fk = p_id_cliente_secundario);


    UPDATE clientes
    SET total_gastado = total_gastado + (SELECT IFNULL(SUM(total),0) FROM ventas WHERE id_cliente_fk = p_id_cliente_secundario)
    WHERE id_cliente = p_id_cliente_principal;


    DELETE FROM clientes
    WHERE id_cliente = p_id_cliente_secundario;

    COMMIT;
END //

DELIMITER ;

CALL sp_FusionarCuentasCliente(1, 2);

-- sp_AsignarProductoAProveedor: Asigna o cambia el proveedor de un producto.
DELIMITER $$

CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_id_producto INT,
    IN p_id_proveedor INT
)
BEGIN

    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id_proveedor = p_id_proveedor) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El proveedor no existe.';
    END IF;

    UPDATE productos
    SET id_proveedor_fk = p_id_proveedor
    WHERE id_producto = p_id_producto;
END$$

DELIMITER ;

CALL sp_AsignarProductoAProveedor(1, 2);

SELECT id_producto, nombre, id_proveedor_fk FROM productos WHERE id_producto = 1;

-- sp_BuscarProductos: Realiza una búsqueda avanzada de productos con filtros por nombre, categoría, rango de precios, etc.
DELIMITER $$

CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre VARCHAR(50),
    IN p_id_categoria INT,
    IN p_precio_min DECIMAL(10,2),
    IN p_precio_max DECIMAL(10,2)
)
BEGIN
    SELECT *
    FROM productos
    WHERE (p_nombre IS NULL OR nombre LIKE CONCAT('%', p_nombre, '%'))
      AND (p_id_categoria IS NULL OR id_categoria_fk = p_id_categoria)
      AND (p_precio_min IS NULL OR precio >= p_precio_min)
      AND (p_precio_max IS NULL OR precio <= p_precio_max);
END$$

DELIMITER ;
-- Buscar todos los productos de la categoría 1 cuyo nombre contenga 'Camiseta' y precio entre 50000 y 100000
CALL sp_BuscarProductos('Camiseta', 1, 50000, 100000);

-- Buscar nombre 'Zapato', sin filtrar categoría ni precio
CALL sp_BuscarProductos('Zapato', NULL, NULL, NULL);

-- Buscar por la categoría 2
CALL sp_BuscarProductos(NULL, 2, NULL, NULL);


-- sp_ObtenerDashboardAdmin: Devuelve un conjunto de KPIs para un panel de administración (ventas de hoy, nuevos clientes, etc.).
DELIMITER $$

CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    -- Ventas del día
    SELECT 
        COUNT(*) AS total_pedidos_hoy,
        SUM(total) AS total_ventas_hoy
    FROM ventas
    WHERE DATE(fecha_venta) = CURRENT_DATE;

    -- Nuevos clientes hoy
    SELECT COUNT(*) AS nuevos_clientes_hoy
    FROM clientes
    WHERE DATE(fecha_registro) = CURRENT_DATE;

    -- Ventas del mes
    SELECT 
        COUNT(*) AS total_pedidos_mes,
        SUM(total) AS total_ventas_mes
    FROM ventas
    WHERE YEAR(fecha_venta) = YEAR(CURRENT_DATE)
      AND MONTH(fecha_venta) = MONTH(CURRENT_DATE);

    -- Pedidos pendientes
    SELECT COUNT(*) AS pedidos_pendientes
    FROM ventas
    WHERE estado = 'PendientePago';

    -- Productos con bajo stock
    SELECT nombre, stock, stock_minimo
    FROM productos
    WHERE stock < stock_minimo
    ORDER BY stock ASC;
END$$

DELIMITER ;

CALL sp_ObtenerDashboardAdmin();

-- sp_ProcesarPago: Simula el procesamiento de un pago para una venta, actualizando su estado a "Pagado".

DELIMITER $$

CREATE PROCEDURE sp_ProcesarPago(IN p_id_venta INT)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    DECLARE v_mensaje_error VARCHAR(200);

    -- Obtener el estado actual de la venta
    SELECT estado INTO v_estado_actual
    FROM ventas
    WHERE id_venta = p_id_venta;

    -- Verificar si la venta existe y está pendiente
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Venta no encontrada.';
    ELSEIF v_estado_actual = 'PendientePago' THEN
        -- Actualizar estado a Procesando (o Pagado según tu flujo)
        UPDATE ventas
        SET estado = 'Procesando'
        WHERE id_venta = p_id_venta;
    ELSE
        SET v_mensaje_error = CONCAT('La venta no puede procesarse. Estado actual: ', v_estado_actual);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_mensaje_error;
    END IF;
END$$

DELIMITER ;

CALL sp_ProcesarPago(6);

-- sp_AñadirReseñaProducto: Permite a un cliente añadir una reseña y calificación a un producto que ha comprado.
DELIMITER $$

CREATE PROCEDURE sp_AñadirReseñaProducto (
    IN p_id_producto INT,
    IN p_id_cliente INT,
    IN p_calificacion INT,
    IN p_comentario VARCHAR(500)
)
BEGIN
    -- Verificar que el cliente haya comprado el producto y que la venta esté entregada
    IF EXISTS (
        SELECT 1 
        FROM detalle_ventas dv
        JOIN ventas v ON dv.id_venta_fk = v.id_venta
        WHERE dv.id_producto_fk = p_id_producto
          AND v.id_cliente_fk = p_id_cliente
          AND v.estado = 'Entregado'
    ) THEN
        -- Insertar la reseña
        INSERT INTO reseñas (id_producto_fk, id_cliente_fk, calificacion, comentario)
        VALUES (p_id_producto, p_id_cliente, p_calificacion, p_comentario);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no ha comprado este producto o no ha sido entregado.';
    END IF;
END$$

DELIMITER ;
CALL sp_AñadirReseñaProducto(4, 11, 5, 'Excelente calidad y muy cómoda!');

-- sp_ObtenerProductosRelacionados: Devuelve una lista de productos relacionados a uno dado, basándose en compras de otros clientes.
DELIMITER $$

CREATE PROCEDURE sp_ObtenerProductosRelacionados (
    IN p_id_producto INT
)
BEGIN
    /*
    Devuelve productos que otros clientes han comprado junto con el producto dado.
    Ordena por la cantidad de veces que se compraron juntos (más frecuentes primero).
    */
    SELECT dv2.id_producto_fk AS id_producto_relacionado,
           p.nombre,
           COUNT(*) AS veces_comprado_junto
    FROM detalle_ventas dv1
    JOIN detalle_ventas dv2 
        ON dv1.id_venta_fk = dv2.id_venta_fk
       AND dv2.id_producto_fk <> dv1.id_producto_fk
    JOIN productos p ON dv2.id_producto_fk = p.id_producto
    WHERE dv1.id_producto_fk = p_id_producto
    GROUP BY dv2.id_producto_fk, p.nombre
    ORDER BY veces_comprado_junto DESC;
END$$

DELIMITER ;

CALL sp_ObtenerProductosRelacionados(1);

-- sp_MoverProductosEntreCategorias: Mueve uno o más productos de una categoría a otra de forma segura.
DELIMITER $$

CREATE PROCEDURE sp_MoverProductosEntreCategorias (
    IN p_id_categoria_origen INT,
    IN p_id_categoria_destino INT
)
BEGIN
    DECLARE v_count INT;

    -- Verificar que la categoría destino exista
    SELECT COUNT(*) INTO v_count
    FROM categorias
    WHERE id_categoria = p_id_categoria_destino;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La categoría destino no existe.';
    END IF;

    -- Actualizar productos que estén en la categoría origen
    UPDATE productos
    SET id_categoria_fk = p_id_categoria_destino
    WHERE id_categoria_fk = p_id_categoria_origen;

END$$

DELIMITER ;

CALL sp_MoverProductosEntreCategorias(1, 2);

-- Verificar cambios
SELECT nombre, id_categoria_fk FROM productos;


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

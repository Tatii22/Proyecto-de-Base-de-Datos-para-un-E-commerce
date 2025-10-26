    -- trg_audit_precio_producto_after_update: Guarda un log de cambios de precios.
    -- trg_check_stock_before_insert_venta: Verifica el stock antes de registrar una venta.
    -- trg_update_stock_after_insert_venta: Decrementa el stock después de una venta.
    -- trg_prevent_delete_categoria_with_products: Impide eliminar una categoría si tiene productos asociados.
    -- trg_log_new_customer_after_insert: Registra en una tabla de auditoría cada vez que se crea un nuevo cliente.
    -- trg_update_total_gastado_cliente: Actualiza un campo total_gastado en la tabla clientes después de cada compra.
    -- trg_set_fecha_modificacion_producto: Actualiza automáticamente la fecha de última modificación de un producto.

-- trg_prevent_negative_stock: Impide que el stock de un producto se actualice a un valor negativo.

DELIMITER $$

CREATE TRIGGER trg_prevent_negative_stock
BEFORE INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual DECIMAL(10,2);

    SELECT stock INTO v_stock_actual
    FROM productos
    WHERE id_producto = NEW.id_producto_fk;

    IF v_stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente: la operación dejaría inventario negativo.';
    ELSE
        UPDATE productos
        SET stock = stock - NEW.cantidad
        WHERE id_producto = NEW.id_producto_fk;
    END IF;
END$$

DELIMITER ;

INSERT INTO detalle_ventas (id_producto_fk, cantidad)
VALUES (1, 50);

-- trg_capitalize_nombre_cliente: Convierte a mayúscula la primera letra del nombre y apellido de un cliente al insertarlo.
DELIMITER $$

CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    SET NEW.nombre = CONCAT(UCASE(LEFT(NEW.nombre, 1)), LCASE(SUBSTRING(NEW.nombre, 2)));
    SET NEW.apellido = CONCAT(UCASE(LEFT(NEW.apellido, 1)), LCASE(SUBSTRING(NEW.apellido, 2)));
END$$

DELIMITER ;

INSERT INTO
    clientes (
        nombre,
        apellido,
        email,
        telefono_contacto,
        contrasena,
        fecha_registro,
        fecha_nacimiento,
        id_barrio_fk,
        total_gastado
    )
VALUES (
        'maria',
        'gomez',
        'maria.gomez@mail.com',
        '3005557777',
        'clave123',
        NOW(),
        '1998-04-15',
        2,
        0.00
    );
SELECT nombre, apellido 
FROM clientes 
WHERE email = 'maria.gomez@mail.com';

-- trg_recalculate_total_venta_on_detalle_change: Recalcula el total en la tabla ventas si se modifica un detalle_venta.
DELIMITER $$

CREATE TRIGGER trg_recalculate_total_venta_on_insert
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    UPDATE ventas
    SET total = (
        SELECT IFNULL(SUM(total_linea), 0)
        FROM detalle_ventas
        WHERE id_venta_fk = NEW.id_venta_fk
    )
    WHERE id_venta = NEW.id_venta_fk;
END$$

DELIMITER ;

INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES (NOW(), 'PendientePago', 0, 1, 1);

INSERT INTO detalle_ventas (id_venta_fk, id_producto_fk, cantidad, precio_unitario_congelado, iva_porcentaje_aplicado, subtotal, total_linea)
VALUES 
(1, 7, 2, 15000, 19, 30000, 35700),
(1, 8, 1, 20000, 19, 20000, 23800);

SELECT id_venta, total FROM ventas;


-- trg_log_order_status_change: Audita cada cambio de estado en un pedido (ej. de 'Procesando' a 'Enviado').
    CREATE TABLE IF NOT EXISTS historial_estado_pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
    IF NEW.estado <> OLD.estado THEN
        INSERT INTO historial_estado_pedidos (id_pedido, estado_anterior, estado_nuevo)
        VALUES (OLD.id_venta, OLD.estado, NEW.estado);
    END IF;
END$$

DELIMITER ;

INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES 
(NOW(), 'PendientePago', 50000, 1, 1),
(NOW(), 'Procesando', 120000, 2, 1);
UPDATE ventas
SET estado = 'Enviado'
WHERE id_venta = 1;

UPDATE ventas
SET estado = 'Entregado'
WHERE id_venta = 2;

SELECT * FROM historial_estado_pedidos;

-- trg_prevent_price_zero_or_less: Impide que el precio de un producto se establezca en cero o un valor negativo.
DELIMITER $$

CREATE TRIGGER trg_prevent_price_zero_or_less_insert
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor a cero.';
    END IF;
END$$

CREATE TRIGGER trg_prevent_price_zero_or_less_update
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor a cero.';
    END IF;
END$$

DELIMITER ;

INSERT INTO productos (
  nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku, 
  fecha_creacion, activo, visto, peso, id_proveedor_fk, id_categoria_fk
) VALUES (
  'Camiseta Básica', 'Camiseta sin mangas', 0, 19, 25000, 15, 3, 
  'SKU-CAMI-001', NOW(), 1, 0, 0.300, 1, 1
);

UPDATE productos
SET precio = -5000
WHERE nombre = 'Balón Profesional';

-- trg_send_stock_alert_on_low_stock: Inserta un registro en una tabla alertas si el stock baja de un umbral.

DELIMITER $$

CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock_minimo IS NOT NULL AND NEW.stock < NEW.stock_minimo THEN
        INSERT INTO alertas_stock (id_producto_fk, mensaje, estado)
        VALUES (
            NEW.id_producto,
            CONCAT('Stock bajo para el producto "', NEW.nombre,
                   '". Stock actual: ', NEW.stock,
                   ', Stock mínimo: ', NEW.stock_minimo),
            'Pendiente'
        );
    END IF;
END$$

DELIMITER ;
INSERT INTO productos (
    nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku,
    fecha_creacion, activo, visto, peso, id_proveedor_fk, id_categoria_fk
)
VALUES (
    'Camiseta Oversize Negra', 'Camiseta de algodón estilo urbano unisex',
    60000, 19, 25000, 12, 8, 'SKU-CAMI01',
    NOW(), 1, 0, 0.300, 1, 1
);

UPDATE productos
SET stock = 7
WHERE nombre = 'Camiseta Oversize Negra';
SELECT * FROM alertas_stock;

-- trg_archive_deleted_venta: Mueve una venta eliminada a una tabla de archivo en lugar de borrarla permanentemente.
DELIMITER $$

CREATE TRIGGER trg_backup_critical_tables_daily
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO clientes_backup (id_cliente, nombre, apellido, email, telefono_contacto )
    VALUES (OLD.id_cliente, OLD.nombre, OLD.apellido, OLD.email, OLD.telefono_contacto);
END$$

DELIMITER ;

-- trg_validate_email_format_on_customer: Valida el formato del email antes de insertar o actualizar un cliente.
DELIMITER $$

CREATE TRIGGER trg_validate_email_format_on_customer_insert
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Formato de email inválido';
    END IF;
END
CREATE TRIGGER trg_validate_email_format_on_customer_update
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Formato de email inválido';
    END IF;
END$$
DELIMITER ;
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, fecha_nacimiento, id_barrio_fk, total_gastado)
VALUES ('Claudia', 'Villamizar', 'claudia@mail.com', '3001234567', 'Pass123', NOW(), '1995-05-10', 1, 100.00);
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, fecha_nacimiento, id_barrio_fk, total_gastado)
VALUES ('Tati', 'Ruiz', 'tati#mail.com', '3009876543', 'Tati123', NOW(), '1996-07-12', 1, 50.00);
UPDATE clientes
SET email = 'invalidemail.com'
WHERE id_cliente = 1;
-- trg_update_last_order_date_customer: Actualiza la fecha del último pedido en la tabla clientes.
ALTER TABLE clientes
ADD COLUMN fecha_ultimo_pedido DATETIME;

DELIMITER $$

CREATE TRIGGER trg_update_last_order_date_customer
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET fecha_ultimo_pedido = NEW.fecha_venta
    WHERE id_cliente = NEW.id_cliente_fk;
END$$

DELIMITER ;

INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES (NOW(), 'PendientePago', 150.00, 1, 1);

SELECT id_cliente, nombre, fecha_ultimo_pedido
FROM clientes
WHERE id_cliente = 1;
-- trg_prevent_self_referral: Impide que un cliente se referencie a sí mismo en un programa de referidos.
CREATE TABLE referidos (
    id_referido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente_fk INT NOT NULL,
    id_referente_fk INT NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_referente_fk) REFERENCES clientes(id_cliente)
);
DELIMITER $$

CREATE TRIGGER trg_prevent_self_referral
BEFORE INSERT ON referidos
FOR EACH ROW
BEGIN
    IF NEW.id_cliente_fk = NEW.id_referente_fk THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un cliente no puede referirse a sí mismo.';
    END IF;
END$$

DELIMITER ;

INSERT INTO referidos (id_cliente_fk, id_referente_fk) VALUES (2, 1);
INSERT INTO referidos (id_cliente_fk, id_referente_fk) VALUES (3, 3); -- falla y lanza error

-- trg_log_permission_changes: Audita los cambios en los permisos de los usuarios.
DELIMITER $$

CREATE TRIGGER trg_log_permission_changes
AFTER UPDATE ON usuarios_bd
FOR EACH ROW
BEGIN
    -- Solo registrar si cambió el rol
    IF OLD.rol <> NEW.rol THEN
        INSERT INTO permisos_log (usuario, accion, descripcion, id_usuario_fk)
        VALUES (
            OLD.nombre_usuario,
            'Cambio de rol',
            CONCAT('El rol cambió de ', OLD.rol, ' a ', NEW.rol),
            OLD.id_usuario
        );
    END IF;
END$$

DELIMITER ;

INSERT INTO usuarios_bd (nombre_usuario, rol, activo)
VALUES ('tatiana', 'Empleado_Inventario', 1);
UPDATE usuarios_bd
SET rol = 'Analista_Datos'
WHERE nombre_usuario = 'tatiana';
SELECT * FROM permisos_log;

-- trg_assign_default_category_on_null: Asigna una categoría "General" si se inserta un producto sin categoría.
INSERT IGNORE INTO categorias (nombre)
VALUES ('General');

DELIMITER $$

CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    IF NEW.id_categoria_fk IS NULL THEN
        -- Asignar el id de la categoría "General"
        SET NEW.id_categoria_fk = (SELECT id_categoria FROM categorias WHERE nombre = 'General' LIMIT 1);
    END IF;
END$$

DELIMITER ;


INSERT INTO productos (nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku, fecha_creacion, activo, visto, peso, id_proveedor_fk)
VALUES ('Camisa Básica Blanca', 'Camisa de algodón unisex', 45000, 19, 20000, 20, 5, 'SKU-CAMI02', NOW(), 1, 0, 0.250, 1);


SELECT nombre, id_categoria_fk FROM productos WHERE nombre = 'Camisa Básica Blanca';


-- trg_update_producto_count_in_categoria: Mantiene un contador de cuántos productos hay en cada categoría.

ALTER TABLE categorias
ADD COLUMN cantidad_productos INT DEFAULT 0;

DELIMITER $$

CREATE TRIGGER trg_increment_producto_count
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
    UPDATE categorias
    SET cantidad_productos = cantidad_productos + 1
    WHERE id_categoria = NEW.id_categoria_fk;
END
CREATE TRIGGER trg_decrement_producto_count
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
    UPDATE categorias
    SET cantidad_productos = cantidad_productos - 1
    WHERE id_categoria = OLD.id_categoria_fk;
END

CREATE TRIGGER trg_update_producto_count_on_update
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF OLD.id_categoria_fk <> NEW.id_categoria_fk THEN
        -- Decrementar la categoría anterior
        UPDATE categorias
        SET cantidad_productos = cantidad_productos - 1
        WHERE id_categoria = OLD.id_categoria_fk;

        -- Incrementar la nueva categoría
        UPDATE categorias
        SET cantidad_productos = cantidad_productos + 1
        WHERE id_categoria = NEW.id_categoria_fk;
    END IF;
END$$

DELIMITER ;

INSERT INTO productos (nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku, fecha_creacion, activo, visto, peso, id_proveedor_fk, id_categoria_fk)
VALUES ('Pantalón Jeans Azul', 'Pantalón de mezclilla unisex', 80000, 19, 50000, 15, 5, 'SKU-PANT01', NOW(), 1, 0, 0.400, 1, 1);

SELECT nombre, cantidad_productos FROM categorias;


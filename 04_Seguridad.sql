    -- Crear el rol Administrador_Sistema con todos los privilegios.
    -- Crear el rol Gerente_Marketing con acceso de solo lectura a ventas y clientes.
    -- Crear el rol Analista_Datos con acceso de solo lectura a todas las tablas, excepto a las de auditoría.
    -- Crear el rol Empleado_Inventario que solo pueda modificar la tabla productos (stock y ubicación).
    -- Crear el rol Atencion_Cliente que pueda ver clientes y ventas, pero no modificar precios.
    -- Crear el rol Auditor_Financiero con acceso de solo lectura a ventas, productos y logs de precios.
    -- Crear un usuario admin_user y asignarle el rol de administrador.
-- Crear un usuario marketing_user y asignarle el rol de marketing.
GRANT CREATE ROLE ON *.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

CREATE ROLE marketing;
CREATE USER 'marketing_user'@'%' IDENTIFIED BY 'PasswordMarketing2025!';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'marketing_user'@'%';
GRANT SELECT ON proyecto_ecommerce.productos TO 'marketing_user'@'%';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'marketing_user'@'%';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'marketing_user'@'%';
FLUSH PRIVILEGES;

-- Crear un usuario inventory_user y asignarle el rol de inventario.
CREATE ROLE 'inventario';
FLUSH PRIVILEGES;
GRANT SELECT ON proyecto_ecommerce.proveedores TO 'inventario';
GRANT SELECT, UPDATE (stock), SELECT (id_producto, nombre, precio, id_categoria_fk)
ON proyecto_ecommerce.productos
TO 'inventario';

CREATE USER 'inventory_user'@'%' IDENTIFIED BY 'Inventory2025!';
GRANT 'inventario' TO 'inventory_user'@'%';
FLUSH PRIVILEGES;

-- Crear un usuario support_user y asignarle el rol de atención al cliente.
CREATE ROLE 'atencion_cliente';

GRANT SELECT (id_cliente, nombre, apellido, email, fecha_registro)
ON proyecto_ecommerce.clientes
TO 'atencion_cliente';

GRANT SELECT (id_carritos, fecha_creacion, estado, id_cliente_fk)
ON proyecto_ecommerce.carritos
TO 'atencion_cliente';

GRANT SELECT ON proyecto_ecommerce.productos_carritos TO 'atencion_cliente';

GRANT SELECT (id_venta, total, id_cliente_fk)
ON proyecto_ecommerce.ventas
TO 'atencion_cliente';

CREATE USER 'support_user'@'%' IDENTIFIED BY 'Support2025!';
GRANT 'atencion_cliente' TO 'support_user'@'%';

SET DEFAULT ROLE 'atencion_cliente' TO 'support_user'@'%';
FLUSH PRIVILEGES;

-- Impedir que el rol Analista_Datos pueda ejecutar comandos DELETE o TRUNCATE.
CREATE ROLE IF NOT EXISTS 'Analista_Datos';
GRANT SELECT ON proyecto_ecommerce.* TO 'Analista_Datos';
REVOKE DELETE, DROP ON *.* FROM 'Analista_Datos';
REVOKE DROP ON *.* FROM 'Analista_Datos';
FLUSH PRIVILEGES;

-- Otorgar al rol Gerente_Marketing permiso para ejecutar procedimientos almacenados de reportes de marketing.
CREATE ROLE IF NOT EXISTS 'Gerente_Marketing';

GRANT EXECUTE ON proyecto_ecommerce.* TO 'Gerente_Marketing';

FLUSH PRIVILEGES;

-- Crear una vista v_info_clientes_basica que oculte información sensible y dar acceso a ella al rol Atencion_Cliente.
CREATE OR REPLACE VIEW v_info_clientes_basica AS
SELECT 
    id_cliente,
    nombre,
    apellido,
    email,
    telefono_contacto,
    fecha_registro
FROM clientes;

GRANT SELECT ON v_info_clientes_basica TO 'Atencion_Cliente';

FLUSH PRIVILEGES;

-- Revocar el permiso de UPDATE sobre la columna precio de la tabla productos al rol Empleado_Inventario.
REVOKE UPDATE (precio) ON productos FROM 'inventario';
FLUSH PRIVILEGES;

-- Implementar una política de contraseñas seguras para todos los usuarios.

DELIMITER $$

CREATE TRIGGER trg_validar_contrasena_insert
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.contrasena) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contraseña demasiado corta';
    ELSEIF NEW.contrasena NOT REGEXP '[A-Z]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener una mayúscula';
    ELSEIF NEW.contrasena NOT REGEXP '[0-9]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener un número';
    ELSEIF NEW.contrasena NOT REGEXP '[!@#$%^&*(),.?":{}|<>]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener un carácter especial';
    END IF;
END
CREATE TRIGGER trg_validar_contrasena_update
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.contrasena) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contraseña demasiado corta';
    ELSEIF NEW.contrasena NOT REGEXP '[A-Z]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener una mayúscula';
    ELSEIF NEW.contrasena NOT REGEXP '[0-9]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener un número';
    ELSEIF NEW.contrasena NOT REGEXP '[!@#$%^&*(),.?":{}|<>]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe tener un carácter especial';
    END IF;
END$$

DELIMITER ;
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, id_barrio_fk)
VALUES ('Juan', 'Perez', 'juan@mail.com', '3001234567', 'abc', NOW(), 1);
--Valida
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, id_barrio_fk)
VALUES ('Ana', 'López', 'ana@mail.com', '3007654321', 'Segura123!', NOW(), 1);      
-- Asegurar que el usuario root no pueda ser usado desde conexiones remotas.
SELECT User, Host FROM mysql.user WHERE User = 'root';

DELETE FROM mysql.user
WHERE User = 'root' AND Host = '%';
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User = 'root';

-- Crear un rol Visitante que solo pueda ver la tabla productos.
CREATE ROLE 'Visitante';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Visitante';

FLUSH PRIVILEGES;

-- Limitar el número de consultas por hora para el rol Analista_Datos para evitar sobrecarga.
CREATE ROLE IF NOT EXISTS 'Visitante';
CREATE USER 'analista'@'localhost' IDENTIFIED BY 'PasswordSegura123'
WITH MAX_QUERIES_PER_HOUR 100;

GRANT SELECT ON proyecto_ecommerce.productos TO 'Visitante';
GRANT 'Visitante' TO 'analista'@'localhost';
FLUSH PRIVILEGES;

-- Asegurar que los usuarios solo puedan ver las ventas de la sucursal a la que pertenecen (requiere añadir id_sucursal).
ALTER TABLE usuarios_bd
ADD COLUMN id_sucursal_fk INT,
ADD FOREIGN KEY (id_sucursal_fk) REFERENCES sucursales(id_sucursal);

CREATE OR REPLACE VIEW ventas_por_sucursal AS
SELECT v.*
FROM ventas v
JOIN usuarios_bd u ON u.id_sucursal_fk = v.id_sucursal_fk
WHERE u.id_usuario = CURRENT_USER();
CREATE USER 'usuario_sucursal'@'localhost' IDENTIFIED BY 'ContraseñaSegura123';
GRANT SELECT ON proyecto_ecommerce.productos TO 'usuario_sucursal'@'localhost';


-- Auditar todos los intentos de inicio de sesión fallidos en la base de datos.
CREATE TABLE intentos_fallidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50),
    host VARCHAR(50),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    mensaje VARCHAR(255)
) ENGINE=InnoDB;
DELIMITER $$

CREATE PROCEDURE sp_login(IN p_usuario VARCHAR(50), IN p_password VARCHAR(100))
BEGIN
    DECLARE v_pass_correcta VARCHAR(100);

    SELECT contrasena INTO v_pass_correcta
    FROM usuarios_bd
    WHERE nombre_usuario = p_usuario;

    IF v_pass_correcta IS NULL OR v_pass_correcta <> p_password THEN
        INSERT INTO intentos_fallidos(usuario, host, mensaje)
        VALUES (p_usuario, SUBSTRING_INDEX(USER(),'@',-1), 'Intento de login fallido');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario o contraseña incorrecta';
    END IF;
END$$

DELIMITER ;
CALL sp_login('usuario_inexistente', '1234');
SELECT * FROM intentos_fallidos;

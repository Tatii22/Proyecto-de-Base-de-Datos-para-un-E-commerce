
-- SEGURIDAD Y PERMISOS PARA MI TIENDA

USE `proyecto_ecommerce`;

-- 1. CREAR ROL ADMINISTRADOR_SISTEMA CON TODOS LOS PRIVILEGIOS
-- El administrador puede hacer todo

CREATE ROLE IF NOT EXISTS 'Administrador_Sistema'@'localhost';
CREATE ROLE IF NOT EXISTS 'Administrador_Sistema'@'%';

-- Le doy todos los permisos al administrador
GRANT ALL PRIVILEGES ON proyecto_ecommerce.* TO 'Administrador_Sistema'@'localhost';
GRANT ALL PRIVILEGES ON proyecto_ecommerce.* TO 'Administrador_Sistema'@'%';

-- 2. CREAR ROL GERENTE_MARKETING CON ACCESO DE SOLO LECTURA A VENTAS Y CLIENTES
-- El gerente de marketing solo puede ver datos, no modificar

CREATE ROLE IF NOT EXISTS 'Gerente_Marketing'@'localhost';
CREATE ROLE IF NOT EXISTS 'Gerente_Marketing'@'%';

-- Solo puede leer las tablas de ventas y clientes
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.promociones TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.promociones TO 'Gerente_Marketing'@'%';
GRANT SELECT ON proyecto_ecommerce.promociones_producto TO 'Gerente_Marketing'@'localhost';
GRANT SELECT ON proyecto_ecommerce.promociones_producto TO 'Gerente_Marketing'@'%';

-- 3. CREAR ROL ANALISTA_DATOS CON ACCESO DE SOLO LECTURA A TODAS LAS TABLAS, EXCEPTO AUDITORiA

CREATE ROLE IF NOT EXISTS 'Analista_Datos'@'localhost';
CREATE ROLE IF NOT EXISTS 'Analista_Datos'@'%';

-- Permisos de solo lectura para todas las tablas principales
GRANT SELECT ON proyecto_ecommerce.proveedores TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.proveedores TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.paises TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.paises TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.ciudades TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ciudades TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.barrios TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.barrios TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.sucursales TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.sucursales TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.envios TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.envios TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.carritos TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.carritos TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.productos_carritos TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos_carritos TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.promociones TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.promociones TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.promociones_producto TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.promociones_producto TO 'Analista_Datos'@'%';
GRANT SELECT ON proyecto_ecommerce.reseñas TO 'Analista_Datos'@'localhost';
GRANT SELECT ON proyecto_ecommerce.reseñas TO 'Analista_Datos'@'%';

-- 4. CREAR ROL EMPLEADO_INVENTARIO QUE SOLO PUEDA MODIFICAR LA TABLA PRODUCTOS (STOCK Y UBICACIoN)

CREATE ROLE IF NOT EXISTS 'Empleado_Inventario'@'localhost';
CREATE ROLE IF NOT EXISTS 'Empleado_Inventario'@'%';

-- Permisos para leer y modificar solo campos especificos de productos
GRANT SELECT ON proyecto_ecommerce.productos TO 'Empleado_Inventario'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Empleado_Inventario'@'%';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Empleado_Inventario'@'localhost';
GRANT SELECT ON proyecto_ecommerce.categorias TO 'Empleado_Inventario'@'%';
GRANT SELECT ON proyecto_ecommerce.proveedores TO 'Empleado_Inventario'@'localhost';
GRANT SELECT ON proyecto_ecommerce.proveedores TO 'Empleado_Inventario'@'%';

-- Permisos limitados para actualizar solo stock y campos relacionados
GRANT UPDATE (stock, stock_minimo, activo) ON proyecto_ecommerce.productos TO 'Empleado_Inventario'@'localhost';
GRANT UPDATE (stock, stock_minimo, activo) ON proyecto_ecommerce.productos TO 'Empleado_Inventario'@'%';

-- 5. CREAR ROL ATENCION_CLIENTE QUE PUEDA VER CLIENTES Y VENTAS, PERO NO MODIFICAR PRECIOS

CREATE ROLE IF NOT EXISTS 'Atencion_Cliente'@'localhost';
CREATE ROLE IF NOT EXISTS 'Atencion_Cliente'@'%';

-- Permisos de lectura para clientes y ventas
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Atencion_Cliente'@'localhost';
GRANT SELECT ON proyecto_ecommerce.clientes TO 'Atencion_Cliente'@'%';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Atencion_Cliente'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Atencion_Cliente'@'%';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Atencion_Cliente'@'localhost';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Atencion_Cliente'@'%';
GRANT SELECT ON proyecto_ecommerce.envios TO 'Atencion_Cliente'@'localhost';
GRANT SELECT ON proyecto_ecommerce.envios TO 'Atencion_Cliente'@'%';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Atencion_Cliente'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Atencion_Cliente'@'%';

-- Permisos limitados para actualizar solo informacion de clientes (no precios)
GRANT UPDATE (nombre, apellido, email, telefono_contacto, fecha_nacimiento) ON proyecto_ecommerce.clientes TO 'Atencion_Cliente'@'localhost';
GRANT UPDATE (nombre, apellido, email, telefono_contacto, fecha_nacimiento) ON proyecto_ecommerce.clientes TO 'Atencion_Cliente'@'%';
GRANT UPDATE (estado) ON proyecto_ecommerce.ventas TO 'Atencion_Cliente'@'localhost';
GRANT UPDATE (estado) ON proyecto_ecommerce.ventas TO 'Atencion_Cliente'@'%';
GRANT UPDATE (estado_envio) ON proyecto_ecommerce.envios TO 'Atencion_Cliente'@'localhost';
GRANT UPDATE (estado_envio) ON proyecto_ecommerce.envios TO 'Atencion_Cliente'@'%';

-- 6. CREAR ROL AUDITOR_FINANCIERO CON ACCESO DE SOLO LECTURA A VENTAS, PRODUCTOS Y LOGS DE PRECIOS

CREATE ROLE IF NOT EXISTS 'Auditor_Financiero'@'localhost';
CREATE ROLE IF NOT EXISTS 'Auditor_Financiero'@'%';

-- Permisos de solo lectura para auditoria financiera
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Auditor_Financiero'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ventas TO 'Auditor_Financiero'@'%';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Auditor_Financiero'@'localhost';
GRANT SELECT ON proyecto_ecommerce.detalle_ventas TO 'Auditor_Financiero'@'%';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Auditor_Financiero'@'localhost';
GRANT SELECT ON proyecto_ecommerce.productos TO 'Auditor_Financiero'@'%';
GRANT SELECT ON proyecto_ecommerce.auditoria_precios TO 'Auditor_Financiero'@'localhost';
GRANT SELECT ON proyecto_ecommerce.auditoria_precios TO 'Auditor_Financiero'@'%';
GRANT SELECT ON proyecto_ecommerce.ventas_archivo TO 'Auditor_Financiero'@'localhost';
GRANT SELECT ON proyecto_ecommerce.ventas_archivo TO 'Auditor_Financiero'@'%';

-- 7. CREAR USUARIO ADMIN_USER Y ASIGNARLE EL ROL DE ADMINISTRADOR

CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'AdminSecure123!';
CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'AdminSecure123!';

-- Asignar rol de administrador
GRANT 'Administrador_Sistema'@'localhost' TO 'admin_user'@'localhost';
GRANT 'Administrador_Sistema'@'%' TO 'admin_user'@'%';

-- Activar roles por defecto
ALTER USER 'admin_user'@'localhost' DEFAULT ROLE 'Administrador_Sistema'@'localhost';
ALTER USER 'admin_user'@'%' DEFAULT ROLE 'Administrador_Sistema'@'%';

-- APLICAR TODOS LOS CAMBIOS
FLUSH PRIVILEGES;
    
 
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

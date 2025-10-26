
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
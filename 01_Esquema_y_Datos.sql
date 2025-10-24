DROP SCHEMA IF EXISTS `proyecto_ecommerce`;
CREATE SCHEMA IF NOT EXISTS `proyecto_ecommerce` DEFAULT CHARACTER SET utf8;
USE `proyecto_ecommerce`;

CREATE TABLE proveedores (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL,
  email_contacto VARCHAR(45) NOT NULL UNIQUE,
  telefono_contacto VARCHAR(15),
  CHECK (email_contacto LIKE '%@%')
) ENGINE=InnoDB;

CREATE TABLE categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT(500)
) ENGINE=InnoDB;

CREATE TABLE productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (precio >= 0),
  iva DECIMAL(6,2) CHECK (iva BETWEEN 0 AND 100),
  costo DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (costo >= 0),
  stock DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (stock >= 0),
  stock_minimo DECIMAL(10,2) CHECK (stock_minimo >= 0),
  sku VARCHAR(50) NOT NULL UNIQUE,
  fecha_creacion DATETIME NOT NULL,
  activo TINYINT NOT NULL CHECK (activo IN (0,1)),
  visto INT,
  peso DECIMAL(5,3) NOT NULL CHECK (peso >= 0),
  id_proveedor_fk INT NOT NULL,
  id_categoria_fk INT NOT NULL,
  FOREIGN KEY (id_proveedor_fk) REFERENCES proveedores(id_proveedor),
  FOREIGN KEY (id_categoria_fk) REFERENCES categorias(id_categoria)
) ENGINE=InnoDB;

CREATE TABLE paises (
  id_pais INT AUTO_INCREMENT PRIMARY KEY,
  pais VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE ciudades (
  id_ciudad INT AUTO_INCREMENT PRIMARY KEY,
  ciudad VARCHAR(50) NOT NULL,
  num_dia INT,
  id_pais_fk INT NOT NULL,
  FOREIGN KEY (id_pais_fk) REFERENCES paises(id_pais)
) ENGINE=InnoDB;

CREATE TABLE barrios (
  id_barrio INT AUTO_INCREMENT PRIMARY KEY,
  barrio VARCHAR(50) NOT NULL,
  id_ciudad_fk INT NOT NULL,
  FOREIGN KEY (id_ciudad_fk) REFERENCES ciudades(id_ciudad)
) ENGINE=InnoDB;

CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL,
  apellido VARCHAR(45) NOT NULL,
  email VARCHAR(45) NOT NULL UNIQUE,
  telefono_contacto VARCHAR(15) NOT NULL,
  contrasena VARCHAR(45) NOT NULL,
  fecha_registro DATETIME NOT NULL,
  fecha_nacimiento DATE,
  id_barrio_fk INT NOT NULL,
  total_gastado DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total_gastado >= 0),
  FOREIGN KEY (id_barrio_fk) REFERENCES barrios(id_barrio)
) ENGINE=InnoDB;

CREATE TABLE sucursales (
  id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  direccion VARCHAR(50) NOT NULL,
  telefono VARCHAR(15) NOT NULL,
  id_barrio_fk INT NOT NULL,
  FOREIGN KEY (id_barrio_fk) REFERENCES barrios(id_barrio)
) ENGINE=InnoDB;

CREATE TABLE ventas (
  id_venta INT AUTO_INCREMENT PRIMARY KEY,
  fecha_venta DATETIME NOT NULL,
  estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  id_cliente_fk INT NOT NULL,
  id_sucursal_fk INT NOT NULL,
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_sucursal_fk) REFERENCES sucursales(id_sucursal)
) ENGINE=InnoDB;

CREATE TABLE detalle_ventas (
  id_venta_fk INT NOT NULL,
  id_producto_fk INT NOT NULL,
  cantidad INT DEFAULT 1 CHECK (cantidad > 0),
  precio_unitario_congelado DECIMAL(10,2) NOT NULL CHECK (precio_unitario_congelado >= 0),
  iva_porcentaje_aplicado DECIMAL(5,2) NOT NULL CHECK (iva_porcentaje_aplicado BETWEEN 0 AND 100),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  total_linea DECIMAL(10,2) NOT NULL CHECK (total_linea >= 0),
  PRIMARY KEY (id_venta_fk, id_producto_fk),
  FOREIGN KEY (id_venta_fk) REFERENCES ventas(id_venta),
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

CREATE TABLE envios (
  id_envios INT AUTO_INCREMENT PRIMARY KEY,
  direccion_envio VARCHAR(45) NOT NULL,
  codigo_rastreo VARCHAR(45) NOT NULL UNIQUE,
  fecha_envio DATETIME NOT NULL,
  fecha_entrega DATETIME NOT NULL,
  estado_envio ENUM('Preparando', 'En tránsito', 'Entregado', 'Devuelto'),
  id_venta_fk INT NOT NULL,
  id_barrio_fk INT NOT NULL,
  FOREIGN KEY (id_venta_fk) REFERENCES ventas(id_venta),
  FOREIGN KEY (id_barrio_fk) REFERENCES barrios(id_barrio)
) ENGINE=InnoDB;

CREATE TABLE carritos (
  id_carritos INT AUTO_INCREMENT PRIMARY KEY,
  fecha_creacion DATETIME NOT NULL,
  fecha_cierre DATETIME NOT NULL,
  estado ENUM('Abierto', 'Convertido', 'Abandonado') NOT NULL,
  id_cliente_fk INT NOT NULL,
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE productos_carritos (
  id_producto_fk INT NOT NULL,
  id_carritos_fk INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  PRIMARY KEY (id_producto_fk, id_carritos_fk),
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto),
  FOREIGN KEY (id_carritos_fk) REFERENCES carritos(id_carritos)
) ENGINE=InnoDB;

CREATE TABLE promociones (
  id_promocion INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NOT NULL,
  descuento_porcentaje DECIMAL(6,2) NOT NULL CHECK (descuento_porcentaje BETWEEN 0 AND 100),
  activa TINYINT NOT NULL DEFAULT 1 CHECK (activa IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE promociones_producto (
  id_producto_fk INT NOT NULL,
  id_promocion_fk INT NOT NULL,
  PRIMARY KEY (id_producto_fk, id_promocion_fk),
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto),
  FOREIGN KEY (id_promocion_fk) REFERENCES promociones(id_promocion)
) ENGINE=InnoDB;

CREATE TABLE auditoria_precios (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  precio_anterior DECIMAL(10,2) CHECK (precio_anterior >= 0),
  precio_nuevo DECIMAL(10,2) CHECK (precio_nuevo >= 0),
  fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
  usuario VARCHAR(100),
  id_producto_fk INT NOT NULL,
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

CREATE TABLE usuarios_bd (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre_usuario VARCHAR(45) NOT NULL UNIQUE,
  rol ENUM('Administrador_Sistema', 'Gerente_Marketing', 'Analista_Datos', 'Empleado_Inventario') NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo TINYINT NOT NULL CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE auditoria_clientes (
  id_auditoria INT NOT NULL PRIMARY KEY,
  accion ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario VARCHAR(100),
  id_cliente_fk INT NOT NULL,
  id_usuario_fk INT NOT NULL,
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_usuario_fk) REFERENCES usuarios_bd(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE alertas_stock (
  id_alerta INT AUTO_INCREMENT PRIMARY KEY,
  mensaje VARCHAR(255) NOT NULL,
  fecha DATETIME NOT NULL,
  estado ENUM('Pendiente', 'Atendida') NOT NULL DEFAULT 'Pendiente',
  id_producto_fk INT NOT NULL,
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

CREATE TABLE ventas_archivo (
  id_venta INT AUTO_INCREMENT PRIMARY KEY,
  fecha_venta DATETIME NOT NULL,
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
  motivo_archivo VARCHAR(200),
  id_sucursal_fk INT NOT NULL,
  id_cliente_fk INT NOT NULL,
  FOREIGN KEY (id_sucursal_fk) REFERENCES sucursales(id_sucursal),
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE permisos_log (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  usuario VARCHAR(50) NOT NULL,
  accion VARCHAR(255) NOT NULL,
  fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  descripcion TEXT,
  id_usuario_fk INT NOT NULL,
  FOREIGN KEY (id_usuario_fk) REFERENCES usuarios_bd(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE reseñas (
  id_reseña INT AUTO_INCREMENT PRIMARY KEY,
  calificacion INT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
  comentario VARCHAR(500) NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_producto_fk INT NOT NULL,
  id_cliente_fk INT NOT NULL,
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto),
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

-- ==========================================
-- BASE DE DATOS: proyecto_ecommerce
-- ==========================================
DROP DATABASE IF EXISTS proyecto_ecommerce;
CREATE DATABASE proyecto_ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE proyecto_ecommerce;

-- ==========================================
-- TABLA: PAISES
-- ==========================================
CREATE TABLE paises (
    id_pais INT AUTO_INCREMENT PRIMARY KEY,
    pais VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: CIUDADES
-- ==========================================
CREATE TABLE ciudades (
    id_ciudad INT AUTO_INCREMENT PRIMARY KEY,
    ciudad VARCHAR(100) NOT NULL,
    id_pais INT NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES paises(id_pais)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: BARRIOS
-- ==========================================
CREATE TABLE barrios (
    id_barrio INT AUTO_INCREMENT PRIMARY KEY,
    barrio VARCHAR(100) NOT NULL,
    id_ciudad INT NOT NULL,
    FOREIGN KEY (id_ciudad) REFERENCES ciudades(id_ciudad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: CATEGORIAS
-- ==========================================
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PROVEEDORES
-- ==========================================
CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email_contacto VARCHAR(100) UNIQUE,
    telefono_contacto VARCHAR(30)
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PRODUCTOS
-- ==========================================
CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    sku VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    peso DECIMAL(6,3) DEFAULT 0 CHECK (peso >= 0),
    id_categoria INT NOT NULL,
    id_proveedor INT,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: CLIENTES
-- ==========================================
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono_contacto VARCHAR(30),
    contraseña VARCHAR(255) NOT NULL,
    direccion_envio TEXT,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    id_barrio INT,
    FOREIGN KEY (id_barrio) REFERENCES barrios(id_barrio)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: SUCURSALES
-- ==========================================
CREATE TABLE sucursales (
    id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    telefono VARCHAR(30),
    id_barrio INT NOT NULL,
    FOREIGN KEY (id_barrio) REFERENCES barrios(id_barrio)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: VENTAS
-- ==========================================
CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_sucursal INT,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: DETALLE DE VENTAS
-- ==========================================
CREATE TABLE detalle_ventas (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_congelado DECIMAL(10,2) NOT NULL CHECK (precio_unitario_congelado > 0),
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario_congelado) STORED,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: ENVIOS
-- ==========================================
CREATE TABLE envios (
    id_envio INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    direccion_envio TEXT NOT NULL,
    codigo_rastreo VARCHAR(100) UNIQUE,
    fecha_envio DATETIME,
    fecha_entrega DATETIME,
    estado ENUM('Preparando', 'En tránsito', 'Entregado', 'Devuelto') DEFAULT 'Preparando',
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PAGOS
-- ==========================================
CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    metodo_pago ENUM('Efectivo', 'Tarjeta Crédito', 'Tarjeta Débito', 'Transferencia', 'PSE') NOT NULL,
    monto_pagado DECIMAL(10,2) NOT NULL CHECK (monto_pagado >= 0),
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    referencia_transaccion VARCHAR(100) UNIQUE,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: CARRITOS
-- ==========================================
CREATE TABLE carritos (
    id_carrito INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre DATETIME,
    estado ENUM('Abierto', 'Convertido', 'Abandonado') DEFAULT 'Abierto',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PRODUCTOS EN CARRITOS
-- ==========================================
CREATE TABLE productos_carritos (
    id_producto INT NOT NULL,
    id_carrito INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    PRIMARY KEY (id_producto, id_carrito),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_carrito) REFERENCES carritos(id_carrito)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PROMOCIONES
-- ==========================================
CREATE TABLE promociones (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    descuento_porcentaje DECIMAL(5,2) NOT NULL CHECK (descuento_porcentaje BETWEEN 0 AND 100),
    activa BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: PROMOCIONES_PRODUCTO
-- ==========================================
CREATE TABLE promociones_producto (
    id_producto INT NOT NULL,
    id_promocion INT NOT NULL,
    PRIMARY KEY (id_producto, id_promocion),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_promocion) REFERENCES promociones(id_promocion)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: AUDITORIA_PRECIOS
-- ==========================================
CREATE TABLE auditoria_precios (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL CHECK (precio_anterior >= 0),
    precio_nuevo DECIMAL(10,2) NOT NULL CHECK (precio_nuevo >= 0),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: USUARIOS_BD
-- ==========================================
CREATE TABLE usuarios_bd (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(100) NOT NULL UNIQUE,
    rol ENUM('Administrador_Sistema', 'Gerente_Marketing', 'Analista_Datos', 'Empleado_Inventario') NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: AUDITORIA_CLIENTES
-- ==========================================
CREATE TABLE auditoria_clientes (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    accion ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    fecha_evento DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100),
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios_bd(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: ALERTAS_STOCK
-- ==========================================
CREATE TABLE alertas_stock (
    id_alerta INT AUTO_INCREMENT PRIMARY KEY,
    mensaje VARCHAR(255) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente', 'Atendida') DEFAULT 'Pendiente',
    id_producto INT NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: RESEÑAS
-- ==========================================
CREATE TABLE reseñas (
    id_reseña INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_cliente INT NOT NULL,
    calificacion TINYINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario TEXT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- TABLA: HISTORIAL_STOCK
-- ==========================================
CREATE TABLE historial_stock (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    tipo_movimiento ENUM('Entrada', 'Salida', 'Ajuste') NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT,
    usuario_responsable VARCHAR(100),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

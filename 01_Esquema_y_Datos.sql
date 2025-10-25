DROP SCHEMA IF EXISTS `proyecto_ecommerce`;
CREATE SCHEMA IF NOT EXISTS `proyecto_ecommerce` DEFAULT CHARACTER SET utf8;
USE `proyecto_ecommerce`;

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
  estado ENUM('PendientePago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
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
  estado_envio ENUM('Preparando', 'Entransito', 'Entregado', 'Devuelto','Cancelado'),
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

-- INSERTS


-- INSERTS PARA PAISES (20)
INSERT INTO paises (pais) VALUES
('Colombia'), 
('México'), 
('Argentina'), 
('Chile'), 
('Perú'),
('Brasil'), 
('Ecuador'), 
('Uruguay'), 
('Paraguay'), 
('Bolivia'),
('España'), 
('Portugal'), 
('Francia'), 
('Italia'), 
('Alemania'),
('Estados Unidos'), 
('Canadá'), 
('Japón'), 
('China'), 
('Corea del Sur');

-- INSERTS PARA CIUDADES (20)
INSERT INTO ciudades (ciudad, num_dia, id_pais_fk) VALUES
('Bogotá', 1, 1), 
('Medellín', 2, 1), 
('Cali', 3, 1), 
('Ciudad de México', 4, 2), 
('Guadalajara', 5, 2),
('Buenos Aires', 6, 3), 
('Rosario', 7, 3), 
('Santiago', 8, 4), 
('Lima', 9, 5), 
('Río de Janeiro', 10, 6),
('Quito', 11, 7), 
('Montevideo', 12, 8), 
('Asunción', 13, 9), 
('La Paz', 14, 10), 
('Madrid', 15, 11),
('Lisboa', 16, 12), 
('París', 17, 13), 
('Roma', 18, 14), 
('Berlín', 19, 15), 
('New York', 20, 16);

-- INSERTS PARA BARRIOS (20)
INSERT INTO barrios (barrio, id_ciudad_fk) VALUES
('Chapinero', 1), 
('El Poblado', 2), 
('San Antonio', 3), 
('Polanco', 4), 
('Tlaquepaque', 5),
('Palermo', 6), 
('Centro', 7), 
('Providencia', 8), 
('Miraflores', 9), 
('Copacabana', 10),
('La Floresta', 11), 
('Pocitos', 12), 
('Villa Morra', 13), 
('Sopocachi', 14), 
('Salamanca', 15),
('Belém', 16), 
('Montmartre', 17), 
('Trastevere', 18), 
('Tiergarten', 19), 
('Brooklyn', 20);

-- INSERTS PARA PROVEEDORES (20)
INSERT INTO proveedores (nombre, email_contacto, telefono_contacto) VALUES
('Distribuciones Andina S.A.S.', 'ventas@andina.com.co', '3174526890'),
('TecnoGlobal Ltda.', 'contacto@tecnoglobal.com', '3109823456'),
('Suministros del Norte', 'info@suminorte.co', '3167451230'),
('Grupo Alimentos Rivera', 'pedidos@alimentosrivera.com', '3136048927'),
('Insumos Médicos del Oriente', 'contacto@insumosoriente.co', '3142097856'),
('Papelería Universal', 'ventas@papeleriauniversal.com', '3186001743'),
('ConstruMarket S.A.', 'contacto@constru-market.com', '3209875643'),
('Energías del Futuro', 'ventas@enerfuturo.com', '3126009451'),
('Ferretería El Tornillo Feliz', 'atencion@tornillofeliz.co', '3115632048'),
('Textiles Bucaramanga', 'ventas@textibuca.com', '3154729681'),
('Distribuidora Gourmet', 'info@dgourmet.co', '3168904321'),
('Computec Solutions', 'contacto@computecsoluciones.com', '3198756043'),
('LimpioMax S.A.S.', 'ventas@limpiomax.com', '3126984750'),
('RefriAndes', 'contacto@refriandes.co', '3108963471'),
('AgroCampo Ltda.', 'ventas@agrocampo.co', '3176054892'),
('ElectroHogar', 'soporte@electrohogar.com', '3147098653'),
('Maderas del Sur', 'ventas@maderadelsur.com', '3158906742'),
('Impresiones Digitales 3D', 'info@id3d.co', '3125689470'),
('Químicos del Caribe', 'contacto@quimcaribe.com', '3207658491'),
('Logística Express', 'servicio@logisticaexpress.co', '3137852049');

-- INSERTS PARA CATEGORIAS (20)
INSERT INTO categorias (nombre, descripcion) VALUES
('Tecnología', 'Artículos electrónicos'),
('Hogar', 'Decoración y electrodomésticos'),
('Ropa', 'Prendas de vestir'),
('Calzado', 'Zapatos de todo tipo'),
('Deportes', 'Equipamiento deportivo'),
('Belleza', 'Productos de cuidado personal'),
('Juguetería', 'Juegos y juguetes'),
('Herramientas', 'Instrumentos para trabajo'),
('Automotriz', 'Accesorios de vehículos'),
('Jardinería', 'Artículos para jardines'),
('Electrodomésticos', 'Productos para el hogar'),
('Oficina', 'Útiles y escritorio'),
('Librería', 'Libros y cuadernos'),
('Música', 'Instrumentos y accesorios'),
('Bebés', 'Artículos para bebé'),
('Mascotas', 'Productos para animales'),
('Salud', 'Bienestar y farmacia'),
('Videojuegos', 'Consolas y juegos'),
('Iluminación', 'Lámparas y focos'),
('Arte', 'Material artístico');

-- INSERTS PARA PRODUCTOS (20)
INSERT INTO productos (nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku, fecha_creacion, activo, visto, peso, id_proveedor_fk, id_categoria_fk) VALUES
('Café Premium Andino 500g', 'Café de origen colombiano, tostado medio y molido, en presentación de 500 gramos.', 18500.00, 19.00, 12000.00, 60, 10, 'SKU001', NOW(), 1, 25, 0.500, 1, 5),
('Mouse Inalámbrico Logitech M170', 'Mouse óptico inalámbrico con receptor USB y diseño ergonómico.', 52000.00, 19.00, 35000.00, 40, 5, 'SKU002', NOW(), 1, 40, 0.120, 2, 1),
('Papel Resma Carta 500 Hojas', 'Resma de papel blanco tamaño carta, 75 g/m², ideal para oficina.', 18500.00, 19.00, 12000.00, 80, 10, 'SKU003', NOW(), 1, 55, 2.500, 6, 12),
('Arroz Premium 5kg', 'Arroz blanco tipo exportación, grano largo, sin impurezas.', 28500.00, 19.00, 19000.00, 50, 8, 'SKU004', NOW(), 1, 20, 5.000, 4, 5),
('Guantes de Nitrilo Azul (Caja x100)', 'Guantes desechables de nitrilo para uso médico o industrial.', 42000.00, 19.00, 28000.00, 30, 5, 'SKU005', NOW(), 1, 30, 0.800, 5, 17),
('Detergente Líquido Multiusos 2L', 'Detergente líquido concentrado para limpieza de superficies.', 17500.00, 19.00, 9500.00, 45, 6, 'SKU006', NOW(), 1, 28, 2.000, 13, 2),
('Tornillos para Madera (Caja x100)', 'Tornillos galvanizados de 1½", resistentes a la oxidación.', 12000.00, 19.00, 7000.00, 90, 10, 'SKU007', NOW(), 1, 22, 1.000, 9, 8),
('Panel Solar 150W Monocristalino', 'Panel solar con alta eficiencia, ideal para sistemas residenciales.', 420000.00, 19.00, 310000.00, 15, 2, 'SKU008', NOW(), 1, 17, 10.000, 8, 19),
('Camisa Polo Hombre Talla M', 'Camisa tipo polo de algodón, color azul marino.', 58000.00, 19.00, 35000.00, 35, 5, 'SKU009', NOW(), 1, 19, 0.350, 10, 3),
('Lámpara LED de Escritorio', 'Lámpara LED con brazo flexible y puerto USB, bajo consumo.', 72000.00, 19.00, 50000.00, 25, 4, 'SKU010', NOW(), 1, 40, 0.800, 2, 19),
('Queso Mozzarella 1kg', 'Queso mozzarella fresco ideal para pizzas y pastas.', 28500.00, 19.00, 19000.00, 30, 5, 'SKU011', NOW(), 1, 33, 1.000, 11, 5),
('Tóner HP 12A', 'Cartucho de tóner negro compatible con impresoras HP LaserJet.', 145000.00, 19.00, 110000.00, 12, 2, 'SKU012', NOW(), 1, 25, 0.750, 12, 12),
('Aspiradora Portátil 1200W', 'Aspiradora compacta para el hogar con filtro lavable.', 240000.00, 19.00, 180000.00, 18, 3, 'SKU013', NOW(), 1, 26, 3.500, 16, 11),
('Bloque de Madera Pino 2x4', 'Bloques de madera seca y cepillada, ideales para construcción.', 21000.00, 19.00, 14000.00, 60, 10, 'SKU014', NOW(), 1, 15, 2.400, 17, 8),
('Filete de Pescado Tilapia 1kg', 'Filete fresco empacado al vacío, sin espinas.', 32000.00, 19.00, 22000.00, 20, 3, 'SKU015', NOW(), 1, 20, 1.000, 4, 5),
('Desinfectante Ambiental 1L', 'Desinfectante antibacterial con aroma cítrico.', 10500.00, 19.00, 6500.00, 75, 8, 'SKU016', NOW(), 1, 48, 1.000, 13, 2),
('Cable HDMI 2.0 3 Metros', 'Cable HDMI alta velocidad para video y audio HD.', 23000.00, 19.00, 13000.00, 50, 6, 'SKU017', NOW(), 1, 35, 0.250, 2, 1),
('Impresora Multifuncional Epson L3250', 'Impresora con sistema EcoTank, impresión inalámbrica.', 789000.00, 19.00, 610000.00, 10, 2, 'SKU018', NOW(), 1, 28, 5.000, 12, 12),
('Aceite Vegetal 3L', 'Aceite comestible 100% vegetal, libre de colesterol.', 18500.00, 19.00, 12500.00, 40, 6, 'SKU019', NOW(), 1, 30, 3.000, 4, 5),
('Cinta de Embalaje Transparente', 'Cinta adhesiva industrial para empaque de cajas.', 8500.00, 19.00, 5000.00, 100, 15, 'SKU020', NOW(), 1, 52, 0.200, 20, 12);


-- INSERTS PARA CLIENTES (20)
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, fecha_nacimiento, id_barrio_fk, total_gastado) VALUES
('Juan', 'Pipo', 'juan.pipo1@mail.com', '300000001', 'pass123', NOW(), '1990-05-10', 1, 150.00),
('Ana', 'Lecoq', 'ana.lecoq2@mail.com', '300000002', 'pass123', NOW(), '1988-08-20', 2, 200.00),
('Luis', 'Newton', 'luis.newton3@mail.com', '300000003', 'pass123', NOW(), '1995-02-15', 3, 300.00),
('Sofía', 'Newt', 'sofia.newt4@mail.com', '300000004', 'pass123', NOW(), '1992-09-07', 4, 120.50),
('Carlos', 'Blanco', 'carlos.blanco5@mail.com', '300000005', 'pass123', NOW(), '1987-10-11', 5, 500.00),
('Sebastian', 'Montoya', 'sebastian.montoya6@mail.com', '300000006', 'pass123', NOW(), '1999-12-01', 6, 250.00),
('Pedro', 'Sánchez', 'pedro.sanchez7@mail.com', '300000007', 'pass123', NOW(), '1989-06-29', 7, 175.00),
('Lucía', 'Hernández', 'lucia.hernandez8@mail.com', '300000008', 'pass123', NOW(), '1996-03-03', 8, 220.00),
('Miguel', 'Castro', 'miguel.castro9@mail.com', '300000009', 'pass123', NOW(), '1985-01-21', 9, 350.00),
('Laura', 'Gómez', 'laura.gomez10@mail.com', '300000010', 'pass123', NOW(), '2000-04-14', 10, 90.00),
('Diego', 'Morales', 'diego.morales11@mail.com', '300000011', 'pass123', NOW(), '1993-07-16', 11, 400.00),
('Valentina', 'Flores', 'valentina.flores12@mail.com', '300000012', 'pass123', NOW(), '1997-11-09', 12, 320.40),
('Tatiana', 'Ruiz', 'tatiana.ruiz13@mail.com', '300000013', 'pass123', NOW(), '1986-12-25', 13, 180.00),
('Paula', 'Ortiz', 'paula.ortiz14@mail.com', '300000014', 'pass123', NOW(), '1991-05-05', 14, 230.00),
('Brandon', 'Blanco', 'brandon.blanco15@mail.com', '300000015', 'pass123', NOW(), '1994-09-17', 15, 280.00),
('Camila', 'Vargas', 'camila.vargas16@mail.com', '300000016', 'pass123', NOW(), '1998-10-30', 16, 350.00),
('Ángel', 'Suárez', 'angel.suarez17@mail.com', '300000017', 'pass123', NOW(), '1987-04-08', 17, 420.00),
('Daniela', 'Molina', 'daniela.molina18@mail.com', '300000018', 'pass123', NOW(), '1995-02-18', 18, 150.00),
('Felipe', 'Guerra', 'felipe.guerra19@mail.com', '300000019', 'pass123', NOW(), '1989-08-01', 19, 290.90),
('Alejandra', 'Blanco', 'alejandra.blanco20@mail.com', '300000020', 'pass123', NOW(), '1993-03-10', 20, 510.00);

-- INSERTS PARA SUCURSALES (20)
INSERT INTO sucursales (nombre, direccion, telefono, id_barrio_fk) VALUES
('Sucursal Principal Cabecera', 'Cra 35 #48-22, Cabecera del Llano', '6076432201', 1),
('Sucursal Cañaveral', 'Calle 30 #28-15, Cañaveral', '6076521198', 2),
('Sucursal Provenza', 'Cra 21 #110-05, Portales de Provenza', '3174526890', 3),
('Sucursal Real de Minas', 'Av. La Rosita #21-80, Real de Minas', '6076413322', 4),
('Sucursal Centro', 'Calle 36 #17-22, Centro', '6076309088', 5),
('Sucursal San Francisco', 'Cra 22 #15-09, San Francisco', '6076439875', 6),
('Sucursal Girón Central', 'Calle 28 #24-10, Girón', '6076467453', 7),
('Sucursal Floridablanca Norte', 'Av. Bucarica #10-20, Floridablanca', '6076483921', 8),
('Sucursal Lagos del Cacique', 'Calle 54 #34-09, Lagos del Cacique', '6076420109', 9),
('Sucursal Mutis', 'Cra 16 #64-25, Mutis', '6076435012', 10),
('Sucursal La Victoria', 'Cra 27 #45-30, La Victoria', '6076440820', 11),
('Sucursal La Cumbre', 'Calle 30 #14-18, La Cumbre', '6076523401', 12),
('Sucursal Sotomayor', 'Cra 33 #52-17, Sotomayor', '6076451976', 13),
('Sucursal San Alonso', 'Calle 14 #26-32, San Alonso', '6076465013', 14),
('Sucursal Morrorico', 'Calle 6 #12-45, Morrorico', '6076468751', 15),
('Sucursal El Bosque', 'Cra 18 #36-20, El Bosque', '6076472089', 16),
('Sucursal Kennedy', 'Calle 9 #28-19, Kennedy', '6076476592', 17),
('Sucursal La Salle', 'Cra 29 #56-04, La Salle', '6076480021', 18),
('Sucursal San Luis', 'Calle 60 #15-33, San Luis', '6076483580', 19),
('Sucursal Altos de Cabecera', 'Cra 38 #45-50, Altos de Cabecera', '6076492045', 20);

-- INSERTS PARA VENTAS (20)
INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES 
('2025-01-05 14:23:10', 'PendientePago', 89.99, 1, 1),
('2025-01-06 09:15:45', 'Procesando', 129.50, 2, 1),
('2025-01-06 16:32:25', 'Enviado', 45.00, 1, 2),
('2025-01-07 11:05:00', 'Entregado', 210.75, 3, 2),
('2025-01-07 18:49:12', 'Cancelado', 150.20, 1, 3),
('2025-01-08 10:21:33', 'PendientePago', 72.90, 2, 3),
('2025-01-08 13:44:55', 'Procesando', 305.10, 3, 1),
('2025-01-08 20:50:01', 'Entregado', 98.99, 2, 2),
('2025-01-09 12:10:37', 'Enviado', 220.00, 3, 1),
('2025-01-09 19:02:49', 'Cancelado', 65.40, 1, 2),
('2025-01-10 08:45:23', 'PendientePago', 180.30, 4, 1),
('2025-01-10 15:22:11', 'Procesando', 55.70, 5, 2),
('2025-01-11 10:09:45', 'Enviado', 330.99, 4, 3),
('2025-01-11 17:33:29', 'Entregado', 120.50, 5, 1),
('2025-01-11 21:10:13', 'Cancelado', 44.99, 4, 2),
('2025-01-12 09:05:42', 'PendientePago', 260.75, 2, 3),
('2025-01-12 14:58:00', 'Procesando', 199.00, 3, 2),
('2025-01-12 22:11:55', 'Enviado', 88.60, 5, 3),
('2025-01-13 13:47:33', 'Entregado', 412.40, 4, 1),
('2025-01-13 19:26:17', 'Cancelado', 27.99, 2, 2);



-- INSERTS PARA DETALLE_VENTAS (5)
INSERT INTO detalle_ventas (id_venta_fk, id_producto_fk, cantidad, precio_unitario_congelado, iva_porcentaje_aplicado, subtotal, total_linea)
VALUES
(1, 1, 2, 15.00, 19.00, 30.00, 35.70),
(1, 3, 1, 59.99, 19.00, 59.99, 71.39),
(2, 2, 1, 120.00, 19.00, 120.00, 142.80),
(2, 5, 1,  9.50, 19.00,  9.50, 11.31),
(3, 4, 3, 10.00, 19.00, 30.00, 35.70),
(4, 1, 1, 15.00, 19.00, 15.00, 17.85),
(4, 3, 2, 59.99, 19.00, 119.98, 142.78),
(4, 5, 4,  9.50, 19.00, 38.00, 45.22),
(5, 2, 1, 120.00, 19.00, 120.00, 142.80);

-- INSERTS PARA ENVIOS (5)
INSERT INTO envios (direccion_envio, codigo_rastreo, fecha_envio, fecha_entrega, estado_envio, id_venta_fk, id_barrio_fk)
VALUES
('Calle 45 # 12-30', 'TRK123456COL', '2025-01-06 09:30:00', '2025-01-08 14:00:00', 'Entregado', 1, 1),
('Carrera 22 # 80-15', 'TRK789012COL', '2025-01-07 10:20:00', '2025-01-09 16:30:00', 'Entransito', 2, 2),
('Av. Central 10-55', 'TRK456789COL', '2025-01-08 08:45:00', '2025-01-10 12:15:00', 'Preparando', 3, 3),
('Calle 12 # 50-05', 'TRK159357COL', '2025-01-08 14:55:00', '2025-01-11 18:25:00', 'Entransito', 4, 1),
('Carrera 5 # 22-99', 'TRK753951COL', '2025-01-09 11:10:00', '2025-01-12 13:50:00', 'Devuelto', 5, 2),
('Calle 90 # 25-12', 'TRK202501COL', '2025-01-10 07:12:00', '2025-01-13 09:34:00', 'Entransito', 6, 3),
('Carrera 18 # 44-20', 'TRK202502COL', '2025-01-10 10:45:00', '2025-01-12 15:10:00', 'Entregado', 7, 1),
('Av. Libertad # 100-40', 'TRK202503COL', '2025-01-11 09:35:00', '2025-01-14 11:49:00', 'Cancelado', 8, 2),
('Calle 7 # 60-33', 'TRK202504COL', '2025-01-11 13:20:00', '2025-01-14 20:05:00', 'Preparando', 9, 3),
('Transversal 15 # 55-17', 'TRK202505COL', '2025-01-12 08:40:00', '2025-01-15 10:22:00', 'Entransito', 10, 1),
('Diagonal 32 # 15-50', 'TRK202506COL', '2025-01-12 12:10:00', '2025-01-16 17:55:00', 'Entregado', 11, 2),
('Calle 100 # 70-25', 'TRK202507COL', '2025-01-13 07:33:00', '2025-01-17 14:30:00', 'Entransito', 12, 3),
('Carrera 45 # 90-10', 'TRK202508COL', '2025-01-13 15:55:00', '2025-01-16 12:50:00', 'Devuelto', 13, 1),
('Av. Principal 50-20', 'TRK202509COL', '2025-01-14 10:05:00', '2025-01-18 19:42:00', 'Preparando', 14, 2),
('Calle 24 # 33-18', 'TRK202510COL', '2025-01-14 18:25:00', '2025-01-19 16:11:00', 'Entransito', 15, 3),
('Carrera 8 # 21-48', 'TRK202511COL', '2025-01-15 09:40:00', '2025-01-20 11:18:00', 'Entregado', 16, 1),
('Calle 11 # 23-19', 'TRK202512COL', '2025-01-15 14:10:00', '2025-01-18 17:59:00', 'Entransito', 17, 2),
('Calle 99 # 11-07', 'TRK202513COL', '2025-01-16 08:05:00', '2025-01-21 14:44:00', 'Preparando', 18, 3),
('Carrera 66 # 40-88', 'TRK202514COL', '2025-01-16 12:20:00', '2025-01-22 10:31:00', 'Devuelto', 19, 1),
('Av. Colón # 75-32', 'TRK202515COL', '2025-01-17 07:55:00', '2025-01-23 19:05:00', 'Entransito', 20, 2);

-- INSERTS PARA CARRITO (20)
INSERT INTO carritos (fecha_creacion, fecha_cierre, estado, id_cliente_fk)
VALUES
('2025-01-05 10:15:22', '2025-01-05 14:23:10', 'Convertido', 1),
('2025-01-06 08:05:19', '2025-01-06 09:15:45', 'Convertido', 2),
('2025-01-06 15:00:11', '2025-01-06 16:32:25', 'Convertido', 1),
('2025-01-07 10:30:00', '2025-01-08 09:45:18', 'Abandonado', 3),
('2025-01-07 18:02:51', '2025-01-07 18:49:12', 'Convertido', 1),
('2025-01-08 09:15:40', '2025-01-10 13:00:10', 'Abandonado', 2),
('2025-01-08 13:05:00', '2025-01-08 13:44:55', 'Convertido', 3),
('2025-01-09 11:40:37', '2025-01-09 19:02:49', 'Convertido', 2),
('2025-01-09 17:25:10', '2025-01-10 10:10:00', 'Abierto', 3),
('2025-01-10 09:00:00', '2025-01-10 09:00:00', 'Abierto', 1),
('2025-01-10 14:22:33', '2025-01-10 16:00:00', 'Convertido', 1),
('2025-01-11 08:10:50', '2025-01-11 09:45:12', 'Convertido', 2),
('2025-01-11 15:55:21', '2025-01-12 18:10:44', 'Abandonado', 3),
('2025-01-12 12:05:30', '2025-01-12 14:40:59', 'Convertido', 1),
('2025-01-12 18:32:19', '2025-01-13 09:22:11', 'Abierto', 2),
('2025-01-13 07:20:05', '2025-01-13 07:20:05', 'Abierto', 3),
('2025-01-13 16:45:10', '2025-01-13 20:50:30', 'Convertido', 2),
('2025-01-14 10:12:42', '2025-01-14 15:14:22', 'Abandonado', 1),
('2025-01-14 19:30:00', '2025-01-15 08:02:15', 'Convertido', 3),
('2025-01-15 09:00:55', '2025-01-15 09:45:00', 'Abierto', 2);


-- INSERTS PRODUCTOS CARRITO
INSERT INTO productos_carritos (id_producto_fk, id_carritos_fk, cantidad) VALUES
(1, 1, 2),
(2, 1, 1),
(3, 2, 1),
(4, 2, 3),
(5, 3, 1),
(1, 3, 4),
(2, 4, 2),
(3, 4, 1),
(4, 5, 1),
(5, 5, 2),
(1, 6, 1),
(3, 6, 2),
(2, 7, 1),
(5, 7, 3),
(4, 8, 2),
(3, 8, 1),
(1, 9, 2),
(2, 9, 2),
(5, 10, 1),
(4, 10, 4);

-- INSERTS PROMOCIONES (20)
INSERT INTO promociones (nombre, fecha_inicio, fecha_fin, descuento_porcentaje, activa) VALUES
('Descuento Año Nuevo', '2025-01-01 00:00:00', '2025-01-10 23:59:59', 10.00, 0),
('Promo Verano', '2025-02-01 00:00:00', '2025-02-28 23:59:59', 15.00, 1),
('Liquidación de Invierno', '2025-03-01 00:00:00', '2025-03-10 23:59:59', 20.00, 1),
('Semana del Cliente', '2025-03-15 00:00:00', '2025-03-22 23:59:59', 12.00, 1),
('Black Friday', '2025-11-28 00:00:00', '2025-11-28 23:59:59', 50.00, 1),
('Cyber Monday', '2025-12-01 00:00:00', '2025-12-01 23:59:59', 45.00, 1),
('Promo Día del Padre', '2025-06-01 00:00:00', '2025-06-30 23:59:59', 18.00, 1),
('Promo Día de la Madre', '2025-05-01 00:00:00', '2025-05-31 23:59:59', 22.00, 1),
('Aniversario Tienda', '2025-04-10 00:00:00', '2025-04-20 23:59:59', 30.00, 1),
('Flash Sale', '2025-02-15 10:00:00', '2025-02-15 20:00:00', 40.00, 0),
('Fin de Temporada', '2025-07-01 00:00:00', '2025-07-15 23:59:59', 25.00, 1),
('Promo Estudiantes', '2025-08-01 00:00:00', '2025-08-31 23:59:59', 10.00, 1),
('Descuento Lealtad', '2025-09-01 00:00:00', '2025-09-30 23:59:59', 17.50, 1),
('2x1 Especial', '2025-10-01 00:00:00', '2025-10-05 23:59:59', 50.00, 1),
('Liquidación Express', '2025-03-25 00:00:00', '2025-03-27 23:59:59', 35.00, 0),
('Fiestas Patrias', '2025-09-15 00:00:00', '2025-09-20 23:59:59', 12.50, 1),
('Promo Navidad', '2025-12-15 00:00:00', '2025-12-31 23:59:59', 33.00, 1),
('Compra y Gana', '2025-06-10 00:00:00', '2025-06-12 23:59:59', 28.00, 0),
('Entrega Gratis', '2025-07-20 00:00:00', '2025-07-25 23:59:59', 8.00, 1),
('Testeo Interno', '2025-01-05 00:00:00', '2025-01-06 23:59:59', 5.00, 0);

-- INSERTS PROMOCIONES PRODUCTO (20)
INSERT INTO promociones_producto (id_producto_fk, id_promocion_fk) VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 3),
(3, 3),
(3, 4),
(4, 4),
(4, 5),
(5, 5),
(5, 6),
(6, 6),
(6, 7),
(7, 7),
(7, 8),
(8, 8),
(8, 9),
(9, 9),
(9, 10),
(10, 1),
(10, 3);

-- INSERTS USUARIOS (20)
INSERT INTO usuarios_bd (nombre_usuario, rol, fecha_creacion, activo) VALUES
('admin_sistema', 'Administrador_Sistema', '2025-01-01 09:00:00', 1),
('jefe_marketing', 'Gerente_Marketing', '2025-01-02 10:30:00', 1),
('analista_datos1', 'Analista_Datos', '2025-01-03 11:45:00', 1),
('empleado_inv1', 'Empleado_Inventario', '2025-01-04 14:20:00', 1),
('admin_respaldo', 'Administrador_Sistema', '2025-01-05 08:00:00', 1),
('marketing_aux', 'Gerente_Marketing', '2025-01-06 15:10:00', 0),
('analista_datos2', 'Analista_Datos', '2025-01-07 09:30:00', 1),
('inventario_user', 'Empleado_Inventario', '2025-01-08 13:40:00', 1),
('sys_admin2', 'Administrador_Sistema', '2025-01-09 10:05:00', 1),
('promo_manager', 'Gerente_Marketing', '2025-01-10 17:50:00', 1),
('data_expert', 'Analista_Datos', '2025-01-11 12:15:00', 1),
('stock_specialist', 'Empleado_Inventario', '2025-01-12 16:25:00', 1),
('root_access', 'Administrador_Sistema', '2025-01-13 07:55:00', 1),
('mk_lead', 'Gerente_Marketing', '2025-01-14 11:00:00', 1),
('data_team', 'Analista_Datos', '2025-01-15 10:00:00', 0),
('inv_master', 'Empleado_Inventario', '2025-01-16 09:25:00', 1),
('sys_support', 'Administrador_Sistema', '2025-01-17 18:00:00', 1),
('marketing_insights', 'Gerente_Marketing', '2025-01-18 14:10:00', 1),
('data_cruncher', 'Analista_Datos', '2025-01-19 13:45:00', 1),
('inventory_checker', 'Empleado_Inventario', '2025-01-20 08:55:00', 0);

-- INSERTS RESEÑAS (20)
INSERT INTO reseñas (calificacion, comentario, id_producto_fk, id_cliente_fk)
VALUES
(5, 'Excelente calidad, estoy muy satisfecho.', 1, 1),
(4, 'Buen producto aunque podría mejorar el empaque.', 2, 2),
(3, 'Aceptable, cumple con lo necesario.', 3, 3),
(5, 'Muy recomendable, volveré a comprar.', 4, 4),
(2, 'El producto llegó dañado.', 5, 5),
(4, 'Buena compra, relación calidad-precio correcta.', 1, 2),
(1, 'No funcionó como se esperaba.', 2, 3),
(5, 'Tal y como se describe, perfecto.', 3, 4),
(3, 'Regular, esperaba un poco más.', 4, 5),
(4, 'Me gustó, aunque tardó un poco el envío.', 5, 1),
(5, 'Sorprendido positivamente, gran calidad.', 1, 3),
(2, 'El material no parece muy resistente.', 2, 1),
(4, 'Cumple con todas las especificaciones.', 3, 5),
(3, 'Ni bien ni mal, simple.', 4, 2),
(1, 'Muy mala experiencia, no lo recomiendo.', 5, 4),
(5, 'Perfecto para lo que necesitaba.', 1, 4),
(4, 'El diseño es muy bonito.', 2, 5),
(3, 'Aceptable, precio razonable.', 3, 2),
(5, 'Calidad premium, excelente compra.', 4, 1),
(2, 'El vendedor no respondió mis dudas.', 5, 3);

-- TABLAS SIN INSERTTSS
-- PERMISOS_LOG
-- VENTAS_ARCHIVO
-- ALERTAS_STOCK
-- AUDITORIA_CLIENTES
-- AUDITORIA_PRECIOS
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
  descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (precio >= 0),
  iva DECIMAL(6,2) CHECK (iva BETWEEN 0 AND 100),
  costo DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (costo >= 0),
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  stock_minimo INT CHECK (stock_minimo >= 0),
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
  id_envio INT AUTO_INCREMENT PRIMARY KEY,
  direccion_envio VARCHAR(45) NOT NULL,
  codigo_rastreo VARCHAR(45) NOT NULL UNIQUE,
  fecha_envio DATETIME NOT NULL,
  fecha_entrega DATETIME,
  estado_envio ENUM('Preparando', 'Entransito', 'Entregado', 'Devuelto', 'Cancelado'),
  id_venta_fk INT NOT NULL,
  id_barrio_fk INT NOT NULL,
  FOREIGN KEY (id_venta_fk) REFERENCES ventas(id_venta),
  FOREIGN KEY (id_barrio_fk) REFERENCES barrios(id_barrio)
) ENGINE=InnoDB;

CREATE TABLE carritos (
  id_carrito INT AUTO_INCREMENT PRIMARY KEY,
  fecha_creacion DATETIME NOT NULL,
  fecha_cierre DATETIME NOT NULL,
  estado ENUM('Abierto', 'Convertido', 'Abandonado') NOT NULL,
  id_cliente_fk INT NOT NULL,
  FOREIGN KEY (id_cliente_fk) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE productos_carritos (
  id_producto_fk INT NOT NULL,
  id_carrito_fk INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  PRIMARY KEY (id_producto_fk, id_carrito_fk),
  FOREIGN KEY (id_producto_fk) REFERENCES productos(id_producto),
  FOREIGN KEY (id_carrito_fk) REFERENCES carritos(id_carrito)
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
  id_auditoria INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
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
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente', 'Resuelto') DEFAULT 'Pendiente',
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
('Colombia');

-- INSERTS PARA CIUDADES (20)
INSERT INTO ciudades (ciudad, num_dia, id_pais_fk) VALUES
('Bogotá', 1, 1),
('Medellín', 2, 1),
('Cali', 2, 1),
('Barranquilla', 3, 1),
('Bucaramanga', 2, 1),
('Cartagena', 3, 1),
('Pereira', 2, 1),
('Manizales', 2, 1),
('Cúcuta', 3, 1),
('Santa Marta', 3, 1),
('Ibagué', 2, 1),
('Villavicencio', 2, 1),
('Pasto', 4, 1),
('Montería', 3, 1),
('Neiva', 2, 1),
('Tunja', 1, 1),
('Popayán', 3, 1),
('Sincelejo', 3, 1),
('Armenia', 2, 1),
('Valledupar', 3, 1);

-- INSERTS PARA BARRIOS (20)
INSERT INTO barrios (barrio, id_ciudad_fk) VALUES
('Cabecera del Llano', 5),
('Provenza', 5),
('Real de Minas', 5),
('San Alonso', 5),
('Sotomayor', 5),
('Chapinero', 1),
('El Poblado', 2),
('San Fernando', 3),
('El Prado', 4),
('Cabecera del Llano', 5),
('Bocagrande', 6),
('La Riviera', 7),
('Los Alpes', 8),
('Palogrande', 9),
('Rodadero', 10),
('Cadiz', 11),
('La Esperanza', 12),
('Las Palmas', 13),
('La Castellana', 14),
('Campanario', 15),
('San Andrés', 16),
('La Ford', 17),
('La María', 18),
('La Clarita', 19),
('Doce de Octubre', 20);


-- INSERTS PARA PROVEEDORES (20)
INSERT INTO proveedores (nombre, email_contacto, telefono_contacto) VALUES
('Moda Andina S.A.S.', 'contacto@modaandina.com', '3174526890'),
('Estilo Urbano Ltda.', 'ventas@estilourbano.com', '3109823456'),
('Textiles del Norte', 'info@textilesnorte.co', '3167451230'),
('Eleganza Boutique', 'ventas@eleganzaboutique.com', '3136048927'),
('Belleza & Fragancias S.A.', 'contacto@byffragancias.com', '3142097856'),
('Artesanías de Colombia', 'ventas@artesaniascolombia.com', '3186001743'),
('Diseños del Caribe', 'contacto@discaribe.co', '3209875643'),
('CueroFino Ltda.', 'ventas@cuerofino.com', '3126009451'),
('Sombreros del Sol', 'atencion@sombrerosdelsol.com', '3115632048'),
('TextilVargas S.A.', 'ventas@textilvargas.com', '3154729681'),
('Distribuidora FashionLine', 'info@fashionline.co', '3168904321'),
('Perfumería Selecta', 'contacto@perfumeriaselecta.com', '3198756043'),
('Lencería IntimaLux', 'ventas@intimalux.com', '3126984750'),
('Accesorios Glamour', 'contacto@glamouracc.com', '3108963471'),
('Boutique Primavera', 'ventas@boutiqueprimavera.com', '3176054892'),
('Calzado Elite S.A.S.', 'soporte@calzadoelite.com', '3147098653'),
('Diseños Clásicos', 'ventas@disenosclasicos.co', '3158906742'),
('Joyas del Alma', 'info@joyasdelalma.com', '3125689470'),
('Fragancias del Mundo', 'contacto@fraganciasmundo.com', '3207658491'),
('Moda Express', 'servicio@modaexpress.co', '3137852049');


-- INSERTS PARA CATEGORIAS (20)
INSERT INTO categorias (nombre, descripcion) VALUES
('Ropa de Mujer', 'Blusas, vestidos, faldas, pantalones y chaquetas para dama.'),
('Ropa de Hombre', 'Camisas, pantalones, chaquetas y prendas casuales para caballero.'),
('Calzado', 'Zapatos, sandalias, botas y tacones para dama y caballero.'),
('Bolsos y Carteras', 'Bolsos, carteras y mochilas de moda.'),
('Joyería y Accesorios', 'Collares, aretes, pulseras, anillos y relojes.'),
('Perfumes y Fragancias', 'Perfumes para dama y caballero, colonias y sprays.'),
('Ropa Unisex', 'Prendas cómodas y modernas para cualquier género.'),
('Sombreros y Gorras', 'Accesorios de cabeza: gorras, sombreros y boinas.'),
('Bufandas y Guantes', 'Accesorios de temporada para invierno.'),
('Cinturones', 'Cinturones de cuero, tela y materiales sintéticos.'),
('Lencería y Pijamas', 'Ropa interior y prendas para dormir.'),
('Ropa Formal', 'Trajes, blazers, camisas elegantes y vestidos de gala.'),
('Ropa Casual', 'Prendas diarias y cómodas para uso cotidiano.'),
('Deportivos de Moda', 'Ropa y calzado deportivo con estilo.'),
('Bisutería Artesanal', 'Accesorios hechos a mano con materiales naturales.'),
('Ropa de Temporada', 'Colecciones especiales según la estación.'),
('Moda Juvenil', 'Estilos frescos y modernos para jóvenes.'),
('Moda Clásica', 'Prendas de corte tradicional y elegancia atemporal.'),
('Accesorios de Cuero', 'Productos de cuero: bolsos, cinturones y billeteras.'),
('Complementos de Moda', 'Pequeños detalles que completan el look.');

-- INSERTS PARA PRODUCTOS (20)
INSERT INTO productos 
(nombre, descripcion, precio, iva, costo, stock, stock_minimo, sku, fecha_creacion, activo, visto, peso, id_proveedor_fk, id_categoria_fk)
VALUES
('Blusa de Seda Femenina', 'Blusa elegante de seda color marfil con cuello en V.', 95000, 19, 60000, 20, 5, 'SKU001', NOW(), 1, 15, 0.200, 1, 1),
('Pantalón de Lino Beige', 'Pantalón de lino para dama, corte recto, ideal para clima cálido.', 120000, 19, 80000, 18, 4, 'SKU002', NOW(), 1, 10, 0.400, 2, 1),
('Camisa Casual Hombre Azul Marino', 'Camisa de algodón para hombre, manga larga y botones frontales.', 110000, 19, 70000, 25, 5, 'SKU003', NOW(), 1, 20, 0.350, 3, 2),
('Vestido Floral Verano', 'Vestido corto con estampado floral, tela ligera y fresca.', 145000, 19, 95000, 15, 3, 'SKU004', NOW(), 1, 35, 0.300, 1, 1),
('Chaqueta de Cuero Negra', 'Chaqueta clásica de cuero sintético con cierre frontal.', 280000, 19, 190000, 10, 2, 'SKU005', NOW(), 1, 25, 0.900, 4, 2),
('Zapatos de Tacón Alto', 'Tacones de charol color rojo, altura 8 cm.', 175000, 19, 115000, 14, 3, 'SKU006', NOW(), 1, 30, 0.800, 5, 3),
('Tenis Urbanos Unisex', 'Tenis blancos estilo urbano, suela antideslizante.', 220000, 19, 150000, 22, 5, 'SKU007', NOW(), 1, 22, 0.700, 5, 3),
('Bolso de Mano Cuero', 'Bolso pequeño de cuero genuino color café con cierre metálico.', 195000, 19, 120000, 12, 3, 'SKU008', NOW(), 1, 18, 0.600, 6, 4),
('Cartera de Tela Bordada', 'Cartera artesanal hecha a mano con bordado floral.', 85000, 19, 55000, 16, 3, 'SKU009', NOW(), 1, 25, 0.400, 6, 4),
('Collar de Plata con Dije', 'Collar fino de plata con dije en forma de corazón.', 135000, 19, 90000, 20, 4, 'SKU010', NOW(), 1, 28, 0.050, 7, 5),
('Aretes de Perlas Naturales', 'Par de aretes con perlas naturales y base de plata.', 95000, 19, 60000, 25, 5, 'SKU011', NOW(), 1, 20, 0.030, 7, 5),
('Pulsera de Cuero Doble', 'Pulsera artesanal de cuero trenzado con broche metálico.', 65000, 19, 40000, 30, 6, 'SKU012', NOW(), 1, 17, 0.060, 7, 5),
('Perfume Floral Dama 100ml', 'Fragancia floral fresca con notas de jazmín y rosa.', 180000, 19, 120000, 18, 3, 'SKU013', NOW(), 1, 40, 0.300, 8, 6),
('Perfume Amaderado Hombre 100ml', 'Fragancia masculina con notas amaderadas y cítricas.', 190000, 19, 125000, 20, 4, 'SKU014', NOW(), 1, 42, 0.300, 8, 6),
('Bufanda de Lana', 'Bufanda gruesa de lana color gris, ideal para invierno.', 78000, 19, 50000, 28, 5, 'SKU015', NOW(), 1, 25, 0.250, 9, 7),
('Gorra de Algodón Unisex', 'Gorra ajustable 100% algodón, varios colores.', 55000, 19, 35000, 35, 6, 'SKU016', NOW(), 1, 20, 0.150, 9, 8),
('Sombrero Panamá Original', 'Sombrero clásico tejido a mano en paja toquilla.', 160000, 19, 100000, 10, 2, 'SKU017', NOW(), 1, 18, 0.200, 10, 8),
('Reloj de Pulsera Elegante', 'Reloj analógico con correa de cuero y caja metálica.', 250000, 19, 170000, 14, 3, 'SKU018', NOW(), 1, 30, 0.180, 11, 5),
('Cinturón de Cuero Negro', 'Cinturón de cuero genuino con hebilla metálica.', 88000, 19, 55000, 20, 4, 'SKU019', NOW(), 1, 25, 0.250, 11, 9),
('Sandalias de Cuero Dama', 'Sandalias cómodas con tiras de cuero y suela antideslizante.', 125000, 19, 85000, 16, 3, 'SKU020', NOW(), 1, 20, 0.500, 5, 3);

-- INSERTS PARA CLIENTES (20)
INSERT INTO clientes (nombre, apellido, email, telefono_contacto, contrasena, fecha_registro, fecha_nacimiento, id_barrio_fk, total_gastado) VALUES
('Juan', 'Pipo', 'juan.pipo1@mail.com', '300000001', 'pass123', NOW(), '1990-05-10', 1, 150.00),
('Ana', 'Lecoq', 'ana.lecoq2@mail.com', '300000002', 'Ana2025', NOW(), '1988-08-20', 2, 200.00),
('Luis', 'Newton', 'luis.newton3@mail.com', '300000003', 'Lui$Newton1', NOW(), '1995-02-15', 3, 300.00),
('Sofía', 'Newt', 'sofia.newt4@mail.com', '300000004', 'Sofi4fun!', NOW(), '1992-09-07', 4, 120.50),
('Carlos', 'Blanco', 'carlos.blanco5@mail.com', '300000005', 'carlos87', NOW(), '1987-10-11', 5, 500.00),
('Sebastian', 'Montoya', 'sebastian.montoya6@mail.com', '300000006', 'Seb2025$', NOW(), '1999-12-01', 6, 250.00),
('Pedro', 'Sánchez', 'pedro.sanchez7@mail.com', '300000007', 'PedroS123', NOW(), '1989-06-29', 7, 175.00),
('Lucía', 'Hernández', 'lucia.hernandez8@mail.com', '300000008', 'Lucia!H8', NOW(), '1996-03-03', 8, 220.00),
('Miguel', 'Castro', 'miguel.castro9@mail.com', '300000009', 'miguel09', NOW(), '1985-01-21', 9, 350.00),
('Laura', 'Gómez', 'laura.gomez10@mail.com', '300000010', 'LauraG20', NOW(), '2000-04-14', 10, 90.00),
('Diego', 'Morales', 'diego.morales11@mail.com', '300000011', 'DiegoM@11', NOW(), '1993-07-16', 11, 400.00),
('Valentina', 'Flores', 'valentina.flores12@mail.com', '300000012', 'ValenF123', NOW(), '1997-11-09', 12, 320.40),
('Tatiana', 'Ruiz', 'tatiana.ruiz13@mail.com', '300000013', 'TatiRu!z', NOW(), '1986-12-25', 13, 180.00),
('Paula', 'Ortiz', 'paula.ortiz14@mail.com', '300000014', 'Paula89', NOW(), '1991-05-05', 14, 230.00),
('Brandon', 'Blanco', 'brandon.blanco15@mail.com', '300000015', 'B!randon15', NOW(), '1994-09-17', 15, 280.00),
('Camila', 'Vargas', 'camila.vargas16@mail.com', '300000016', 'Camila2025', NOW(), '1998-10-30', 16, 350.00),
('Ángel', 'Suárez', 'angel.suarez17@mail.com', '300000017', 'AngelS@87', NOW(), '1987-04-08', 17, 420.00),
('Daniela', 'Molina', 'daniela.molina18@mail.com', '300000018', 'Dani123', NOW(), '1995-02-18', 18, 150.00),
('Felipe', 'Guerra', 'felipe.guerra19@mail.com', '300000019', 'Fel!pe19', NOW(), '1989-08-01', 19, 290.90),
('Alejandra', 'Blanco', 'alejandra.blanco20@mail.com', '300000020', 'AleBlanco20', NOW(), '1993-03-10', 20, 510.00);

-- INSERTS PARA SUCURSALES (20)
INSERT INTO sucursales (nombre, direccion, telefono, id_barrio_fk) VALUES
('Boutique Eleganza Bogotá', 'Cra 15 #93-20', '6015551001', 1),
('Boutique Estilo & Moda Medellín', 'Cra 43A #8-15', '6045552001', 4),
('Boutique Rosa Chic Cali', 'Av 6N #21-45', '6025553001', 8),
('Boutique Marina Barranquilla', 'Cra 54 #72-10', '6055554001', 10),
('Boutique Glam Bucaramanga', 'Cl 36 #41-50', '6075555001', 13),
('Boutique Bocagrande Cartagena', 'Cra 3 #9-25', '6055556001', 16),
('Boutique Riviera Pereira', 'Av. Circunvalar #18-30', '6065557001', 17),
('Boutique Manizales Chic', 'Cl 22 #23-45', '6065558001', 18),
('Boutique Rodadero Style', 'Cl 6 #1-30', '6055559001', 19),
('Boutique Cúcuta Moda', 'Av. Libertadores #12E-30', '6075559011', 20);


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
('2025-01-13 19:26:17', 'Cancelado', 27.99, 2, 2),
('2025-01-05 14:23:10', 'Entregado', 89.99, 1, 1),
('2025-03-12 11:15:40', 'Entregado', 120.50, 1, 1),
('2025-04-09 09:30:25', 'Entregado', 99.00, 1, 1),
('2025-02-10 17:42:55', 'Entregado', 65.00, 2, 1),
('2025-05-03 13:08:20', 'Entregado', 210.99, 2, 1),
('2025-01-22 08:10:45', 'Entregado', 150.00, 3, 2),
('2025-02-18 10:55:12', 'Entregado', 200.00, 3, 2),
('2025-06-05 19:20:33', 'Entregado', 180.00, 3, 2),
('2025-03-01 12:50:17', 'Entregado', 300.00, 4, 2),
('2025-07-14 16:22:09', 'Entregado', 125.00, 4, 2),
('2025-04-10 15:00:00', 'Entregado', 50.00, 5, 3),
('2025-05-18 18:45:33', 'Entregado', 95.00, 5, 3),
('2025-08-02 09:25:40', 'Entregado', 130.00, 5, 3);


-- INSERTS PARA DETALLE_VENTAS (5)
INSERT INTO detalle_ventas (id_venta_fk, id_producto_fk, cantidad, precio_unitario_congelado, iva_porcentaje_aplicado, subtotal, total_linea)
VALUES
(1, 1, 2, 45000, 19, 90000, 107100),
(2, 2, 1, 120000, 19, 120000, 142800),
(3, 4, 3, 10000, 19, 30000, 35700),
(4, 5, 2, 95000, 19, 190000, 226100),
(5, 3, 1, 110000, 19, 110000, 130900); 

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
INSERT INTO productos_carritos (id_producto_fk, id_carrito_fk, cantidad) VALUES
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
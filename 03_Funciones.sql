
-- FUNCIONES PARA MI TIENDA ONLINE


USE `proyecto_ecommerce`;

-- 1. fn_CalcularTotalVenta
-- Esta funcion calcula el total de una venta con IVA

DELIMITER $$
CREATE FUNCTION fn_CalcularTotalVenta(
    p_cantidad INT,
    p_precio_unitario DECIMAL(10,2),
    p_iva_porcentaje DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_iva DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    
    -- Primero calculo el subtotal
    SET v_subtotal = p_cantidad * p_precio_unitario;
    
    -- Luego calculo el IVA
    SET v_iva = v_subtotal * (p_iva_porcentaje / 100);
    
    -- Finalmente sumo todo
    SET v_total = v_subtotal + v_iva;
    
    RETURN v_total;
END$$
DELIMITER ;

-- 2. fn_VerificarDisponibilidadStock
-- Para verificar si hay suficiente stock de un producto

DELIMITER $$
CREATE FUNCTION fn_VerificarDisponibilidadStock(
    p_id_producto INT,
    p_cantidad_solicitada INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_stock_disponible DECIMAL(10,2);
    DECLARE v_disponible BOOLEAN DEFAULT FALSE;
    
    -- Busco el stock del producto
    SELECT stock INTO v_stock_disponible
    FROM productos
    WHERE id_producto = p_id_producto AND activo = 1;
    
    -- Verifico si hay suficiente
    IF v_stock_disponible IS NOT NULL AND v_stock_disponible >= p_cantidad_solicitada THEN
        SET v_disponible = TRUE;
    END IF;
    
    RETURN v_disponible;
END$$
DELIMITER ;

-- 3. fn_ObtenerPrecioProducto
-- Para obtener el precio de un producto

DELIMITER $$
CREATE FUNCTION fn_ObtenerPrecioProducto(
    p_id_producto INT,
    p_fecha_consulta DATETIME
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    
    -- Busco el precio del producto
    SELECT precio INTO v_precio
    FROM productos
    WHERE id_producto = p_id_producto AND activo = 1;
    
    -- Si no encuentro el producto, devuelvo 0
    IF v_precio IS NULL THEN
        SET v_precio = 0;
    END IF;
    
    RETURN v_precio;
END$$
DELIMITER ;

-- 4. fn_CalcularEdadCliente
-- Para calcular la edad de un cliente

DELIMITER $$
CREATE FUNCTION fn_CalcularEdadCliente(
    p_fecha_nacimiento DATE
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_edad INT;
    
    -- Calculo la edad si tengo la fecha de nacimiento
    IF p_fecha_nacimiento IS NOT NULL THEN
        SET v_edad = TIMESTAMPDIFF(YEAR, p_fecha_nacimiento, CURDATE());
    ELSE
        SET v_edad = NULL;
    END IF;
    
    RETURN v_edad;
END$$
DELIMITER ;

-- 5. fn_FormatearNombreCompleto
-- Para formatear nombres de manera consistente

DELIMITER $$
CREATE FUNCTION fn_FormatearNombreCompleto(
    p_nombre VARCHAR(45),
    p_apellido VARCHAR(45)
) RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_nombre_completo VARCHAR(100);
    
    -- Uno el nombre y apellido con formato correcto
    SET v_nombre_completo = CONCAT(
        UPPER(LEFT(p_nombre, 1)), 
        LOWER(SUBSTRING(p_nombre, 2)), 
        ' ', 
        UPPER(LEFT(p_apellido, 1)), 
        LOWER(SUBSTRING(p_apellido, 2))
    );
    
    RETURN v_nombre_completo;
END$$
DELIMITER ;

-- 6. fn_EsClienteNuevo
-- Para saber si un cliente es nuevo

DELIMITER $$
CREATE FUNCTION fn_EsClienteNuevo(
    p_id_cliente INT,
    p_dias_limite INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_fecha_registro DATETIME;
    DECLARE v_es_nuevo BOOLEAN DEFAULT FALSE;
    
    -- Busco cuando se registro el cliente
    SELECT fecha_registro INTO v_fecha_registro
    FROM clientes
    WHERE id_cliente = p_id_cliente;
    
    -- Veo si es nuevo segun los dias que me pasan
    IF v_fecha_registro IS NOT NULL AND 
       DATEDIFF(CURDATE(), v_fecha_registro) <= p_dias_limite THEN
        SET v_es_nuevo = TRUE;
    END IF;
    
    RETURN v_es_nuevo;
END$$
DELIMITER ;

-- 7. fn_CalcularCostoEnvio
-- Para calcular cuanto cuesta enviar un paquete

DELIMITER $$
CREATE FUNCTION fn_CalcularCostoEnvio(
    p_peso_total DECIMAL(5,3),
    p_distancia_km INT,
    p_tipo_envio ENUM('Estandar', 'Express', 'Premium')
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_costo_base DECIMAL(10,2) DEFAULT 0;
    DECLARE v_costo_por_kg DECIMAL(10,2) DEFAULT 0;
    DECLARE v_costo_por_km DECIMAL(10,2) DEFAULT 0;
    DECLARE v_costo_total DECIMAL(10,2);
    
    -- Segun el tipo de envio pongo diferentes precios
    CASE p_tipo_envio
        WHEN 'Estandar' THEN
            SET v_costo_base = 5.00;
            SET v_costo_por_kg = 2.50;
            SET v_costo_por_km = 0.15;
        WHEN 'Express' THEN
            SET v_costo_base = 10.00;
            SET v_costo_por_kg = 4.00;
            SET v_costo_por_km = 0.25;
        WHEN 'Premium' THEN
            SET v_costo_base = 15.00;
            SET v_costo_por_kg = 6.00;
            SET v_costo_por_km = 0.35;
    END CASE;
    
    -- Calculo el costo total
    SET v_costo_total = v_costo_base + 
                       (p_peso_total * v_costo_por_kg) + 
                       (p_distancia_km * v_costo_por_km);
    
    -- Si es muy barato, pongo un minimo
    IF v_costo_total < 3.00 THEN
        SET v_costo_total = 3.00;
    END IF;
    
    RETURN v_costo_total;
END$$
DELIMITER ;
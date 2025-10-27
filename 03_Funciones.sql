






















































































































































































































-- fn_CalcularTotalVenta: Calcula el monto total de una venta específica.
-- fn_VerificarDisponibilidadStock: Valida si hay stock suficiente para un producto.
-- fn_ObtenerPrecioProducto: Devuelve el precio actual de un producto.
-- fn_CalcularEdadCliente: Calcula la edad de un cliente a partir de su fecha de nacimiento.
-- fn_FormatearNombreCompleto: Devuelve el nombre y apellido de un cliente en un formato estandarizado.
-- fn_EsClienteNuevo: Devuelve VERDADERO si un cliente realizó su primera compra en los últimos 30 días.
-- fn_CalcularCostoEnvio: Calcula el costo de envío basado en el peso total de los productos de una venta.

-- fn_AplicarDescuento: Aplica un porcentaje de descuento a un monto dado.
DELIMITER $$

CREATE FUNCTION fn_AplicarDescuento(
    precio_original DECIMAL(10,2),
    descuento_porcentaje DECIMAL(6,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE precio_final DECIMAL(10,2);

    IF descuento_porcentaje < 0 THEN
        SET descuento_porcentaje = 0;
    END IF;

    IF descuento_porcentaje > 100 THEN
        SET descuento_porcentaje = 100;
    END IF;

    SET precio_final = precio_original - (precio_original * (descuento_porcentaje / 100));

    RETURN precio_final;
END$$

DELIMITER;

SELECT fn_AplicarDescuento (100, 15) AS precio_con_descuento;

-- fn_ObtenerUltimaFechaCompra: Devuelve la fecha de la última compra de un cliente.
DELIMITER $$

CREATE FUNCTION fn_ObtenerUltimaFechaCompra(
    p_id_cliente INT
)
RETURNS DATETIME
DETERMINISTIC
BEGIN
    DECLARE ultima_fecha DATETIME;

    SELECT MAX(fecha_venta)
    INTO ultima_fecha
    FROM ventas
    WHERE id_cliente_fk = p_id_cliente;

    RETURN ultima_fecha;
END$$

DELIMITER;

SELECT fn_ObtenerUltimaFechaCompra (3) AS ultima_compra;

-- fn_ValidarFormatoEmail: Comprueba si una cadena de texto tiene un formato de correo electrónico válido.
DELIMITER $$

CREATE FUNCTION fn_ValidarFormatoEmail(
    p_email VARCHAR(100)
)
RETURNS TINYINT
DETERMINISTIC
BEGIN
    IF p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$' THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END$$

DELIMITER;

SELECT fn_ValidarFormatoEmail ('juan.pipo1@mail.com') AS valido;

SELECT fn_ValidarFormatoEmail ('cliente@email') AS valido;

-- fn_ObtenerNombreCategoria: Devuelve el nombre de la categoría a partir del ID de un producto.
DELIMITER $$

CREATE FUNCTION fn_ObtenerNombreCategoria(
    p_id_categoria INT
)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE v_nombre_categoria VARCHAR(50);

    SELECT nombre
    INTO v_nombre_categoria
    FROM categorias
    WHERE id_categoria = p_id_categoria
    LIMIT 1;

    RETURN v_nombre_categoria;
END$$

DELIMITER;

SELECT fn_ObtenerNombreCategoria (3) AS categoria;

-- fn_ContarVentasCliente: Cuenta el número total de compras realizadas por un cliente.
DELIMITER $$

CREATE FUNCTION fn_ContarVentasCliente(
    p_id_cliente INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_total_ventas INT;

    SELECT COUNT(*)
    INTO v_total_ventas
    FROM ventas
    WHERE id_cliente_fk = p_id_cliente;

    RETURN v_total_ventas;
END$$

DELIMITER;

SELECT fn_ContarVentasCliente (5) AS total_ventas;

-- fn_CalcularDiasDesdeUltimaCompra: Devuelve el número de días transcurridos desde la última compra de un cliente.
-- 12
DELIMITER $$

CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(
    p_id_cliente INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_dias INT;

    SELECT DATEDIFF(CURRENT_DATE, MAX(fecha_venta))
    INTO v_dias
    FROM ventas
    WHERE id_cliente_fk = p_id_cliente;

    RETURN v_dias;
END$$

DELIMITER;

SELECT fn_CalcularDiasDesdeUltimaCompra (4) AS dias_inactivo;

-- fn_DeterminarEstadoLealtad: Asigna un estado de lealtad (Bronce, Plata, Oro) a un cliente según su gasto total.

DELIMITER $$

CREATE FUNCTION fn_DeterminarEstadoLealtad(p_idCliente INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE totalVentas INT;

    SELECT COUNT(*) INTO totalVentas
    FROM ventas
    WHERE id_cliente_fk = p_idCliente;

    IF totalVentas = 0 THEN
        RETURN 'Nuevo';
    ELSEIF totalVentas BETWEEN 1 AND 5 THEN
        RETURN 'Recurrente';
    ELSE
        RETURN 'VIP';
    END IF;
END $$

DELIMITER;

SELECT fn_DeterminarEstadoLealtad (6) AS lealtad;

-- fn_GenerarSKU: Genera un código de producto (SKU) único basado en su nombre y categoría.
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_GenerarSKU(nombre_producto VARCHAR(100), nombre_categoria VARCHAR(100))
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE sku VARCHAR(50);
    SET sku = CONCAT(
        UPPER(LEFT(nombre_categoria, 3)), '-', 
        UPPER(LEFT(nombre_producto, 3)), '-', 
        LPAD(FLOOR(RAND() * 10000), 4, '0')
    );
    RETURN sku;
END$$

DELIMITER;

SELECT fn_GenerarSKU ( 'Zapatos Deportivos', 'Calzado' ) AS SKU;

-- fn_CalcularIVA: Calcula el impuesto (IVA) sobre el total de una venta.
DELIMITER $$

CREATE FUNCTION fn_CalcularIVA(idVenta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_iva DECIMAL(10,2);
    SELECT 
        SUM((subtotal * iva_porcentaje_aplicado) / 100)
    INTO total_iva
    FROM detalle_ventas
    WHERE id_venta_fk = idVenta;
    RETURN IFNULL(total_iva, 0);
END$$

DELIMITER;

SELECT
    v.id_venta,
    v.total AS Total_Venta,
    fn_CalcularIVA (v.id_venta) AS IVA_Total
FROM ventas v;
-- fn_ObtenerStockTotalPorCategoria: Suma el stock de todos los productos de una categoría.
DELIMITER $$

CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(idCategoria INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_stock INT;
    SELECT SUM(stock)
    INTO total_stock
    FROM productos
    WHERE id_categoria_fk = idCategoria;
    RETURN IFNULL(total_stock, 0);
END$$

DELIMITER;

SELECT
    c.id_categoria,
    c.nombre,
    fn_ObtenerStockTotalPorCategoria (c.id_categoria) AS Stock_Total
FROM categorias c;
-- fn_EstimarFechaEntrega: Calcula la fecha estimada de entrega de un pedido según la ubicación del cliente.
DELIMITER $$

CREATE FUNCTION fn_EstimarFechaEntrega(idCliente INT)
RETURNS DATETIME
DETERMINISTIC
BEGIN
    DECLARE dias_envio INT;
    DECLARE fecha_estimada DATETIME;
    SELECT c.num_dia
    INTO dias_envio
    FROM clientes cl
    INNER JOIN barrios b ON cl.id_barrio_fk = b.id_barrio
    INNER JOIN ciudades c ON b.id_ciudad_fk = c.id_ciudad
    WHERE cl.id_cliente = idCliente;
    SET dias_envio = IFNULL(dias_envio, 3);
    SET fecha_estimada = DATE_ADD(NOW(), INTERVAL dias_envio DAY);
    RETURN fecha_estimada;
END$$

DELIMITER;

SELECT
    cl.nombre AS Nombre,
    cl.apellido AS Apellido,
    ci.ciudad AS Ciudad_Destino,
    fn_EstimarFechaEntrega (cl.id_cliente) AS Fecha_Estimada_Entrega
FROM
    clientes cl
    INNER JOIN barrios b ON cl.id_barrio_fk = b.id_barrio
    INNER JOIN ciudades ci ON b.id_ciudad_fk = ci.id_ciudad;

-- fn_ConvertirMoneda: Convierte un monto a otra moneda usando una tasa de cambio fija.
DELIMITER $$

CREATE FUNCTION fn_ConvertirMoneda(
    monto DECIMAL(10,2),
    tasa_cambio DECIMAL(10,4)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE monto_convertido DECIMAL(10,2);
    SET monto_convertido = monto / tasa_cambio;
    RETURN ROUND(monto_convertido, 2);
END$$

DELIMITER;

SELECT fn_ConvertirMoneda (100000, 4000) AS Valor_En_Dolares;

SELECT
    v.id_venta,
    v.total AS Total_COP,
    fn_ConvertirMoneda (v.total, 4000) AS Total_USD
FROM ventas v
WHERE
    v.estado = 'Entregado';

-- fn_ValidarComplejidadContraseña: Verifica si una contraseña cumple con los criterios de seguridad (longitud, caracteres, etc.).

DELIMITER $$

CREATE FUNCTION IF NOT EXISTS fn_ValidarContraseñaCliente(idCliente INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE contrasena VARCHAR(45);
    DECLARE mensaje VARCHAR(50);

    SELECT c.contrasena
    INTO contrasena
    FROM clientes c
    WHERE c.id_cliente = idCliente;

    IF CHAR_LENGTH(contrasena) < 8 THEN
        SET mensaje = 'Demasiado corta';
    ELSEIF contrasena NOT REGEXP '[A-Z]' THEN
        SET mensaje = 'Debe tener una mayúscula';
    ELSEIF contrasena NOT REGEXP '[0-9]' THEN
        SET mensaje = 'Debe tener un número';
    ELSEIF contrasena NOT REGEXP '[!@#$%^&*(),.?":{}|<>]' THEN
        SET mensaje = 'Debe tener un carácter especial';
    ELSE
        SET mensaje = 'Contraseña válida';
    END IF;
    RETURN mensaje;
END$$

DELIMITER;

SELECT
    nombre,
    apellido,
    fn_ValidarContraseñaCliente (id_cliente) AS Estado_Contraseña
FROM clientes;
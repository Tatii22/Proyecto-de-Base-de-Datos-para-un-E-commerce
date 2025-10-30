USE `proyecto_ecommerce`;
--Un único script .sql que contenga las sentencias ALTER TABLE para añadir los nuevos campos, 
-- el CREATE TRIGGER para mantener actualizada la fecha_ultima_compra y 
-- el CREATE EVENT para evt_desactivar_cuentas_inactivas.

-----------------------
-- desactivar automáticamente las cuentas de clientes que no han realizado ninguna compra en los últimos dos años.
ALTER TABLE clientes
ADD COLUMN fecha_ultima_compra DATETIME; -- Se agrega campo para registrar la utima fecha de la compra del cliente

ALTER TABLE clientes
ADD COLUMN activo BOOLEAN DEFAULT TRUE; -- Se agrega campo para indicar que el cliente esta activo o inactivo


DELIMITER $$
CREATE TRIGGER trg_update_last_purchase_date -- Se crea trigger para una vez que se realize una venta se guarde la fecha en clientes
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET fecha_ultima_compra = NEW.fecha_venta
    WHERE id_cliente = NEW.id_cliente_fk;
END
$$   
DELIMITER ;

INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES 
(NOW(),'Entregado',150.30, 2, 1); -- Se ingresa nuevas ventas

-- Crea un evento programado llamado evt_desactivar_cuentas_inactivas.
SET GLOBAL event_scheduler = ON;
SHOW VARIABLES LIKE 'event_scheduler';

DELIMITER $$
CREATE EVENT evt_desactivar_cuentas_inactivas
ON SCHEDULE EVERY 1 MONTH --  Debe ejecutarse una vez al mes.
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE
        clientes
    SET activo = FALSE -- se cambia a false y el cliente queda inactivo
    WHERE fecha_ultima_compra < DATE_SUB(NOW(), INTERVAL 2 YEAR); -- Si la ultima compra fue hace mas de 2 años
END$$
DELIMITER ;




















--- PRUEBA EVENTO A 1 MINUTO
INSERT INTO ventas (fecha_venta, estado, total, id_cliente_fk, id_sucursal_fk)
VALUES 
('2020-01-05 14:23:10','Entregado',800.30, 1, 1);
DELIMITER $$
CREATE EVENT evt_desactivar_cuentas_inactivas_PRUEBA
ON SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE
        clientes
    SET activo = FALSE
    WHERE fecha_ultima_compra < DATE_SUB(NOW(), INTERVAL 2 YEAR);
END$$
DELIMITER ;


-- Adjunto repositorio de notas: http://github.com/Tatii22/APUNTES-SOFTWARE-TatianaVillamizar/blob/main/SQL%20II.md
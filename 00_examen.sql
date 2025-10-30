USE `proyecto_ecommerce`;

-- Crea un evento programado llamado evt_desactivar_cuentas_inactivas.

CREATE EVENT evt_desactivar_cuentas_inactivas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP


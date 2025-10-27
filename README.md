# 🛍️ Proyecto de Base de Datos para un E-Commerce

## 📋 Descripción General
Este proyecto implementa el **diseño, desarrollo y gestión de una base de datos completa** para un sistema de comercio electrónico (E-Commerce).  
El objetivo es simular un entorno real que permita administrar clientes, productos, ventas, inventarios, proveedores y análisis de datos, con especial atención a la **seguridad, automatización y optimización** mediante triggers, procedimientos almacenados, funciones, roles y eventos programados.

---

## 🧱 Estructura del Proyecto

### 🔹Tablas Principales
- **clientes** – información personal y de contacto de los clientes.  
- **productos** – catálogo de artículos disponibles.  
- **categorías** – clasificación de los productos.  
- **proveedores** – datos de los proveedores y sus productos asociados.  
- **ventas** – registro de transacciones realizadas.  
- **detalle_ventas** – relación entre ventas y productos.  
- **reseñas** – opiniones y calificaciones de clientes.  
- **usuarios_bd** – gestión de usuarios internos y roles.  
- **alertas_stock** – control automático de inventarios.  
- **permisos_log** – auditoría de cambios en permisos.

---
## ⚙️ Requisitos Técnicos
- **Motor de Base de Datos:** MySQL 8.0 o superior  
- **Herramientas Recomendadas:**  
  - MySQL Workbench  
  - Docker (opcional)  
  - Git / GitHub para control de versiones  

---
## 🚀 Cómo Usar el Proyecto

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/<tu-usuario>/Proyecto-de-Base-de-Datos-para-un-E-commerce.git
   cd Proyecto-de-Base-de-Datos-para-un-E-commerce
   ```

2. **Importar el script principal** en MySQL Workbench o terminal:
   ```sql
   SOURCE proyecto_ecommerce.sql;
   ```

3. **Probar procedimientos y triggers:**  
   Inserta registros de prueba en tablas como `clientes`, `productos`, `ventas`, etc., y observa el funcionamiento de las automatizaciones.

---

## 🧩 Autores

👩‍💻 **Claudia Tatiana Villamizar Márquez**  
👨‍💻 **Sebastián Montoya Ochoa**  
👨‍💻 **Bramdon Steven Blanco**
📧 *Desarrolladora de Base de Datos y Estudiante de Programación*  
📍 *Bucaramanga, Colombia*
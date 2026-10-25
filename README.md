# api.3

# Taller ADSO 03 - API de pedidos con FastAPI y MySQL

Este proyecto implementa clientes, productos y pedidos relacionados. La creación de pedido guarda su encabezado y detalles, conserva el precio de venta y descuenta inventario dentro de una transacción MySQL.

## 1. Requisitos

- Python 3.10 o superior.
- MySQL o MariaDB iniciado.
- Git.
- PowerShell para los comandos de Windows.

## 2. Preparar MySQL

1. En MySQL Workbench o phpMyAdmin, ejecuta `sql/01_esquema.sql` completo.
2. Ejecuta `sql/02_datos_prueba.sql` una sola vez.
3. Verifica que existen dos clientes y tres productos con `SELECT * FROM tienda_adso.clientes;` y `SELECT * FROM tienda_adso.productos;`.
4. Con un usuario administrador, crea el usuario de la API y otorga permisos. Cambia la contraseña:

```sql
CREATE USER IF NOT EXISTS 'api_adso'@'localhost' IDENTIFIED BY 'ClaveLocalFuerte123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON tienda_adso.* TO 'api_adso'@'localhost';
```

## 3. Preparar Python desde PowerShell

Abre PowerShell en la carpeta del proyecto:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
notepad .env
```

En `.env`, coloca la clave del usuario MySQL `api_adso`. No compartas ni subas ese archivo. `.gitignore` ya excluye `.env` y `.venv`.

Si PowerShell bloquea la activación, ejecuta `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` en esa ventana y vuelve a ejecutar el comando de activación.

## Iniciar y detener la API con PowerShell

Desde la raíz del proyecto, inicia el servidor en segundo plano:

```powershell
.\iniciar_api.ps1
```

Abre el panel en <http://127.0.0.1:8000/>. En “Crear pedido” selecciona un cliente, agrega productos desde listas y define sus cantidades; el panel arma el cuerpo que necesita la API automáticamente. Para apagarla:

```powershell
.\detener_api.ps1
```

Los mensajes del servidor quedan en `api.log` y `api-error.log`. Si Windows bloquea la ejecución del script, permite scripts solo en la ventana actual y vuelve a iniciarlo:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\iniciar_api.ps1
```

## 4. Abrir el panel web y ejecutar la API

Inicia la API y abre <http://127.0.0.1:8000/> para ver el panel web. Desde allí puedes consultar clientes, productos y pedidos; registrar clientes y productos; crear pedidos y consultar su detalle. Swagger sigue disponible en <http://127.0.0.1:8000/docs>.

## 5. Ejecutar y probar

Desde la raíz del proyecto, con `.venv` activo:

```powershell
fastapi dev app/main.py
```

Abre <http://127.0.0.1:8000/docs>. Prueba `GET /clientes`, `GET /productos`, crea un cliente y producto, y luego crea un pedido con:

```json
{
  "cliente_id": 1,
  "items": [
    {"producto_id": 1, "cantidad": 2},
    {"producto_id": 2, "cantidad": 1}
  ]
}
```

Con los datos semilla el total esperado es 150000. Consulta `GET /pedidos/{id}` y revisa en MySQL que el stock bajó. Intenta crear un pedido con stock insuficiente: debe responder 409 y revertir toda la operación. Los errores principales son 404 para registros inexistentes, 409 para correo duplicado o stock insuficiente y 422 para datos inválidos.

## 6. Subir a GitHub

Crea un repositorio vacío en GitHub. En PowerShell, desde la raíz del proyecto, sustituye la URL por la de tu repositorio:

```powershell
git init
git status
git add .
git status
```

Antes de confirmar, revisa que `.env` y `.venv` no estén listados. Después:

```powershell
git commit -m "Completa taller ADSO FastAPI y MySQL"
git branch -M main
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
git push -u origin main
```

Si `origin` ya existe, inspecciónalo con `git remote -v` y actualízalo con `git remote set-url origin URL_DEL_REPOSITORIO`.

## 7. ZIP de entrega

La guía académica también solicita un ZIP. Desde la carpeta raíz del proyecto:

```powershell
Compress-Archive -Path app, sql, requirements.txt, README.md, .env.example -DestinationPath entrega_tienda_adso.zip
```

No incluyas `.env` ni `.venv`. Guarda capturas de Swagger, el pedido exitoso, detalle, stock antes/después, consultas JOIN y el rechazo por falta de stock.

## 8. Cómo se distribuye la lógica

- `app/main.py`: crea la aplicación, sirve el panel web e incluye los routers.
- `app/database.py`: conecta con MySQL y confirma o revierte transacciones.
- `app/schemas.py`: valida cuerpos y parámetros recibidos.
- `app/routers/clientes.py`: consulta y crea clientes.
- `app/routers/productos.py`: consulta, crea productos y cambia stock.
- `app/routers/pedidos.py`: crea pedidos atómicos y consulta encabezado y detalle.
- `app/static/index.html`: interfaz web para ver y administrar clientes, productos y pedidos.
- `sql/`: define tablas y datos de ejemplo.

La tabla `detalle_pedidos` representa la relación muchos a muchos entre pedidos y productos. Las claves foráneas comprueban relaciones válidas. InnoDB permite que el pedido, sus detalles y el descuento de stock se confirmen juntos o se reviertan juntos.



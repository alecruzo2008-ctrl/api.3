# Guía manual del taller ADSO con FastAPI, MySQL y Git

Esta guía explica cómo reconstruir el proyecto paso a paso en Windows, probarlo localmente y registrar avances con commits pequeños. El proyecto usa la base `tienda_adso_1`, FastAPI, PyMySQL y una página HTML servida desde FastAPI.

## Antes de comenzar

Necesitas Python 3.10 o superior, Git y MySQL Server o MariaDB iniciado. Abre PowerShell en la carpeta donde quieras crear el proyecto. En el taller ya existe `C:\Users\nexus\Desktop\tienda_adso`; si vas a repetirlo desde cero, crea otra carpeta para no sobrescribir ese trabajo.

## 1. Crear la estructura

```powershell
mkdir tienda_adso
cd tienda_adso
mkdir app, app\routers, app\static, sql
New-Item app\__init__.py, app\routers\__init__.py -ItemType File
```

La estructura final debe contener:

```text
tienda_adso/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── database.py
│   ├── schemas.py
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── clientes.py
│   │   ├── productos.py
│   │   └── pedidos.py
│   └── static/
│       └── index.html
├── sql/
│   ├── 01_esquema.sql
│   └── 02_datos_prueba.sql
├── requirements.txt
├── .env.example
├── .env
├── .gitignore
├── iniciar_api.ps1
├── detener_api.ps1
└── README.md
```

Crea cada archivo y copia su contenido desde el proyecto existente. La guía describe qué va en cada uno.

## 2. Preparar Git antes de agregar el código

Crea `.gitignore` con estas reglas para no subir el entorno virtual, los secretos ni los logs:

```gitignore
.venv/
__pycache__/
*.py[cod]
.env
.api.pid
api.log
api-error.log
```

Inicializa el repositorio local:

```powershell
git init
git branch -M main
git status
```

### Conectar con GitHub

Para una reconstrucción desde cero, crea un repositorio vacío en GitHub. No lo inicialices con README ni con archivos, porque los crearás localmente. Conecta el remoto una sola vez:

```powershell
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
git remote -v
```

Cambia la URL por la de tu repositorio. Si ya aparece `origin`, no la agregues de nuevo; usa `git remote -v` para verificarla. El repositorio `api.3` ya tiene historial y archivos. Para seguir trabajando allí, usa la carpeta existente y no ejecutes `git init` otra vez.

## 3. Primer commit: archivos base y dependencias

Crea `requirements.txt`:

```text
fastapi[standard]
PyMySQL
python-dotenv
email-validator
```

Crea un `README.md` inicial con el objetivo y los pasos de instalación. Guarda el primer punto de control:

```powershell
git add .gitignore README.md requirements.txt
git status
git commit -m "Crea estructura inicial del proyecto"
```

Revisa `git status` antes de cada commit. Nunca debe aparecer `.env` ni `.venv`.

## 4. Segundo commit: esquema relacional y datos de ejemplo

En `sql/01_esquema.sql`, define la base `tienda_adso_1` y las tablas `clientes`, `productos`, `pedidos` y `detalle_pedidos`. Usa InnoDB y claves foráneas. En `sql/02_datos_prueba.sql`, agrega dos clientes y tres productos; se ejecuta una sola vez para evitar duplicados.

Registra ese avance:

```powershell
git add sql/01_esquema.sql sql/02_datos_prueba.sql
git commit -m "Crea esquema MySQL y datos de ejemplo"
```

Abre los dos scripts en MySQL Workbench. Ejecuta primero `01_esquema.sql` y después `02_datos_prueba.sql`. Comprueba:

```sql
SHOW TABLES FROM tienda_adso_1;
SELECT * FROM tienda_adso_1.clientes;
SELECT * FROM tienda_adso_1.productos;
```

## 5. Crear el usuario MySQL y configurar `.env`

En Workbench, conectado como administrador, crea el usuario para la aplicación. Sustituye el texto de contraseña por una clave privada:

```sql
CREATE USER 'api_adso'@'localhost' IDENTIFIED BY 'TU_CLAVE_PRIVADA';
GRANT SELECT, INSERT, UPDATE, DELETE ON tienda_adso_1.* TO 'api_adso'@'localhost';
```

Si el usuario ya existe, cambia su clave con `ALTER USER` en lugar de volver a ejecutar `CREATE USER`:

```sql
ALTER USER 'api_adso'@'localhost' IDENTIFIED BY 'TU_CLAVE_PRIVADA';
```

Crea `.env.example` con valores de muestra, sin una contraseña real:

```text
DB_HOST=localhost
DB_PORT=3306
DB_USER=api_adso
DB_PASSWORD=CAMBIA_ESTA_CLAVE
DB_NAME=tienda_adso_1
```

Crea tu `.env` local y escribe la clave que acabas de asignar en MySQL:

```powershell
Copy-Item .env.example .env
notepad .env
```

Agrega solo la plantilla al siguiente commit, nunca `.env`:

```powershell
git add .env.example
git status
```

Confirma que `.env` no está listado antes de continuar.

## 6. Crear el entorno Python

Desde la raíz del proyecto:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Si PowerShell bloquea la activación en esa ventana:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

La carpeta `.venv` es local y no se sube a Git.

## 7. Tercer commit: conexión, validación, clientes y productos

Completa estos archivos copiando su código desde el proyecto:

- `app/database.py`: abre la conexión MySQL y hace commit o rollback.
- `app/schemas.py`: valida nombres, correos, precios, stock y artículos de pedido.
- `app/routers/clientes.py`: lista, consulta y registra clientes.
- `app/routers/productos.py`: lista, busca, consulta, crea productos y actualiza stock.
- `app/main.py`: crea FastAPI e incluye los routers.

Cuando esos archivos estén listos:

```powershell
git add app/__init__.py app/main.py app/database.py app/schemas.py app/routers/__init__.py app/routers/clientes.py app/routers/productos.py
git status
git commit -m "Agrega conexión y recursos de clientes y productos"
```

## 8. Cuarto commit: pedidos con transacción

Implementa `app/routers/pedidos.py`. El endpoint debe validar que exista el cliente y cada producto, bloquear productos con `SELECT ... FOR UPDATE`, comprobar existencias, calcular subtotales y total, insertar pedido y detalles, y descontar stock. Todo ocurre en una transacción: un error debe revertir todos los cambios.

```powershell
git add app/routers/pedidos.py
git commit -m "Agrega pedidos con control transaccional de stock"
```

## 9. Quinto commit: panel web y servidor

En `app/static/index.html`, arma el panel con formularios para clientes, productos y pedidos. Para pedidos, usa selectores de cliente y producto, campo de cantidad y botón para agregar artículos. JavaScript envía los datos a los endpoints FastAPI.

En `app/main.py`, sirve la página mediante `FileResponse` en la ruta `/`. Conserva `/docs` para Swagger.

```powershell
git add app/main.py app/static/index.html
git commit -m "Agrega panel web para administrar la tienda"
```

## 10. Sexto commit: iniciar y detener desde PowerShell

Crea `iniciar_api.ps1` para lanzar Uvicorn usando `.venv\Scripts\python.exe`, y `detener_api.ps1` para terminar ese proceso usando el PID guardado. El proyecto terminado ya contiene ambos scripts.

```powershell
git add iniciar_api.ps1 detener_api.ps1 .gitignore README.md
git status
git commit -m "Agrega comandos PowerShell para controlar la API"
```

## 11. Ejecutar y revisar la aplicación

Asegúrate de que MySQL está iniciado, ejecutaste los scripts SQL y el `.env` contiene el usuario, clave y nombre de base correctos. Desde la raíz del proyecto:

```powershell
.\iniciar_api.ps1
```

Abre el panel en <http://127.0.0.1:8000/> y Swagger en <http://127.0.0.1:8000/docs>. Prueba listar y crear cliente/producto, crear un pedido, abrir su detalle y comprobar el stock en MySQL. Para detener el servidor:

```powershell
.\detener_api.ps1
```

Si ves `Internal Server Error`, revisa la terminal o `api-error.log`; verifica el servicio MySQL, la clave de `.env`, los permisos del usuario y que la base se llame exactamente `tienda_adso_1`.

## 12. Subir los commits a GitHub

Cuando hayas terminado y `git status` esté limpio:

```powershell
git log --oneline
git push -u origin main
```

Los commits quedan separados por etapa y el `push` los publica en GitHub. Para cambios futuros, repite el ciclo: edita, revisa `git status`, agrega solo los archivos relacionados, crea un commit claro y luego ejecuta `git push`.

## Nota para el proyecto que ya existe

La carpeta `C:\Users\nexus\Desktop\tienda_adso` ya tiene `.git`, `origin` y commits. Para trabajar allí, no repitas `git init` ni `git remote add origin`. Los commits incrementales de esta guía describen el orden de construcción desde cero; el historial existente ya conserva los cambios previamente guardados.



from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse

from app.routers import clientes, pedidos, productos

app = FastAPI(
    title="Taller 3 ADSO - Tienda",
    version="1.0.0",
    description="API de clientes, productos y pedidos",
)
app.include_router(clientes.router)
app.include_router(productos.router)
app.include_router(pedidos.router)


@app.get("/", include_in_schema=False)
def pagina_inicio():
    archivo = Path(__file__).parent / "static" / "index.html"
    return FileResponse(archivo)

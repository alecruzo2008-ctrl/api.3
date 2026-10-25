from fastapi import FastAPI
from app.routers import clientes, pedidos, productos

app = FastAPI(
    title="Taller 3 ADSO - Tienda",
    version="1.0.0",
    description="API de clientes, productos y pedidos",
)
app.include_router(clientes.router)
app.include_router(productos.router)
app.include_router(pedidos.router)


@app.get("/", tags=["Inicio"])
def inicio():
    return {"mensaje": "API tienda ADSO", "documentacion": "/docs"}

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Hackathon API",
    description="API para el proyecto del Hackathon",
    version="0.1.0"
)

# CORS - ajustar origins en producción
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"status": "ok", "message": "Hackathon API running"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}

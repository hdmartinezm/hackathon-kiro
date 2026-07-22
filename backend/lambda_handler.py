"""Handler Lambda usando Mangum para despliegue en AWS Lambda."""
from mangum import Mangum
from app.main import app

handler = Mangum(app, lifespan="off")

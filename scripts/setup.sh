#!/bin/bash
# Setup script para el proyecto del Hackathon

echo "=== Hackathon Setup ==="

# Backend
echo ""
echo ">> Configurando Backend (Python)..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..
echo "   Backend listo!"

# Frontend
echo ""
echo ">> Configurando Frontend (React)..."
cd frontend
npm install
cd ..
echo "   Frontend listo!"

echo ""
echo "=== Setup Completo ==="
echo ""
echo "Para iniciar el backend:"
echo "  cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo ""
echo "Para iniciar el frontend:"
echo "  cd frontend && npm run dev"

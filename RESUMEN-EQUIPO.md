# Resumen Final - Hackathon Kiro

---

## Links del Proyecto

| Herramienta | Link |
|-------------|------|
| **GitHub** | https://github.com/hdmartinezm/hackathon-kiro |
| **Trello** | https://trello.com/b/sSyhs88y/hackathon-kiro |
| **Google Drive** | https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9 |
| **AWS Console** | Cuenta `539562792848` |

---

## Equipo

| Rol | Nombre | GitHub | Email |
|-----|--------|--------|-------|
| Coordinador + Backend | Hector | hdmartinezm | |
| Diseño + Frontend | Alvaro | ajha63 | hernandez.alvaro@gmail.com |
| Fullstack | William | izquierdowaws | izquierdowo@gmail.com |
| Frontend | Francisco | FranciscoJTHG | franthielengaravito@gmail.com |

### Responsabilidades

| Tarea | Hector | Alvaro | William | Francisco |
|-------|:------:|:------:|:-------:|:---------:|
| Coordinar equipo / Trello | **Owner** | | | |
| API / Endpoints | **Owner** | | Ayuda | |
| Base de datos | **Owner** | | Ayuda | |
| Deploy AWS | **Owner** | | Ayuda | |
| Diseño / Mockups | | **Owner** | | |
| Assets (logos, iconos) | | **Owner** | | |
| Componentes React | | Ayuda | Ayuda | **Owner** |
| Estilos / CSS | | **Owner** | | Ayuda |
| Integración API-Frontend | | | **Owner** | Ayuda |
| Demo / Pitch | **Owner** | Ayuda | | |

---

## Primeros Pasos (cada miembro)

### 1. Aceptar invitación de GitHub
```
https://github.com/hdmartinezm/hackathon-kiro/invitations
```

### 2. Clonar y probar el proyecto
```bash
git clone https://github.com/hdmartinezm/hackathon-kiro.git
cd hackathon-kiro
./scripts/setup.sh
```

### 3. Iniciar desarrollo
```bash
# Terminal 1 - Backend
cd backend && source venv/bin/activate && uvicorn app.main:app --reload

# Terminal 2 - Frontend
cd frontend && npm run dev
```

### 4. AWS (si aplica)
```bash
export AWS_PROFILE=Sandbox-Hackathon
aws sts get-caller-identity
```

---

## Estructura del Repo

```
hackathon-kiro/
├── frontend/          # React + Vite
├── backend/           # Python + FastAPI
├── docs/              # Documentación
├── assets/            # Recursos (imágenes, logos)
├── infrastructure/    # Docker, deploy
└── scripts/           # Scripts de utilidad
```

---

## Workflow de Git

```bash
# 1. Actualizar dev
git checkout dev && git pull

# 2. Crear tu rama
git checkout -b feat/mi-feature

# 3. Trabajar y commitear
git add .
git commit -m "feat: descripción"

# 4. Push y crear PR
git push -u origin feat/mi-feature
# → Crear PR hacia dev en GitHub
```

**Convención de commits:** `tipo: descripción`
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `docs:` documentación

---

## Tablero Trello

```
Backlog → Sprint 1 → En Curso → Revisión → Done → Bloqueado
```

**Etiquetas:** Setup (verde), Frontend (azul), Backend (morado), Database (amarillo), Bug (rojo), Blocker (negro), Design (naranja)

---

## Checklist Pre-Hackathon

- [ ] Aceptar invitación de GitHub
- [ ] Clonar repo y correr `./scripts/setup.sh`
- [ ] Verificar que frontend y backend corren
- [ ] Revisar Trello y asignarse tareas
- [ ] Acceder a Google Drive

---

**¡Listos para el hackathon!**

# Estructura de Gestión - Hackathon 2024

> **Tiempo de setup:** ~2 horas
> **Equipo:** 4 personas
> **Duración del evento:** 48-72 horas

---

## Tabla de Contenidos

1. [Links Importantes](#links-importantes)
2. [Roles del Equipo](#roles-del-equipo)
3. [Estructura del Repositorio](#estructura-del-repositorio)
4. [Estrategia de Git](#estrategia-de-git)
5. [Tablero Trello](#tablero-trello)
6. [Google Drive](#google-drive)
7. [Comunicación](#comunicación)
8. [Checklist Pre-Hackathon](#checklist-pre-hackathon)
9. [Comandos Rápidos](#comandos-rápidos)

---

## Links Importantes

| Recurso | URL |
|---------|-----|
| Repositorio GitHub | `[PENDIENTE]` |
| Tablero Trello | `[PENDIENTE]` |
| Google Drive | `[PENDIENTE]` |
| Discord/Slack | `[PENDIENTE]` |
| AWS Console | https://539562792848.signin.aws.amazon.com/console |
| Figma (si aplica) | `[PENDIENTE]` |

---

## Roles del Equipo

### Distribución

```
┌─────────────────────────────────────────────────────────────────┐
│                        EQUIPO HACKATHON                         │
├─────────────────┬───────────────────────────────────────────────┤
│                 │                                               │
│   COORDINADOR   │  • Mantiene el Trello actualizado            │
│   + FULLSTACK   │  • Facilita standups y resuelve conflictos   │
│                 │  • Hace merge a dev/main                      │
│   [_________]   │  • Código: conecta frontend ↔ backend        │
│                 │  • Prepara la demo final                      │
│                 │                                               │
├─────────────────┼───────────────────────────────────────────────┤
│                 │                                               │
│    FRONTEND     │  • UI/UX completa                             │
│    LEAD         │  • Componentes, estilos, responsive          │
│                 │  • Integra APIs del backend                   │
│   [_________]   │  • Pruebas manuales de UX                    │
│                 │                                               │
├─────────────────┼───────────────────────────────────────────────┤
│                 │                                               │
│    BACKEND      │  • API endpoints                              │
│    LEAD         │  • Base de datos y modelos                    │
│                 │  • Autenticación/seguridad                    │
│   [_________]   │  • Deploy e infraestructura (AWS)            │
│                 │                                               │
├─────────────────┼───────────────────────────────────────────────┤
│                 │                                               │
│    DISEÑO       │  • Wireframes y mockups rápidos              │
│    + FRONTEND   │  • Assets gráficos (logos, iconos)           │
│                 │  • Ayuda con CSS/componentes                  │
│   [_________]   │  • Pitch deck y materiales de presentación   │
│                 │                                               │
└─────────────────┴───────────────────────────────────────────────┘
```

### Matriz de Responsabilidades

| Tarea | Coordinador | Frontend | Backend | Diseño |
|-------|:-----------:|:--------:|:-------:|:------:|
| Merge a main | **Owner** | - | - | - |
| UI Components | Ayuda | **Owner** | - | Ayuda |
| API Endpoints | - | - | **Owner** | - |
| Database | - | - | **Owner** | - |
| Diseño visual | - | Ayuda | - | **Owner** |
| Deploy AWS | Backup | - | **Owner** | - |
| Trello/Docs | **Owner** | - | - | Ayuda |
| Demo/Pitch | **Owner** | Ayuda | Ayuda | **Owner** |

### Contactos

| Rol | Nombre | GitHub | Teléfono |
|-----|--------|--------|----------|
| Coordinador | | | |
| Frontend | | | |
| Backend | | | |
| Diseño | | | |

---

## Estructura del Repositorio

```
hackathon-proyecto/
├── README.md                    # Descripción, setup, y quién hace qué
├── docs/
│   ├── ARCHITECTURE.md          # Decisiones técnicas clave
│   ├── API.md                   # Endpoints (si aplica)
│   └── DECISIONS.md             # Log de decisiones rápidas
├── frontend/
│   ├── src/
│   ├── public/
│   └── package.json
├── backend/
│   ├── src/
│   ├── tests/
│   └── requirements.txt         # o package.json
├── infrastructure/
│   ├── docker-compose.yml
│   └── deploy/
├── assets/
│   ├── designs/                 # Exports de Figma/diseños
│   ├── images/
│   └── logos/
└── scripts/
    ├── setup.sh                 # Script de instalación local
    └── deploy.sh
```

---

## Estrategia de Git

### Ramas

```
main                 ← Siempre deployable, protegida
  └── dev            ← Integración continua del equipo
       ├── feat/login-ui          (Frontend)
       ├── feat/api-users         (Backend)
       ├── feat/database-setup    (Backend)
       └── fix/cors-issue         (Cualquiera)
```

**Reglas:**
- `main` = solo merges de `dev` cuando funciona
- `dev` = todos hacen PR aquí
- `feat/nombre-corto` = features nuevas
- `fix/nombre-corto` = bugs

### Convención de Commits

```
tipo: descripción corta (max 50 chars)

Tipos:
  feat:     Nueva funcionalidad
  fix:      Corrección de bug
  docs:     Documentación
  style:    Formato (no afecta lógica)
  refactor: Reestructuración sin cambiar comportamiento
  chore:    Tareas de mantenimiento

Ejemplos:
  feat: agregar autenticación con Google
  fix: corregir error de CORS en API
  docs: documentar endpoints de usuario
```

### Workflow

```bash
git checkout dev
git pull origin dev
git checkout -b feat/mi-feature
# ... trabajo ...
git add .
git commit -m "feat: descripción"
git push origin feat/mi-feature
# Crear PR en GitHub → Squash and Merge → Delete branch
```

---

## Tablero Trello

### Listas

```
┌───────────┬───────────┬───────────┬───────────┬───────────┬───────────┐
│  BACKLOG  │ SPRINT 1  │ EN CURSO  │ REVISIÓN  │   DONE    │ BLOQUEADO │
│  (ideas)  │ (priori-  │ (WIP max  │ (PR/test) │ (comple-  │ (urgente) │
│           │  zado)    │  1 c/u)   │           │  tado)    │           │
└───────────┴───────────┴───────────┴───────────┴───────────┴───────────┘
```

### Etiquetas

| Color | Nombre | Uso |
|-------|--------|-----|
| 🟢 Verde | Setup | Configuración inicial |
| 🔵 Azul | Frontend | UI/UX |
| 🟣 Morado | Backend | API/Server |
| 🟡 Amarillo | Database | Datos/Modelos |
| 🔴 Rojo | Bug | Errores |
| ⚫ Negro | Blocker | Bloquea a otros |
| 🟠 Naranja | Design | Diseño/Assets |

### Plantilla de Card - Feature

```
Título: [FEAT] Nombre de la feature
Etiqueta: (según área)
Asignado: [Nombre]

Descripción:
  [Qué debe hacer esta feature]

Checklist:
  □ Subtarea 1
  □ Subtarea 2
  □ Test manual completado

Criterio de Done: PR aprobado y mergeado a dev
```

### Plantilla de Card - Bug

```
Título: [BUG] Descripción corta del error
Etiqueta: 🔴 Bug
Asignado: [Nombre]

Pasos para reproducir:
  1. Ir a...
  2. Hacer click en...
  3. Ver error...

Comportamiento esperado:
  [Qué debería pasar]
```

---

## Google Drive

```
📁 Hackathon-[NombreProyecto]/
│
├── 📁 00-LEER-PRIMERO/
│   ├── 📄 QUICK-START.md
│   ├── 📄 CONTACTOS.md
│   └── 📄 LINKS-IMPORTANTES.md
│
├── 📁 01-Documentación/
│   ├── 📄 Pitch-Deck.slides
│   ├── 📄 Idea-Original.md
│   ├── 📄 Requisitos-Técnicos.md
│   └── 📄 User-Stories.md
│
├── 📁 02-Diseño/
│   ├── 📁 Wireframes/
│   ├── 📁 Mockups/
│   ├── 📁 Assets-Export/
│   └── 📄 Link-Figma.md
│
├── 📁 03-Investigación/
│   ├── 📄 Competencia.md
│   ├── 📄 APIs-Externas.md
│   └── 📄 Referencias.md
│
├── 📁 04-Decisiones/
│   └── 📄 Decision-Log.md
│
├── 📁 05-Demo/
│   ├── 📁 Screenshots/
│   ├── 📁 Videos/
│   └── 📄 Script-Demo.md
│
└── 📁 06-Recursos/
    ├── 📁 Logos/
    ├── 📁 Iconos/
    └── 📁 Fuentes/
```

---

## Comunicación

### Canales (Discord/Slack)

```
📢 #anuncios          → Solo coordinador, info crítica
💬 #general           → Conversación libre
🔧 #dev-frontend      → Discusiones técnicas frontend
⚙️ #dev-backend       → Discusiones técnicas backend
🎨 #diseño            → Assets, feedback de UI
🚨 #bloqueadores      → SOLO para bloqueos urgentes
🔊 Sala de voz        → Siempre abierta para pair/dudas
```

### Reuniones

| Reunión | Duración | Frecuencia | Formato |
|---------|----------|------------|---------|
| **Kickoff** | 30 min | 1 vez (inicio) | Roles, objetivos, primer sprint |
| **Standup** | 5 min | Cada 4-6 horas | Async en #general o voice rápido |
| **Sync** | 15 min | 2x/día | Revisar bloqueadores, reajustar |
| **Demo prep** | 30 min | Última hora | Preparar presentación |

### Formato de Standup (Async)

```
🟢 HECHO: [qué completaste]
🔵 HACIENDO: [en qué estás ahora]
🔴 BLOQUEADO: [qué te detiene]
```

### Reglas

1. **#bloqueadores = urgente** — Alguien responde en 5 min
2. **Voice > texto** — Si hay >3 mensajes de ida y vuelta, ir a voz
3. **Decisiones en #anuncios** — Lo importante queda documentado
4. **30 min bloqueado = pedir ayuda** — No perder tiempo solo

---

## Checklist Pre-Hackathon

### Infraestructura

- [ ] Repo creado y todos con acceso
- [ ] Branch protection configurado en `main`
- [ ] Todos pueden clonar, hacer commit y push
- [ ] README con instrucciones de setup

### Herramientas

- [ ] Tablero de Trello creado y compartido
- [ ] Carpeta de Drive creada y compartida
- [ ] Servidor de Discord/Slack listo
- [ ] Grupo de WhatsApp backup creado

### Accesos Verificados

- [ ] AWS Sandbox funcionando: `aws sts get-caller-identity --profile Sandbox-Hackathon`
- [ ] Cada miembro probó: `git clone`, `npm install`, `npm run dev`
- [ ] Credenciales de APIs externas obtenidas

### Definiciones

- [ ] Idea/problema a resolver documentado
- [ ] MVP definido (qué SÍ y qué NO entra)
- [ ] Stack tecnológico decidido
- [ ] Roles asignados y aceptados
- [ ] División inicial de tareas en Trello

### Logística

- [ ] Horarios de disponibilidad conocidos
- [ ] Número de teléfono de cada miembro
- [ ] Plan de descansos acordado

---

## Comandos Rápidos

### Setup Inicial

```bash
# Clonar repositorio
git clone git@github.com:tu-org/hackathon-proyecto.git
cd hackathon-proyecto

# Instalar dependencias
npm install        # o el comando de tu stack

# Verificar que corre
npm run dev
```

### Git Diario

```bash
# Actualizar dev y crear feature
git checkout dev && git pull
git checkout -b feat/mi-feature

# Commit y push
git add .
git commit -m "feat: descripción"
git push -u origin feat/mi-feature

# Después del merge, limpiar
git checkout dev && git pull
git branch -d feat/mi-feature
```

### AWS

```bash
# Configurar perfil
export AWS_PROFILE=Sandbox-Hackathon

# Verificar acceso
aws sts get-caller-identity

# Listar recursos
aws s3 ls
aws ec2 describe-instances
aws lambda list-functions
```

---

## Plan de Setup (2 horas)

### Hora 1: Infraestructura

| Min | Tarea | Responsable |
|-----|-------|-------------|
| 0-15 | Crear repo GitHub + estructura | Coordinador |
| 0-15 | Crear servidor Discord + canales | Cualquiera |
| 15-30 | Configurar branch protection | Coordinador |
| 15-30 | Crear tablero Trello | Diseño |
| 30-45 | Crear carpeta Drive | Diseño |
| 30-45 | Escribir README | Backend |
| 45-60 | **Todos:** clonar y probar | Todos |

### Hora 2: Verificación

| Min | Tarea | Responsable |
|-----|-------|-------------|
| 0-15 | Verificar acceso AWS | Backend |
| 0-15 | Subir links a Drive/Discord | Coordinador |
| 15-30 | Asignar cards iniciales | Coordinador |
| 30-45 | Kickoff call | Todos |
| 45-60 | Buffer para problemas | - |

---

> **Recuerda:** El objetivo es velocidad + claridad. Si algo no funciona en 15 minutos, pide ayuda en #bloqueadores.

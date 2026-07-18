# Checklist de Setup - Hackathon BabyHealth

**Última actualización:** 18 julio 2026

---

## GitHub / Repositorio
- [x] Inicializar repositorio Git local
- [x] Crear estructura de carpetas (flutter_app/, backend/, infra/)
- [x] Crear README.md con instrucciones
- [x] Crear repo en GitHub: https://github.com/hdmartinezm/hackathon-kiro
- [x] Push inicial a GitHub
- [x] Crear rama `dev`
- [x] Agregar colaboradores
      - [x] FranciscoJTHG - aceptó invitación
      - [ ] ajha63 - pendiente aceptar
      - [ ] izquierdowaws - pendiente aceptar

## Trello
- [x] Crear tablero: https://trello.com/b/sSyhs88y/hackathon-kiro
- [x] Crear listas (Backlog, Sprint 1, En Curso, Revisión, Done, Bloqueado)
- [x] Crear etiquetas (Setup, Frontend, Backend, Design, Bug, Blocker)
- [x] Agregar miembros al tablero
- [x] Crear 21 tareas organizadas por día (D1-D7)

## Google Drive
- [x] Crear carpeta: https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9
- [x] Crear subcarpetas
- [x] Configurar permisos de edición
- [x] Compartir con el equipo

## AWS / Bedrock
- [x] Acceso a cuenta Sandbox-Hackathon (539562792848)
- [x] Verificar modelos disponibles
- [x] **Claude Sonnet 4.5** - FUNCIONANDO (imagen)
- [x] **Claude Haiku 4.5** - FUNCIONANDO (imagen)
- [x] **Amazon Nova Pro** - FUNCIONANDO (imagen + video)

## Audio On-Device (Enfoque Dual)

### iOS - DeepInfant
- [x] Identificar modelo: DeepInfant V2 (89% precision)
- [x] Verificar licencia: Apache 2.0
- [x] Crear guia: docs/GUIA-DEEPINFANT.md
- [x] Agregar tareas a Trello (4 tareas D5)
- [ ] Descargar modelo CoreML (Dia 5)

### Android - YAMNet
- [x] Identificar modelo: YAMNet TFLite (93% deteccion)
- [x] Verificar clase: "Baby cry, infant cry" (indice 20)
- [x] Crear guia: docs/GUIA-YAMNET-ANDROID.md
- [x] Agregar tareas a Trello (4 tareas D5)
- [ ] Descargar modelo TFLite (Dia 5)

### Datasets (Referencia futura)
- [x] Donate-a-Cry corpus: 457 samples, 5 clases
- [x] Kaggle features dataset: MFCCs extraidos

## Documentación
- [x] ESTRUCTURA-EQUIPO.md
- [x] RESUMEN-EQUIPO.md
- [x] PLAN-REFINADO.md (con modelos actualizados)
- [x] Roles definidos (Hector, Alvaro, William, Francisco)

## Comunicación
- [ ] Crear servidor Discord / Slack
- [ ] Grupo WhatsApp backup

---

# Resumen Visual

```
┌─────────────────────────────────────────────────────────────────┐
│                    HACKATHON BABYHEALTH                         │
│                     Estado: LISTO ✓                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  GitHub ✓        Trello ✓        Drive ✓        AWS ✓          │
│  ─────────       ─────────       ─────────      ─────────       │
│  Repo creado     29 tareas       Carpetas      Bedrock OK       │
│  Rama dev        Por día         Compartido    Modelos OK       │
│  3 colabor.      +8 audio D5                                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ARQUITECTURA HIBRIDA                                           │
│  ───────────────────────────────────────────────────────        │
│  IMAGEN (Cloud)          │  AUDIO (On-Device)                   │
│  Claude Vision + Bedrock │  DeepInfant CoreML                   │
│  Análisis en AWS         │  Análisis local (89% acc)            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  EQUIPO                                                         │
│  ───────────────────────────────────────────────────────        │
│  Hector    │ Coordinador + Backend  │ @hdmartinezm              │
│  Alvaro    │ Diseño + Frontend      │ @ajha63                   │
│  William   │ Fullstack              │ @izquierdowaws            │
│  Francisco │ Frontend Lead          │ @FranciscoJTHG ✓          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  MODELOS                                                        │
│  ───────────────────────────────────────────────────────        │
│  Claude Sonnet 4.5  │ Bedrock (imagen)              │ ✓         │
│  Amazon Nova Pro    │ Bedrock (video)               │ ✓         │
│  DeepInfant V2      │ CoreML iOS (audio)            │ ✓         │
│  YAMNet             │ TFLite Android (audio)        │ ✓         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# Links Importantes

| Recurso | URL |
|---------|-----|
| **GitHub** | https://github.com/hdmartinezm/hackathon-kiro |
| **Trello** | https://trello.com/b/sSyhs88y/hackathon-kiro |
| **Google Drive** | https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9 |
| **AWS Console** | Cuenta 539562792848 |
| **DeepInfant** | https://github.com/skytells-research/DeepInfant |
| **YAMNet** | https://tfhub.dev/google/yamnet/1 |
| **Donate-a-Cry** | https://github.com/gveres/donateacry-corpus |

---

# Pendiente para Mañana (Día 1)

## Antes de empezar
- [ ] ajha63 acepta invitación GitHub
- [ ] izquierdowaws acepta invitación GitHub
- [ ] Crear canal de comunicación (Discord/WhatsApp)

## Tareas Día 1

| Quién | Tarea | Prioridad |
|-------|-------|:---------:|
| **Hector** | Deploy CDK (S3, Lambda, DynamoDB, API Gateway) | Alta |
| **Hector** | Probar endpoint con Bedrock | Alta |
| **Francisco** | Setup proyecto Flutter | Alta |
| **Alvaro** | Wireframes 3 pantallas | Media |
| **William** | Ayudar donde se necesite | - |

---

# Comandos de Verificación

```bash
# AWS
export AWS_PROFILE=Sandbox-Hackathon
aws sts get-caller-identity

# Probar Bedrock
aws bedrock-runtime invoke-model \
  --model-id us.anthropic.claude-sonnet-4-5-20250929-v1:0 \
  --region us-east-1 \
  --profile Sandbox-Hackathon \
  --content-type application/json \
  --accept application/json \
  --body "$(echo '{"anthropic_version":"bedrock-2023-05-31","max_tokens":50,"messages":[{"role":"user","content":"Hola"}]}' | base64)" \
  /tmp/test.json && cat /tmp/test.json

# Git clone (para el equipo)
git clone https://github.com/hdmartinezm/hackathon-kiro.git
cd hackathon-kiro
git checkout dev
```

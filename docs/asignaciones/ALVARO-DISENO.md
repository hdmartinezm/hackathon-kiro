# 🎨 Asignación: Alvaro (Diseño + Frontend)

**Rol:** Diseño UI/UX + Assets + Presentación
**GitHub:** ajha63
**Email:** hernandez.alvaro@gmail.com
**Rama base:** `dev`
**Convención de ramas:** `feat/design-*`

---

## Resumen de Responsabilidades

Eres responsable del diseño visual completo de la app (wireframes, mockups, tema), exportación de assets gráficos, y la preparación del pitch deck y materiales de presentación.

---

## Distribución por Día

| Día | Entregable | Estado |
|-----|-----------|--------|
| **D1** | Wireframes de todas las pantallas | ⬜ |
| **D2** | Mockups de alta fidelidad | ⬜ |
| **D3** | Tema visual (colores, tipografía, iconos) | ⬜ |
| **D4** | Exportar assets finales | ⬜ |
| **D5** | Pulir UI (detalles visuales) | ⬜ |
| **D6** | Slides del pitch | ⬜ |
| **D7** | Soporte en presentación | ⬜ |

---

## Día 1: Wireframes

### Objetivos
- Definir el flujo visual completo de la app
- Wireframes de baja fidelidad para todas las pantallas
- Validar con el equipo antes de pasar a mockups

### Pantallas a Diseñar

```
1. Splash Screen (con disclaimer)
2. Home Screen (selección: foto o audio)
3. Camera Screen (preview + botón captura)
4. Audio Screen (grabación con countdown 7s)
5. Result Screen - Visual (semáforo + observaciones)
6. Result Screen - Audio (categoría + recomendación)
```

### Flujo de Navegación
```
Splash (disclaimer) → Home → [Cámara | Audio] → Resultado
                                                     ↓
                                              [Nuevo Análisis]
                                              [Contactar Pediatra]
```

### Componentes Clave

| Componente | Descripción | Pantalla |
|-----------|-------------|----------|
| **Semáforo** | Indicador verde/amarillo/rojo | Result Screen Visual |
| **Disclaimer** | Banner/footer siempre visible | Todas |
| **Barra confianza** | Porcentaje visual | Results |
| **Countdown** | Timer circular de 7 segundos | Audio Screen |
| **Botón acción** | "Nuevo Análisis" / "Contactar Pediatra" | Results |

### Entregables del Día
```
✅ 6 wireframes (baja fidelidad) en Figma o papel
✅ Compartir en Drive (02-Diseño/Wireframes/)
✅ Feedback del equipo recibido
✅ Flujo de navegación validado
```

---

## Día 2: Mockups

### Objetivos
- Convertir wireframes en mockups de alta fidelidad
- Definir paleta de colores y tipografía
- Establecer el look & feel de BabyHealth

### Guía de Estilo Sugerida

**Paleta de colores:**
| Uso | Color sugerido |
|-----|---------------|
| Normal/Positivo | Verde (#4CAF50) |
| Atención | Amarillo/Ámbar (#FFC107) |
| Urgente | Rojo (#F44336) |
| Primario app | Azul suave/Teal para confianza médica |
| Background | Blanco/Gris muy claro |
| Texto | Gris oscuro (#333333) |

**Tipografía:**
- Headers: Fuente sans-serif redondeada (amigable para padres)
- Body: Legible, tamaño generoso (usabilidad con una mano)

**Principios de diseño:**
- Interfaz tranquilizadora (padres ansiosos)
- Información jerárquica clara (semáforo primero)
- Accesible con una mano
- Disclaimer siempre visible sin ser intrusivo

### Entregables del Día
```
✅ 6 mockups de alta fidelidad
✅ Paleta de colores definida
✅ Tipografía seleccionada
✅ Compartir en Drive y con Francisco para implementación
```

---

## Día 3: Tema Visual

### Objetivos
- Definir el tema Flutter (colores, fuentes, estilos)
- Crear especificaciones para Francisco
- Iconografía personalizada si es necesario

### Especificaciones para Flutter

Prepara un documento con:
```
- ColorScheme (primary, secondary, error, background, surface)
- TextTheme (headlineLarge, bodyLarge, labelMedium)
- Spacing/Padding estándar
- Border radius
- Elevation/shadows
- Iconos a usar (Material Icons o custom)
```

### Diseño del Semáforo
```
┌──────────────────────┐
│      ◉ NORMAL        │  ← Verde, icono check
│    Estado de tu bebé  │
│                      │
│ Observaciones:       │
│ • Coloración normal  │
│ • Expresión tranquila│
│                      │
│ Recomendaciones:     │
│ • Monitoreo regular  │
│                      │
│ Confianza: ████░ 87% │
│                      │
│ [Nuevo Análisis]     │
│ [Contactar Pediatra] │
│                      │
│ ⚠️ Disclaimer médico │
└──────────────────────┘
```

### Entregables del Día
```
✅ Documento de tema/estilos para Francisco
✅ Iconos seleccionados o diseñados
✅ Especificaciones de componentes (semáforo, barra, botones)
```

---

## Día 4: Exportar Assets

### Objetivos
- Exportar todos los assets necesarios para la app
- Logos, iconos, splash screen
- Imágenes para la presentación

### Assets Necesarios

| Asset | Formato | Tamaño | Destino |
|-------|---------|--------|---------|
| Logo BabyHealth | PNG/SVG | Múltiples | `assets/logos/` |
| App Icon | PNG | 1024x1024 | Flutter config |
| Splash Image | PNG | Full screen | `flutter_app/assets/` |
| Iconos custom | SVG | 24x24, 48x48 | `assets/images/` |
| Screenshots demo | PNG | Device frames | Drive/05-Demo/ |

### Entregables del Día
```
✅ Logo final en múltiples tamaños
✅ App icon exportado
✅ Splash screen image
✅ Assets subidos al repo en assets/
✅ Commit: feat: agregar assets de diseño
```

---

## Día 5: Pulir UI

### Objetivos
- Revisar la app implementada y sugerir mejoras
- Ajustar animaciones y transiciones con Francisco
- Asegurar consistencia visual

### Actividades
- [ ] Revisar cada pantalla en la app real
- [ ] Ajustar colores/espaciado si difiere del mockup
- [ ] Proponer micro-animaciones (transición semáforo, countdown)
- [ ] Verificar disclaimer visible en todas las pantallas
- [ ] Verificar estados de error son amigables visualmente

---

## Día 6: Slides del Pitch

### Objetivos
- Pitch deck completo para presentación de 5 minutos
- Visuales impactantes del problema y solución

### Estructura del Pitch (5 min)

| Slide | Tiempo | Contenido |
|-------|--------|-----------|
| 1 | 0:00-0:10 | Título + Logo |
| 2 | 0:10-0:30 | Problema (estadísticas, historia) |
| 3-4 | 0:30-1:30 | Demo imagen (screenshots/video) |
| 5-6 | 1:30-2:30 | Demo audio (screenshots/video) |
| 7 | 2:30-3:30 | Arquitectura AWS (diagrama limpio) |
| 8 | 3:30-4:30 | Innovación + Comparativa |
| 9 | 4:30-4:50 | Impacto + Futuro |
| 10 | 4:50-5:00 | Cierre + Disclaimer |

### Entregables del Día
```
✅ Pitch deck completo (10 slides)
✅ Diagrama de arquitectura pulido
✅ Tabla comparativa visual
✅ Subir a Drive (01-Documentación/)
```

---

## Día 7: Soporte Presentación

- [ ] Tener slides finales listas
- [ ] Backup en PDF por si falla internet
- [ ] Estar disponible para ajustes de último minuto
- [ ] Colaborar en la narrativa del pitch

---

## Herramientas Recomendadas

| Herramienta | Uso |
|-------------|-----|
| Figma | Wireframes y mockups |
| Canva/Slides | Pitch deck |
| Iconify/Flaticon | Iconos |
| Coolors.co | Paleta de colores |
| Google Fonts | Tipografía |

---

## Contactos para Coordinación

| Necesito de... | Para... |
|----------------|---------|
| Francisco | Confirmar que implementa el tema correctamente |
| William | Validar que los assets se integran bien |
| Hector | Diagrama de arquitectura para las slides |

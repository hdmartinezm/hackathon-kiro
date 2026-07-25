# Contexto de Presentación — BabyHealth

## Objetivo de la Aplicación

BabyHealth es una aplicación de orientación para padres primerizos que utiliza inteligencia artificial multimodal para analizar videos de bebés y proporcionar recomendaciones sobre su estado de salud. Los padres graban un video corto de su bebé, la IA analiza señales visuales (color de piel, postura, expresiones) y auditivas (clasificación de llanto) para entregar un resultado inmediato en formato de semáforo: verde (normal), amarillo (atención recomendada) o rojo (urgente, consulte pediatra).

## Contexto Histórico

- **Evento:** Hackathon Kiro 2026
- **Duración del desarrollo:** 48-72 horas intensivas
- **Motivación:** Los padres primerizos frecuentemente experimentan ansiedad ante síntomas comunes de sus bebés, sin saber si requieren atención médica inmediata. Las consultas de urgencia innecesarias saturan los sistemas de salud, mientras que situaciones reales pueden pasar desapercibidas por falta de orientación.
- **Inspiración:** Democratizar el acceso a una primera orientación de salud infantil usando IA de última generación, disponible 24/7 desde cualquier dispositivo.

## Retos a Cubrir

1. **Análisis multimodal en tiempo real** — Procesar video (visual + audio) con modelos de IA generativa de forma rápida y económica.
2. **Confiabilidad de la IA** — Implementar doble motor de IA (AWS Bedrock con Claude Sonnet + Google Gemini) para redundancia y comparación de resultados.
3. **Experiencia de usuario intuitiva** — Padres estresados necesitan respuestas claras en segundos, no interfaces complejas.
4. **Escalabilidad serverless** — Arquitectura que escale a millones de consultas sin gestión de servidores.
5. **Seguridad y privacidad** — Videos de bebés son datos sensibles; almacenamiento temporal con TTL de 24h, autenticación social robusta.
6. **Multilenguaje** — Soporte bilingüe (español/inglés) desde el día uno.
7. **Generación de reportes** — PDFs compartibles con pediatras vía WhatsApp para facilitar la comunicación médico-padre.

## Valor a Entregar

- **Para padres:** Tranquilidad inmediata con orientación basada en IA, disponible 24/7, sin costo de consulta.
- **Para pediatras:** Reportes PDF estructurados que llegan antes de la cita, optimizando el tiempo de consulta.
- **Para el sistema de salud:** Reducción de consultas de urgencia innecesarias mediante triaje inteligente.
- **Diferenciadores:**
  - Sistema de semáforo visual claro e inmediato
  - Doble motor de IA para mayor confiabilidad
  - Perfiles personalizados que contextualizan el análisis (edad del bebé, historial)
  - Compartir resultados directamente con el pediatra por WhatsApp

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Frontend** | Flutter Web (Dart), Provider (estado), AWS Amplify + Cognito (auth), SharedPreferences |
| **Backend** | Python 3.11, FastAPI, Mangum (Lambda adapter) |
| **IA - Primario** | AWS Bedrock — Claude Sonnet 4.5 (análisis visual + clasificación de llanto) |
| **IA - Alternativo** | Google Gemini 2.5 Flash (análisis de video nativo) |
| **Infraestructura** | AWS Lambda, API Gateway, CloudFront CDN, S3, DynamoDB |
| **Auth** | AWS Cognito (Google OAuth, Facebook OAuth) |
| **IaC** | AWS CDK (Python) |
| **CI/CD** | GitHub + AWS CDK deploy |

## Equipo de Trabajo

| Nombre | Rol | Responsabilidades |
|--------|-----|-------------------|
| **Hector Martinez** | Coordinador + Backend Lead | Arquitectura AWS, API endpoints, deploy, integración IA, coordinación del equipo, merge a main |
| **Alvaro Hernandez** | Diseño + Frontend | UI/UX, diseño visual, mockups, assets gráficos, estilos, pitch deck |
| **William Izquierdo** | Fullstack | Integración API-Frontend, base de datos, deploy AWS, componentes |
| **Francisco Thielen** | Frontend Lead | Componentes Flutter, pantallas, responsive, pruebas de UX |

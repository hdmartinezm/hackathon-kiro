# Contexto de Presentación — BabyHealth (Demo 001)

## Objetivo de la Aplicación

BabyHealth es una aplicación de orientación para padres primerizos que utiliza inteligencia artificial multimodal para analizar videos de bebés y proporcionar recomendaciones sobre su estado de salud. Resuelve la ansiedad e incertidumbre que enfrentan los padres cuando su bebé llora o presenta síntomas fuera de horario de consulta médica.

## Contexto Histórico

Desarrollada durante el Hackathon Kiro 2026. La motivación original nace de la estadística de que más del 60% de visitas a urgencias pediátricas son por condiciones no urgentes — los padres no tienen herramientas para discriminar cuándo realmente necesitan atención médica inmediata.

## Retos a Cubrir

- **Análisis multimodal en tiempo real:** Procesar video (frame visual + espectrograma de audio) para una evaluación integral.
- **Clasificación de llanto:** Distinguir entre hambre, dolor, sueño, incomodidad y cólico mediante análisis de espectrograma.
- **Sistema de semáforo claro:** Traducir resultados de IA en indicadores accionables (verde/amarillo/rojo).
- **Conectividad directa con pediatra:** Botón de WhatsApp con reporte PDF generado automáticamente.
- **Latencia aceptable:** Análisis completo en menos de 15 segundos desde la captura.
- **Multi-idioma y multi-modelo:** Soporte ES/EN y fallback entre Claude (Bedrock) y Gemini.

## Valor a Entregar

- **Para padres:** Tranquilidad instantánea. Saber si deben ir a urgencias o pueden esperar a la consulta regular.
- **Para el sistema de salud:** Reducción de consultas de emergencia innecesarias.
- **Para pediatras:** Recibir reportes estructurados vía WhatsApp cuando sí se requiere atención.

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter Web (Dart), Provider, flutter_animate |
| Backend | Python 3.11 + FastAPI, Mangum (Lambda adapter) |
| IA Visual | AWS Bedrock — Claude Sonnet (Converse API) |
| IA Alternativa | Google Gemini (fallback) |
| Auth | AWS Cognito (Google/Facebook OAuth) + Amplify |
| Storage | S3 (videos temporales, TTL 24h) |
| Database | DynamoDB (historial de análisis) |
| CDN | CloudFront |
| IaC | AWS CDK (TypeScript) |
| Video Processing | FFmpeg (Lambda Layer) |

## Equipo de Trabajo

| Nombre | Rol | Responsabilidades |
|--------|-----|-------------------|
| Hector Martínez | Coordinador + Backend | API, infraestructura AWS, deploy, Bedrock integration, coordinación |
| Álvaro Hernández | Diseño + Frontend | UI/UX, mockups, estilos, assets gráficos |
| William Izquierdo | Fullstack | Integración API-Frontend, conectividad end-to-end |
| Francisco Thielen | Frontend | Componentes Flutter, pantallas, responsive design |

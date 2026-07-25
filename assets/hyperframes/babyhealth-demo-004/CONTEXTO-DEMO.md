# Contexto de Presentación — BabyHealth (Demo 004)

## Objetivo de la Aplicación

BabyHealth es una aplicación de orientación para padres primerizos que usa IA multimodal para analizar videos de bebés y proporcionar recomendaciones inmediatas sobre su estado de salud, mediante un sistema de semáforo (verde/amarillo/rojo).

## Contexto Histórico

- **Evento:** Hackathon Kiro 2026
- **Desarrollo:** 48-72 horas intensivas
- **Motivación:** Padres primerizos carecen de herramientas para distinguir síntomas normales de urgentes en sus bebés, generando ansiedad y consultas de emergencia innecesarias.

## Retos a Cubrir

1. Análisis multimodal (video + audio) con IA generativa en tiempo real
2. Doble motor de IA (Bedrock + Gemini) para redundancia
3. UX intuitiva para padres estresados — respuestas en segundos
4. Arquitectura serverless que escale sin gestión de servidores
5. Privacidad — videos temporales con TTL 24h
6. Bilingüe (ES/EN) desde el día uno
7. Reportes PDF compartibles con pediatras vía WhatsApp

## Valor a Entregar

- Orientación inmediata 24/7 basada en IA
- Reducción de consultas de urgencia innecesarias
- Comunicación optimizada padre-pediatra con reportes PDF
- Sistema de semáforo claro e intuitivo

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter Web, Provider, AWS Amplify + Cognito |
| Backend | Python 3.11, FastAPI, Mangum |
| IA Primario | AWS Bedrock — Claude Sonnet 4.5 |
| IA Alternativo | Google Gemini 2.5 Flash |
| Infra | AWS Lambda, API Gateway, CloudFront, S3, DynamoDB |
| IaC | AWS CDK (Python) |

## Equipo de Trabajo

| Nombre | Rol | Responsabilidades |
|--------|-----|-------------------|
| Hector Martinez | Coordinador + Backend | Arquitectura AWS, API, deploy, integración IA |
| Alvaro Hernandez | Diseño + Frontend | UI/UX, diseño visual, estilos, pitch deck |
| William Izquierdo | Fullstack | Integración API-Frontend, DB, deploy |
| Francisco Thielen | Frontend Lead | Componentes Flutter, pantallas, responsive |

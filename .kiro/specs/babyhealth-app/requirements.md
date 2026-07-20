# Requirements Document

## Introduction

BabyHealth es una aplicación móvil para padres primerizos que proporciona orientación inmediata sobre el estado de salud de su bebé mediante inteligencia artificial multimodal. La aplicación combina análisis visual (cloud) para detección de condiciones como ictericia, y análisis de audio (on-device) para clasificación de tipos de llanto. La arquitectura es serverless sobre AWS, con procesamiento híbrido cloud/edge para optimizar privacidad y latencia.

## Glossary

- **Sistema_BabyHealth**: Aplicación móvil Flutter (iOS/Android) que integra análisis visual y de audio para orientación de salud infantil
- **Backend_API**: Servicio serverless FastAPI desplegado en AWS Lambda detrás de Amazon API Gateway
- **Motor_Vision**: Servicio de análisis de imagen basado en Amazon Bedrock con Claude Sonnet 4.5
- **Motor_Audio_iOS**: Modelo DeepInfant V2 ejecutado localmente vía CoreML para clasificación de llanto en iOS
- **Motor_Audio_Android**: Pipeline de YAMNet TFLite (detección de llanto) combinado con Bedrock (clasificación) para Android
- **Almacen_Imagenes**: Bucket Amazon S3 para almacenamiento temporal de imágenes con URLs pre-firmadas
- **Almacen_Resultados**: Tabla Amazon DynamoDB para persistencia de resultados de análisis
- **Sesion**: Identificador único (UUID) que agrupa las interacciones de un usuario en un flujo de análisis
- **Nivel_Urgencia**: Clasificación tripartita del estado general: normal, requiere_atencion, urgente
- **Categoria_Llanto**: Una de las 9 clasificaciones posibles del llanto: hambre, dolor, cansancio, incomodidad, eructo, temperatura, miedo, soledad, desconocido
- **Umbral_Confianza**: Valor mínimo de confianza (0.0 a 1.0) requerido para emitir una clasificación válida
- **Disclaimer_Medico**: Aviso legal obligatorio que indica que la aplicación no sustituye consulta médica profesional
- **URL_Prefirmada**: URL temporal generada por S3 que permite subir o descargar un objeto sin credenciales AWS directas

## Requirements

### Requisito 1: Captura y Carga de Imagen

**User Story:** Como padre primerizo, quiero capturar una foto de mi bebé y subirla de forma segura, para que el sistema pueda analizarla.

#### Criterios de Aceptación

1. WHEN el usuario solicita subir una imagen, THE Backend_API SHALL generar una URL_Prefirmada con expiración de 300 segundos para el Almacen_Imagenes
2. WHEN el usuario proporciona el tipo de archivo, THE Backend_API SHALL validar que el tipo sea image/jpeg o image/png
3. IF el tipo de archivo no es image/jpeg ni image/png, THEN THE Backend_API SHALL retornar un error con código 400 y mensaje descriptivo
4. WHEN la URL_Prefirmada es generada exitosamente, THE Backend_API SHALL retornar la URL de carga, la clave S3 y el tiempo de expiración en formato JSON
5. THE Sistema_BabyHealth SHALL asociar cada imagen subida con una Sesion única mediante un session_id en formato UUID

### Requisito 2: Validación de Calidad de Imagen

**User Story:** Como padre primerizo, quiero recibir retroalimentación cuando la foto no es adecuada, para poder tomar una mejor imagen antes del análisis.

#### Criterios de Aceptación

1. WHEN una imagen es recibida para análisis, THE Motor_Vision SHALL evaluar la calidad de la imagen antes de proceder con el análisis de salud
2. IF la imagen tiene iluminación insuficiente o está borrosa, THEN THE Motor_Vision SHALL retornar un mensaje amigable solicitando una nueva captura
3. IF la imagen no contiene un rostro de bebé identificable, THEN THE Motor_Vision SHALL retornar un mensaje indicando que no se detectó un bebé en la imagen
4. WHEN la validación de calidad falla, THE Sistema_BabyHealth SHALL mostrar instrucciones claras para mejorar la captura (iluminación, enfoque, encuadre)

### Requisito 3: Análisis Visual con IA

**User Story:** Como padre primerizo, quiero que la IA analice la foto de mi bebé y detecte posibles condiciones como ictericia, para recibir orientación oportuna.

#### Criterios de Aceptación

1. WHEN una imagen válida es enviada para análisis, THE Motor_Vision SHALL analizar la coloración de piel, expresión facial y estado general del bebé
2. WHEN el análisis es completado, THE Motor_Vision SHALL retornar un JSON estructurado con los campos: estado_general, observaciones, recomendaciones, confianza, disclaimer y timestamp
3. THE Motor_Vision SHALL clasificar el estado_general exclusivamente como uno de los tres valores del Nivel_Urgencia: normal, requiere_atencion o urgente
4. THE Motor_Vision SHALL incluir un valor de confianza entre 0.0 y 1.0 que refleje la certeza del análisis
5. WHEN se detectan signos de coloración amarillenta, THE Motor_Vision SHALL incluir en las observaciones una mención explícita de posible ictericia
6. WHEN el estado_general es requiere_atencion o urgente, THE Motor_Vision SHALL incluir en las recomendaciones la indicación de consultar a un pediatra
7. WHEN el análisis es completado, THE Backend_API SHALL almacenar el resultado en el Almacen_Resultados asociado a la Sesion correspondiente

### Requisito 4: Rendimiento del Análisis Visual

**User Story:** Como padre primerizo, quiero recibir el resultado del análisis rápidamente, para no tener que esperar con ansiedad.

#### Criterios de Aceptación

1. WHEN una imagen es enviada para análisis, THE Backend_API SHALL completar el procesamiento y retornar el resultado en menos de 5 segundos
2. THE Backend_API SHALL tener un tiempo de arranque en frío (cold start) inferior a 3 segundos
3. THE Backend_API SHALL mantener una disponibilidad mínima del 99.9% medida mensualmente mediante Amazon CloudWatch

### Requisito 5: Análisis de Audio en iOS

**User Story:** Como padre primerizo con iPhone, quiero que la app analice el llanto de mi bebé en tiempo real sin conexión a internet, para obtener orientación inmediata.

#### Criterios de Aceptación

1. WHEN el usuario inicia la grabación de audio en iOS, THE Sistema_BabyHealth SHALL capturar exactamente 7 segundos de audio
2. WHEN la grabación se completa en iOS, THE Motor_Audio_iOS SHALL clasificar el llanto utilizando el modelo DeepInfant V2 vía CoreML sin conexión a internet
3. THE Motor_Audio_iOS SHALL clasificar el audio en una de las 9 Categorias_Llanto: hambre, dolor, cansancio, incomodidad, eructo, temperatura, miedo, soledad o desconocido
4. WHEN la clasificación es completada, THE Motor_Audio_iOS SHALL retornar la categoría, etiqueta en español, valor de confianza y recomendación asociada
5. THE Motor_Audio_iOS SHALL completar la clasificación en menos de 1 segundo desde el fin de la grabación
6. THE Motor_Audio_iOS SHALL mantener una precisión de clasificación superior al 85% en condiciones controladas
7. WHILE el dispositivo iOS no tiene conexión a internet, THE Motor_Audio_iOS SHALL funcionar con capacidad completa de clasificación de llanto

### Requisito 6: Análisis de Audio en Android

**User Story:** Como padre primerizo con Android, quiero que la app analice el llanto de mi bebé, para entender qué necesita.

#### Criterios de Aceptación

1. WHEN el usuario inicia la grabación de audio en Android, THE Sistema_BabyHealth SHALL capturar exactamente 7 segundos de audio
2. WHEN la grabación se completa en Android, THE Motor_Audio_Android SHALL utilizar YAMNet TFLite para detectar si el audio contiene llanto de bebé
3. IF YAMNet no detecta llanto de bebé en el audio, THEN THE Motor_Audio_Android SHALL retornar el mensaje "No se detecta llanto de bebé" sin intentar clasificar
4. WHEN YAMNet detecta llanto, THE Motor_Audio_Android SHALL enviar el espectrograma al Backend_API para clasificación mediante Bedrock
5. WHEN la clasificación es completada, THE Motor_Audio_Android SHALL retornar la categoría, etiqueta en español, valor de confianza y recomendación asociada

### Requisito 7: Umbral de Confianza en Audio

**User Story:** Como padre primerizo, quiero que la app solo me muestre resultados cuando tiene suficiente certeza, para no recibir información poco confiable.

#### Criterios de Aceptación

1. IF el valor de confianza de la clasificación de audio es inferior al Umbral_Confianza definido, THEN THE Sistema_BabyHealth SHALL clasificar el resultado como categoría "desconocido"
2. WHEN la categoría resultante es "desconocido", THE Sistema_BabyHealth SHALL mostrar un mensaje indicando que no fue posible determinar la causa del llanto con suficiente certeza
3. WHEN la categoría resultante es "desconocido", THE Sistema_BabyHealth SHALL sugerir al usuario intentar una nueva grabación en un ambiente con menos ruido

### Requisito 8: Privacidad de Audio en iOS

**User Story:** Como padre primerizo, quiero que el audio de mi bebé nunca salga de mi dispositivo, para proteger la privacidad de mi familia.

#### Criterios de Aceptación

1. THE Motor_Audio_iOS SHALL procesar todo el audio exclusivamente en el dispositivo sin transmitir datos de audio a servidores externos
2. THE Sistema_BabyHealth SHALL eliminar el buffer de audio del dispositivo iOS inmediatamente después de completar la clasificación
3. THE Sistema_BabyHealth SHALL no almacenar grabaciones de audio en almacenamiento persistente del dispositivo iOS

### Requisito 9: Disclaimer Médico

**User Story:** Como padre primerizo, quiero ver claramente que esta es una herramienta de orientación y no un diagnóstico médico, para tomar decisiones informadas.

#### Criterios de Aceptación

1. THE Sistema_BabyHealth SHALL mostrar el Disclaimer_Medico en la pantalla de splash al iniciar la aplicación
2. THE Sistema_BabyHealth SHALL mostrar el Disclaimer_Medico en el footer de la pantalla principal
3. THE Sistema_BabyHealth SHALL incluir el Disclaimer_Medico en cada resultado de análisis visual y de audio
4. THE Motor_Vision SHALL incluir el campo disclaimer con el texto "Consulte a su pediatra" en cada respuesta JSON de análisis
5. THE Sistema_BabyHealth SHALL mostrar el texto completo del Disclaimer_Medico: "BabyHealth es una herramienta de orientación. Los resultados son informativos y NO sustituyen la consulta con un profesional de la salud. Ante cualquier duda o emergencia, consulte a su pediatra o acuda a urgencias."

### Requisito 10: Presentación de Resultados Visuales

**User Story:** Como padre primerizo, quiero ver los resultados del análisis de forma clara y comprensible, para saber rápidamente si debo preocuparme.

#### Criterios de Aceptación

1. WHEN un análisis visual es completado, THE Sistema_BabyHealth SHALL mostrar un indicador de semáforo con colores verde (normal), amarillo (requiere_atencion) y rojo (urgente)
2. WHEN un análisis visual es completado, THE Sistema_BabyHealth SHALL mostrar el título del estado, la lista de observaciones, la lista de recomendaciones y el porcentaje de confianza
3. THE Sistema_BabyHealth SHALL mostrar un botón "Nuevo Análisis" para iniciar otro flujo de captura
4. THE Sistema_BabyHealth SHALL mostrar un botón "Contactar Pediatra" que permita al usuario accionar un canal de contacto
5. WHEN el estado es urgente, THE Sistema_BabyHealth SHALL resaltar visualmente las recomendaciones con mayor prominencia

### Requisito 11: Presentación de Resultados de Audio

**User Story:** Como padre primerizo, quiero ver claramente qué tipo de llanto se detectó y qué puedo hacer, para responder adecuadamente a mi bebé.

#### Criterios de Aceptación

1. WHEN un análisis de audio es completado exitosamente, THE Sistema_BabyHealth SHALL mostrar la categoría de llanto detectada con su etiqueta en español
2. WHEN un análisis de audio es completado exitosamente, THE Sistema_BabyHealth SHALL mostrar la recomendación asociada a la categoría detectada
3. WHEN un análisis de audio es completado exitosamente, THE Sistema_BabyHealth SHALL mostrar el valor de confianza como porcentaje
4. THE Sistema_BabyHealth SHALL mostrar un botón "Grabar de Nuevo" para iniciar otra captura de audio

### Requisito 12: Manejo de Errores y Resiliencia

**User Story:** Como padre primerizo, quiero que la app maneje errores de forma amigable, para no quedarme sin orientación cuando algo falla.

#### Criterios de Aceptación

1. IF Amazon Bedrock no responde dentro de 10 segundos, THEN THE Backend_API SHALL reintentar la solicitud hasta 2 veces con espera exponencial
2. IF todos los reintentos a Bedrock fallan, THEN THE Backend_API SHALL retornar un mensaje amigable indicando que el servicio está temporalmente no disponible
3. IF la conexión a internet se pierde durante la carga de imagen, THEN THE Sistema_BabyHealth SHALL mostrar un mensaje indicando la falta de conexión y ofrecer reintentar
4. IF la URL_Prefirmada ha expirado antes de completar la carga, THEN THE Sistema_BabyHealth SHALL solicitar una nueva URL_Prefirmada automáticamente
5. IF ocurre un error inesperado en el Backend_API, THEN THE Backend_API SHALL registrar el error en Amazon CloudWatch con contexto suficiente para diagnóstico

### Requisito 13: Endpoint de Salud

**User Story:** Como equipo de operaciones, quiero verificar que el backend está funcionando correctamente, para monitorear la disponibilidad del servicio.

#### Criterios de Aceptación

1. WHEN se recibe una solicitud GET en /health, THE Backend_API SHALL retornar un JSON con status "ok" y la versión actual del servicio
2. THE Backend_API SHALL responder al endpoint /health en menos de 500 milisegundos

### Requisito 14: Endpoint de Análisis de Audio para Android

**User Story:** Como desarrollador del módulo Android, quiero un endpoint que analice espectrogramas de audio, para completar la clasificación de llanto en la nube.

#### Criterios de Aceptación

1. WHEN se recibe una solicitud POST en /analyze-audio con un s3_key válido, THE Backend_API SHALL descargar el espectrograma del Almacen_Imagenes y enviarlo a Bedrock para clasificación
2. WHEN la clasificación es exitosa, THE Backend_API SHALL retornar un JSON con los campos: category, label, confidence y recommendation
3. IF el s3_key proporcionado no existe en el Almacen_Imagenes, THEN THE Backend_API SHALL retornar un error con código 404 y mensaje descriptivo
4. IF el archivo en s3_key no es un espectrograma válido, THEN THE Backend_API SHALL retornar un error con código 400 y mensaje descriptivo

### Requisito 15: Seguridad y Acceso a la API

**User Story:** Como equipo de desarrollo, quiero que la API esté protegida contra uso no autorizado y abuso, para garantizar la disponibilidad del servicio.

#### Criterios de Aceptación

1. THE Backend_API SHALL configurar CORS permitiendo únicamente los orígenes autorizados de la aplicación
2. THE Backend_API SHALL implementar throttling en API Gateway para limitar solicitudes por IP
3. THE Almacen_Imagenes SHALL configurar políticas de expiración automática para eliminar imágenes después de 24 horas
4. THE Backend_API SHALL validar que todos los parámetros de entrada cumplan con los esquemas definidos antes de procesarlos
5. THE Almacen_Imagenes SHALL denegar acceso público directo a los objetos, permitiendo acceso únicamente mediante URLs pre-firmadas

### Requisito 16: Almacenamiento de Resultados

**User Story:** Como padre primerizo, quiero que mis análisis anteriores se guarden, para poder revisar el historial de evaluaciones de mi bebé.

#### Criterios de Aceptación

1. WHEN un análisis visual o de audio es completado exitosamente, THE Backend_API SHALL almacenar el resultado en el Almacen_Resultados con el session_id como clave primaria
2. THE Almacen_Resultados SHALL almacenar para cada resultado: session_id, tipo de análisis (visual/audio), resultado completo en JSON, y timestamp UTC
3. WHEN se consultan los resultados de una sesión, THE Backend_API SHALL retornar los resultados ordenados cronológicamente por timestamp descendente

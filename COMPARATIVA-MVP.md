# Comparativa técnica extensa

## Alcance

Ambos MVP responden sobre la misma guía técnica y deben usar únicamente el contexto recuperado, citar la página o fuente y rechazar preguntas fuera del alcance. La fuente canónica es el PDF incluido en `manuals/`.

## Resumen

| Criterio | mvp-completo | mvp-minimo |
|---|---|---|
| Objetivo | Plataforma ampliable | Validación funcional |
| API | ASP.NET Core 5077 | ASP.NET Core 5087 |
| Persistencia | PostgreSQL/pgvector + Neo4j | PostgreSQL |
| Recuperación | Full-text, vectorial y gráfica | Full-text e ILIKE |
| Embeddings | Ollama, vector(1024) | No |
| Indexación | Incremental mediante hash | Precargada en SQL |
| Trazabilidad | Ruta y fragmento | Página del PDF |
| Complejidad | Alta | Baja |
| Arranque | Más lento y pesado | Rápido y ligero |
| Evolución | Varias fuentes y relaciones | Un manual pequeño |

## MVP completo

Descubre documentos, calcula hashes, divide el texto con solapamiento y genera embeddings mediante Ollama. PostgreSQL/pgvector conserva documentos, chunks y vectores; Neo4j conserva relaciones entre documentos. La consulta puede combinar coincidencia textual, similitud semántica y grafo antes de pedir a Ollama una respuesta grounded.

Ventajas: admite nuevas fuentes, evita reindexaciones innecesarias, recupera reformulaciones y permite relacionar conceptos o versiones. Costes: cuatro servicios, más memoria, más latencia inicial, más puntos de fallo y mayor dificultad para garantizar una referencia exacta a una página del PDF.

## MVP mínimo

El esquema inicial crea `manuals`, `manual_chunks` y `cases`, carga el texto del manual y lo divide en 11 fragmentos por página. La API usa el índice full-text de PostgreSQL y una coincidencia literal de respaldo. Ollama sintetiza la respuesta; si no está disponible, se devuelve un fallback extractivo.

Ventajas: instalación sencilla, datos inspeccionables con SQL, referencias directas al PDF, bajo consumo y comportamiento predecible. Limitaciones: depende más de los términos de búsqueda, no tiene semántica vectorial, no tiene grafo y las actualizaciones requieren regenerar la carga inicial.

## Flujos

Completo: `documento -> hash -> chunks -> embeddings -> PostgreSQL/Neo4j -> recuperación híbrida -> Ollama`.

Mínimo: `PDF extraído -> chunks por página -> PostgreSQL -> full-text/ILIKE -> Ollama`.

En preguntas literales ambos deberían ser equivalentes. La ventaja del completo debe medirse con reformulaciones o con varias fuentes relacionadas, no asumirse por tener más componentes.

## Operación y aislamiento

El completo usa PostgreSQL 5432, Neo4j 7474/7687 y Ollama 11434. El mínimo usa PostgreSQL 5447 y expone la API en 5087. Cada Compose debe tener nombres y volúmenes propios. Los esquemas son incompatibles y nunca se debe reutilizar el volumen de PostgreSQL de un MVP en el otro.

Las credenciales son de desarrollo local. No se deben exponer PostgreSQL o Neo4j a Internet. El manual describe intervenciones sobre maquinaria, por lo que la interfaz debe mantener la recomendación de verificar valores y trabajar con seguridad antes de producción.

## Matriz de validación

| Área | Prueba | Resultado esperado |
|---|---|---|
| Exactitud | KG+ S, P/S/B, motores | Coincide con el manual |
| Cobertura | Las cinco averías | Contexto pertinente por avería |
| Fuente | Pregunta con página | La página contiene la evidencia |
| Reformulación | Sin términos exactos | Recuperación correcta |
| Rechazo | Azure, Docker, Neo4j | No alucina |
| Latencia | 20 preguntas | Medir p50 y p95 |
| Persistencia | Reinicio | Datos conservados |
| Actualización | Cambiar un documento | Incremental en el completo |

## Métricas y decisión

Medir exactitud factual, precisión de fuentes, cobertura, rechazo correcto, latencia p50/p95, tiempo de arranque, memoria Docker, tiempo de reindexación y tamaño de volúmenes.

El mínimo debe ser la referencia de regresión y la opción inicial para este manual. El completo se justifica sólo cuando una batería repetible demuestre mejora en recuperación, cobertura o mantenimiento. La evolución recomendada es medir primero, incorporar embeddings después y reservar Neo4j para relaciones que aporten respuestas demostrables.

# MVP mínimo - SQL-first

## Enfoque

Valida el valor de hacer preguntas sobre el manual con la mínima infraestructura nueva. La única fuente es `manuals/Guia_por_averias_orden_parametrizacion_S_B_P.pdf`.

- PostgreSQL como fuente de verdad.
- Texto dividido en 11 fragmentos por página.
- Búsqueda textual por términos.
- Ollama `qwen3:4b-instruct` para sintetizar.
- Respuestas breves con `Fuente: ...#page=N`.
- Sin Obsidian, Neo4j, pgvector, Graphiti, Zep ni casos inventados.

## Arranque

```powershell
cd mvp-minimo
docker compose up --build
```

Abrir: http://localhost:5087
PostgreSQL: localhost:5447

La primera ejecución descarga Ollama y puede tardar. Si el modelo aún no está disponible, la API usa un fallback extractivo hasta que termine.

## Pruebas

```powershell
Invoke-RestMethod http://localhost:5087/api/health
Invoke-RestMethod http://localhost:5087/api/manuals?q=KG
Invoke-RestMethod http://localhost:5087/api/chat -Method Post -ContentType 'application/json' -Body '{"message":"¿Qué valor debe tener KG+ del eje S?"}'
```

## Objetivo de comparación

Demostrar cuánto resultado se obtiene con SQL, fragmentación documental y un único modelo local antes de añadir RAG vectorial, grafo o servicios adicionales.
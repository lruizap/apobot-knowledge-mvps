# MVP completo - RAG ampliable

## Enfoque

Este MVP conserva la arquitectura avanzada del proyecto original, pero elimina la dependencia de Obsidian. La única fuente documental es `manuals/Guia_por_averias_orden_parametrizacion_S_B_P.pdf`, convertida a Markdown para que la API la indexe.

Está pensado para comparar una solución con más infraestructura y posibilidades de evolución:

- API .NET.
- PostgreSQL con pgvector y búsqueda full-text.
- Ollama para embeddings y generación.
- Neo4j para relaciones y grafo.
- Indexación incremental por hash.
- Recuperación vectorial y gráfica.

## Arranque

```powershell
cd mvp-completo
docker compose up --build
```

API: http://localhost:5077
PostgreSQL: localhost:5432
Neo4j Browser: http://localhost:7474

Después de que Ollama termine de descargar los modelos:

```powershell
Invoke-RestMethod http://localhost:5077/api/knowledge/index -Method Post
Invoke-RestMethod http://localhost:5077/api/knowledge/health
Invoke-RestMethod http://localhost:5077/api/knowledge/graph
```

## Qué comparar

- Tiempo de arranque.
- Consumo de memoria.
- Tiempo de indexación.
- Calidad de recuperación.
- Calidad de respuestas.
- Valor real aportado por pgvector y Neo4j.

## Limitaciones

La fuente se indexa desde Markdown extraído del PDF; el PDF original se conserva para trazabilidad. El contenido visual del PDF no se interpreta automáticamente en esta versión.
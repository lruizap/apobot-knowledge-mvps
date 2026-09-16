# PersonalKnowledgeAI.Api

API local del MVP para buscar conocimiento en la boveda de Obsidian.

## Ejecutar

Desde la raiz de la boveda:

```powershell
dotnet run --project src/PersonalKnowledgeAI.Api --urls http://127.0.0.1:5077
```

## Endpoints

- `GET /api/knowledge/health`
- `GET /api/knowledge/search?q=memoria&limit=5`

La API busca archivos `.md` en la raiz de la boveda e ignora `.obsidian`, `.git`, `bin` y `obj`.

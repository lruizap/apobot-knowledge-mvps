# APObot Knowledge MVPs

Dos implementaciones independientes para consultar exclusivamente la guía técnica de averías de los ejes P/S/B, correas, motores, cuernecillos y barrera de luz. La única fuente es el manual PDF incluido en el repositorio.

## Proyectos

| Proyecto | Propósito | Servicios | Puertos |
|---|---|---|---|
| `mvp-completo` | RAG ampliable | .NET, PostgreSQL/pgvector, Ollama, Neo4j | API 5077, PostgreSQL 5432, Neo4j 7474/7687 |
| `mvp-minimo` | Validación rápida y trazable | .NET, PostgreSQL, Ollama | API 5087, PostgreSQL 5447 |

## Requisitos

Docker Desktop con Compose v2, 8 GB de RAM y conexión a Internet para descargar las imágenes y `qwen3:4b-instruct`.

```powershell
docker --version
docker compose version
```

## Instalación y ejecución

MVP completo:

```powershell
cd mvp-completo
docker compose up --build
```

Abrir `http://localhost:5077`. Neo4j queda en `http://localhost:7474`.

MVP mínimo:

```powershell
cd mvp-minimo
docker compose up --build
```

Abrir `http://localhost:5087`.

Detener o reinicializar un proyecto:

```powershell
docker compose down
# Borra también los datos persistidos:
docker compose down -v
```

Los dos proyectos usan volúmenes y bases independientes; no deben mezclarse.

## Pruebas

Pregunta principal:

```text
¿Qué valor debe tener KG+ del eje S?
```

Debe responder `340` y citar la página correspondiente. Probar también parametrización P/S/B, cambio de correa 20↔16, barrera de luz, motores paso a paso y ultrasonido.

Prueba fuera de alcance:

```text
¿Cómo se configura Azure?
```

Debe responder que el manual no contiene información suficiente, sin inventar datos.

Healthchecks:

```powershell
Invoke-RestMethod http://localhost:5077/api/knowledge/health
Invoke-RestMethod http://localhost:5077/api/knowledge/graph
Invoke-RestMethod http://localhost:5087/api/health
Invoke-RestMethod 'http://localhost:5087/api/manuals?q=KG%2B'
```

## Solución de problemas

- Si Ollama no descarga el modelo, revisar la conexión y repetir `docker compose up`.
- Si un puerto está ocupado, cambiar sólo el puerto externo de la izquierda en `ports`.
- Si se cambia el modelo de embeddings del completo, revisar `vector(1024)` y reindexar.
- Si aparecen datos antiguos, usar `docker compose down -v` en el MVP afectado.
- Las credenciales incluidas son sólo para desarrollo local.

## Documentación

- [Guía del MVP completo](mvp-completo/README.md)
- [Guía del MVP mínimo](mvp-minimo/README.md)
- [Comparativa técnica extensa](COMPARATIVA-MVP.md)
- [Informe técnico](docs/Informe_Tecnico_IA_Memoria_APObot_v2.pdf)



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

## Ollama: instalación, modelo y ejecución

### Qué es Ollama

Ollama es un runtime local que descarga y ejecuta modelos de lenguaje en el propio equipo y expone una API HTTP. En estos MVP permite procesar el manual sin enviarlo a un proveedor externo ni pagar por tokens. El coste real es hardware, memoria, almacenamiento y electricidad.

### Modelo elegido y para qué sirve

El modelo de generación elegido es `qwen3:4b-instruct`. Ofrece un equilibrio adecuado entre calidad, consumo y latencia para un prototipo técnico. Sigue instrucciones, sintetiza respuestas breves a partir de fragmentos recuperados y permite limitar temperatura y longitud para reducir desviaciones.

El modelo no es la fuente de verdad: sólo redacta usando el contexto recuperado desde PostgreSQL. Si el contexto no responde, la aplicación debe indicar que no hay información suficiente.

El `mvp-completo` utiliza además `qwen3-embedding:0.6b` para convertir fragmentos y preguntas en vectores de búsqueda. El `mvp-minimo` sólo usa `qwen3:4b-instruct`; recupera mediante SQL full-text.

### Ejecución con Docker Compose

No es obligatorio instalar Ollama nativamente. Cada Compose crea un servicio `ollama` y un `ollama-init` que descarga los modelos.

```powershell
cd mvp-completo
docker compose up --build
```

O bien:

```powershell
cd mvp-minimo
docker compose up --build
```

Dentro de Docker, la API usa `http://ollama:11434`; no es necesario instalar ni ejecutar Ollama fuera de Docker. Consultar estado y logs:

```powershell
docker compose ps
docker compose exec ollama ollama list
docker compose logs -f ollama-init
```

Si Ollama aún está descargando, esperar a que termine `ollama-init`. El mínimo dispone de fallback extractivo; el completo necesita el embedding disponible para indexar vectores.

### Configuración

```text
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODEL=qwen3:4b-instruct
OLLAMA_EMBEDDING_MODEL=qwen3-embedding:0.6b
```

### Costes y rendimiento

Ollama y los modelos se ejecutan localmente sin coste por petición. Sí existe coste operativo: CPU/GPU, RAM, disco y electricidad. `qwen3:4b-instruct` se ha escogido para mantener bajos esos requisitos; una GPU compatible puede reducir la latencia, pero no es necesaria para validar el flujo. El volumen de Ollama puede ocupar varios GB y debe conservarse si se quieren evitar nuevas descargas.

Referencias: [Ollama](https://ollama.com/), [biblioteca de modelos](https://ollama.com/library).

## Estado para revisión

| Área | Estado |
|---|---|
| MVP mínimo | Funcional |
| MVP completo | Prototipo funcional |
| Ollama integrado en Docker | Implementado |
| Validación Compose | Automatizada |
| Build de ambas APIs | Automatizado en GitHub Actions |
| Smoke tests | Disponibles en `scripts/` |
| Uso en producción | Pendiente de hardening, secretos y observabilidad |

`cases` en el MVP mínimo queda preparado para registrar casos técnicos validados en una fase posterior; no participa todavía en la recuperación del manual.
## Documentación

- [Guía del MVP completo](mvp-completo/README.md)
- [Guía del MVP mínimo](mvp-minimo/README.md)
- [Comparativa técnica extensa](COMPARATIVA-MVP.md)
- [Informe técnico](docs/Informe_Tecnico_IA_Memoria_APObot_v2.pdf)`r`n- [Costes técnicos del proyecto](COSTES-PROYECTO.md)







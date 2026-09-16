# MVP completo — RAG ampliable

## 1. Propósito y alcance

Este MVP implementa un asistente técnico sobre `manuals/Guia_por_averias_orden_parametrizacion_S_B_P.pdf`. El PDF es la fuente documental; la copia Markdown sirve como representación indexable y el PDF original se conserva para trazabilidad. El objetivo es evaluar una arquitectura preparada para crecer en documentos, consultas semánticas, relaciones y reindexación incremental.

No es automáticamente una solución industrial: las respuestas deben verificarse contra la máquina y el manual antes de actuar.

## 2. Contenido del MVP

- `src/PersonalKnowledgeAI.Api`: API ASP.NET Core, interfaz web y endpoints de salud, búsqueda, chat e indexación.
- `docker-compose.yml`: API, PostgreSQL/pgvector, Ollama y Neo4j.
- `docker/postgres/init.sql`: extensión vector y tablas de documentos/chunks.
- `manuals/`: PDF y texto derivado.
- `Dockerfile`: compilación reproducible multi-stage con .NET 10.

Flujo:

```text
documentos -> hash -> chunks con solapamiento -> embeddings Ollama
           -> PostgreSQL/pgvector + relaciones Neo4j
pregunta -> recuperación textual/vectorial/gráfica -> contexto -> Ollama -> respuesta
```

## 3. Tecnología y motivo de elección

### .NET 10 / ASP.NET Core

Aporta un runtime multiplataforma, tipado fuerte, inyección de dependencias, HTTP y hosting integrado. Es adecuado para una API local con baja fricción de despliegue. Frente al MVP mínimo usa el mismo runtime, por lo que la diferencia no es el lenguaje sino la infraestructura y el pipeline de recuperación.

### PostgreSQL

Es la fuente transaccional de documentos y fragmentos. Su búsqueda full-text ofrece un baseline explicable y pgvector añade similitud coseno. Se elige para evitar una base vectorial adicional. Frente al mínimo comparte PostgreSQL, pero aquí añade vectores, hashes e indexación incremental.

### pgvector

Permite almacenar embeddings junto al texto y filtrar/ordenar por similitud sin introducir otro motor. El esquema actual usa `vector(1024)`: cambiar el modelo exige migración y reindexación. Frente al mínimo resuelve reformulaciones semánticas, pero añade coste de CPU, almacenamiento y complejidad de tuning.

### Ollama

Ejecuta localmente el modelo de generación y el modelo de embeddings, manteniendo el contenido en el equipo. Reduce dependencia de APIs externas y coste por token. El precio monetario del software es cero, pero el consumo real es CPU/GPU, RAM, almacenamiento y electricidad. Frente al mínimo usa Ollama dos veces: síntesis y embeddings.

### Neo4j

Representa enlaces y entidades como nodos y relaciones. Es útil si aparecen manuales versionados, componentes relacionados o trazabilidad entre procedimientos. En este manual pequeño puede aportar poco: frente al mínimo añade un servicio, memoria, backup y una superficie operativa adicional.

### Docker Compose

Aísla versiones, redes, variables y volúmenes. Permite reproducir el entorno en otro equipo. Docker Engine y las imágenes open source no tienen coste de licencia; Docker Desktop Personal es gratuito para uso personal, mientras que los planes profesionales/empresariales pueden requerir suscripción según tamaño y tipo de organización.

## 4. Instalación y ejecución

Requisitos: Docker Desktop con Compose v2, mínimo 8 GB de RAM disponibles y conexión inicial para descargar imágenes/modelos.

```powershell
cd mvp-completo
docker compose up --build
```

Abrir:

- API: http://localhost:5077
- PostgreSQL: `localhost:5432`
- Neo4j Browser: http://localhost:7474

Cuando Ollama esté listo, indexar:

```powershell
Invoke-RestMethod http://localhost:5077/api/knowledge/index -Method Post -ContentType 'application/json' -Body '{}'
Invoke-RestMethod http://localhost:5077/api/knowledge/health
Invoke-RestMethod http://localhost:5077/api/knowledge/graph
```

Detener:

```powershell
docker compose down
```

Borrar datos persistidos y empezar de cero:

```powershell
docker compose down -v
```

## 5. Costes y precios

Coste de licencia estimado: `0 €` para .NET, PostgreSQL, pgvector, Neo4j Community, Ollama, el código propio y las imágenes open source. Esto no incluye obligaciones de marca, soporte comercial ni una licencia de Docker Desktop si la organización cae fuera del uso gratuito.

Coste de operación local: normalmente `0 €/mes` adicionales si ya existe un PC encendido, pero hay consumo eléctrico. Como fórmula: `kW medios × horas × precio_kWh`. Una máquina de 0,15 kW durante 8 h/día consume unos 36 kWh/mes; a 0,20 €/kWh son aproximadamente 7,20 €/mes. Es una estimación, no una tarifa contractual.

Coste de hardware: un equipo sólo CPU puede funcionar pero será lento. Para respuestas cómodas, presupuestar 16–32 GB de RAM y, si se desea acelerar inferencia, una GPU con memoria suficiente para el modelo. El coste depende completamente del equipo existente.

Coste cloud orientativo: una VM con 4–8 vCPU y 16–32 GB RAM suele costar varias decenas de euros al mes antes de almacenamiento, tráfico, backups y GPU; una GPU puede multiplicar el coste. Neo4j Aura, almacenamiento gestionado y soporte tienen precios propios que deben consultar en sus calculadoras oficiales antes de contratar.

Coste de mantenimiento: alto relativo al mínimo. Hay que vigilar cuatro servicios, volúmenes, backups PostgreSQL/Neo4j, compatibilidad del modelo de embeddings y reindexaciones.

## 6. Comparación con `mvp-minimo`

Gana el completo cuando se necesitan preguntas reformuladas, muchas fuentes, relaciones o actualización incremental. Pierde cuando el corpus es pequeño y la prioridad es trazabilidad, arranque rápido, bajo consumo y diagnóstico simple. Para este manual, pgvector y Neo4j sólo están justificados si una batería de pruebas demuestra mejora medible.

## 7. Pruebas técnicas

Medir tiempo de build, arranque hasta healthcheck, memoria por contenedor, tiempo de indexación inicial, tiempo de reindexación sin cambios, latencia p50/p95 y exactitud de fuentes. Probar `KG+ del eje S = 340`, las cinco averías, preguntas reformuladas y preguntas fuera de alcance.

## 8. Limitaciones y operación

El texto visual del PDF no se interpreta automáticamente. No exponer PostgreSQL, Neo4j u Ollama a Internet. Cambiar contraseñas antes de cualquier despliegue real. Si cambia el modelo de embeddings, revisar `vector(1024)` y regenerar todos los vectores.

## 9. Referencias de precios

- [Docker Pricing](https://www.docker.com/pricing/)
- [PostgreSQL License y FAQ](https://www.postgresql.org/about/press/faq/)
- [Ollama](https://ollama.com/)
- [Neo4j Pricing](https://neo4j.com/pricing/)

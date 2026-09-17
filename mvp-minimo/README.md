# MVP mínimo — SQL-first

## 1. Propósito y alcance

Este MVP valida el caso de uso con la menor infraestructura razonable. Consulta exclusivamente `manuals/Guia_por_averias_orden_parametrizacion_S_B_P.pdf`, cargado en PostgreSQL como un manual y 11 fragmentos identificados por página. Es la referencia funcional para medir si hace falta una arquitectura RAG más compleja.

## 2. Contenido del MVP

- `src/ApobotMinimal.Api`: API ASP.NET Core, interfaz, healthcheck, búsqueda y chat.
- `docker-compose.yml`: API, PostgreSQL y Ollama.
- `docker/postgres/init.sql`: esquema, índices y carga reproducible del manual.
- `manuals/`: PDF fuente.
- `Dockerfile`: build multi-stage .NET 10.

Flujo:

```text
PDF extraído -> manual_chunks por página -> PostgreSQL full-text
pregunta -> búsqueda de términos/ILIKE -> contexto -> Ollama -> respuesta
```

Si Ollama aún no responde, la API utiliza un fallback extractivo. Esto permite probar recuperación y fuentes antes de depender de la generación.

## 3. Tecnología y motivo de elección

### .NET 10 / ASP.NET Core

Proporciona API HTTP, hosting y tipado fuerte con una distribución sencilla. Frente al completo es equivalente: el coste y rendimiento de la API son comparables; la diferencia está en que el mínimo no añade indexador semántico ni grafo.

### PostgreSQL

Es la única fuente de verdad operativa. `manual_chunks` conserva página, sección, contenido y fuente. Los índices GIN permiten búsquedas full-text sin un motor adicional. Frente al completo evita pgvector, tablas de embeddings y tuning vectorial, a cambio de depender más de las palabras de la pregunta.

### Ollama y `qwen3:1.7b`

Genera respuestas breves usando el contexto recuperado. Se ejecuta localmente y no cobra por petición; el coste es computacional. Frente al completo se usa para síntesis, pero no para embeddings, por lo que descarga, RAM y tiempo de indexación son menores.

### Docker Compose

Hace reproducible la API, base y modelo. El MVP tiene tres servicios y menos volúmenes. Frente al completo reduce puntos de fallo, consumo y tiempo de diagnóstico.

### SQL full-text e `ILIKE`

El índice GIN hace explícita la evidencia y resulta suficiente para un manual de 11 páginas. `ILIKE` actúa como respaldo para coincidencias literales. Frente a la búsqueda vectorial del completo ofrece menos tolerancia a sinónimos, pero es más fácil de auditar con SQL.

## 4. Instalación y ejecución

Requisitos: Docker Desktop con Compose v2, 4–8 GB de RAM disponibles y conexión inicial para descargar la imagen/modelo.

```powershell
cd mvp-minimo
docker compose up --build
```

Abrir: http://localhost:5087

PostgreSQL queda en `localhost:5447`. Ollama sólo se expone dentro de Compose. La primera ejecución puede tardar mientras descarga el modelo.

Pruebas:

```powershell
Invoke-RestMethod http://localhost:5087/api/health
Invoke-RestMethod http://localhost:5087/api/manuals?q=KG
Invoke-RestMethod http://localhost:5087/api/chat -Method Post -ContentType 'application/json' -Body '{"message":"¿Qué valor debe tener KG+ del eje S?"}'
```

Detener o reinicializar:

```powershell
docker compose down
# Borra también la base persistida:
docker compose down -v
```

## 5. Costes y precios

Coste de licencia estimado: `0 €` para .NET, PostgreSQL, Ollama, el código propio y las imágenes open source. Docker Desktop Personal es gratuito para uso personal; empresas que no cumplan las condiciones del plan gratuito pueden necesitar Docker Pro, Team o Business. Consultar el precio actual antes de comprar.

Coste local: menor que el completo porque no ejecuta Neo4j ni embeddings. Como referencia de electricidad, una máquina de 0,08 kW durante 8 h/día consume unos 19,2 kWh/mes; a 0,20 €/kWh son aproximadamente 3,84 €/mes. Es sólo una hipótesis para comparar órdenes de magnitud.

Coste hardware: 8–16 GB RAM suelen ser suficientes para este MVP, aunque la velocidad depende de CPU/GPU y del modelo. No necesita GPU dedicada para validar el flujo, pero una GPU reduce la latencia.

Coste cloud orientativo: una VM pequeña con 2–4 vCPU y 8–16 GB RAM suele estar en el orden de decenas de euros mensuales según proveedor y región. Añadir backups, disco, tráfico, monitorización y una GPU cambia radicalmente el total. El mínimo permite empezar en local sin coste recurrente.

Coste de mantenimiento: bajo. La actualización principal consiste en regenerar el SQL o el proceso de carga cuando cambia el PDF; no hay grafo, dimensión vectorial ni pipeline híbrido que mantener.

## 6. Comparación con `mvp-completo`

Gana el mínimo para un manual pequeño, respuestas literales, trazabilidad por página, demostraciones, equipos modestos y soporte sencillo. Pierde en reformulaciones, búsqueda semántica, relaciones entre documentos y actualización incremental. Es la opción recomendada para establecer una línea base cuantitativa antes de pagar complejidad operativa.

## 7. Pruebas y criterios de aceptación

Debe devolver `340` para KG+ del eje S, recuperar las cinco averías, citar la página correcta y rechazar preguntas sobre tecnología no descrita. Medir exactitud, precisión de fuente, cobertura, rechazo correcto, latencia p50/p95, tiempo de arranque y memoria.

La prueba clave es comparar las mismas preguntas contra el completo. Si el mínimo obtiene la misma exactitud y trazabilidad, no hay justificación técnica para añadir pgvector y Neo4j todavía.

## 8. Limitaciones y seguridad

La búsqueda depende de términos presentes en el texto. El SQL inicial contiene datos precargados y no es un sistema general de ingestión. Las credenciales son de desarrollo, no exponer PostgreSQL públicamente y verificar siempre las instrucciones técnicas en la máquina.

## 9. Referencias de precios

- [Docker Pricing](https://www.docker.com/pricing/)
- [PostgreSQL License y FAQ](https://www.postgresql.org/about/press/faq/)
- [Ollama](https://ollama.com/)

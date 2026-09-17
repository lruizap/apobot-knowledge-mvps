# Costes técnicos del proyecto

## 1. Objetivo

Este documento estima el coste total de ejecutar los dos MVP del repositorio y compara tres estrategias:

1. Modelo local con Ollama.
2. Modelo servido por una API externa.
3. Arquitectura híbrida: datos y recuperación local, generación externa sólo cuando sea necesario.

Las cifras son presupuestos de ingeniería, no ofertas comerciales. El precio final depende del proveedor, región, volumen, retención, impuestos y hardware ya disponible.

## 2. Resumen ejecutivo

| Escenario | Coste fijo | Coste variable | Privacidad | Complejidad | Recomendación |
|---|---:|---:|---|---|---|
| MVP mínimo local | Bajo | Electricidad y hardware | Alta | Baja | Punto de partida |
| MVP completo local | Bajo/medio | Electricidad y hardware | Alta | Alta | Sólo si aporta mejora medida |
| API externa | Bajo local | Por tokens/embeddings | Depende del proveedor | Media | Picos de uso o modelo superior |
| Híbrido | Bajo | Electricidad + API | Media/alta | Media/alta | Equilibrio operativo |

Para este manual, el MVP mínimo local suele ser el coste total más bajo y el más fácil de auditar. El completo consume más memoria y añade Neo4j, pgvector y embeddings; sólo compensa si mejora la recuperación de forma demostrable.

## 3. Qué se paga realmente

Hay que separar cinco partidas:

- **Licencias:** software, modelos y herramientas.
- **Cómputo:** CPU, RAM y GPU.
- **Almacenamiento:** imágenes, modelos, bases, índices y backups.
- **Red:** descargas iniciales, tráfico y llamadas a APIs.
- **Operación:** mantenimiento, monitorización, copias, actualizaciones y soporte.

Que un componente sea open source no significa que el sistema sea gratis: se paga la máquina, el tiempo técnico y la disponibilidad.

## 4. Memoria y recursos por MVP

Las siguientes cifras son rangos de planificación para Docker Desktop, no límites exactos. La memoria real depende de la carga, número de conexiones, tamaño del contexto y si Ollama utiliza CPU o GPU.

### MVP mínimo

| Componente | RAM orientativa | CPU | Disco inicial | Función |
|---|---:|---:|---:|---|
| API .NET | 150–500 MB | 0.1–1 vCPU | 0.2–0.5 GB | HTTP, recuperación y síntesis |
| PostgreSQL | 250–800 MB | 0.2–1 vCPU | 0.1–1 GB + datos | Manual y 11 chunks |
| Ollama + modelo 4B | 3–6 GB | 2–4 vCPU o GPU | varios GB | Generación |
| Docker Desktop/WSL2 | 1–3 GB | overhead | variable | Runtime |
| **Total recomendado** | **8 GB mínimo; 12–16 GB cómodo** | **4 cores** | **10 GB libres** | Desarrollo local |

El mínimo no crea embeddings. Por eso su indexación es barata: inserta los fragmentos y consulta índices GIN de PostgreSQL.

### MVP completo

| Componente | RAM orientativa | CPU | Disco inicial | Función |
|---|---:|---:|---:|---|
| API .NET | 200–700 MB | 0.1–1 vCPU | 0.5 GB | API e indexador |
| PostgreSQL/pgvector | 500 MB–2 GB | 0.5–2 vCPU | 1–10 GB | Texto, vectores e índices |
| Ollama generador 4B | 3–6 GB | 2–4 vCPU o GPU | varios GB | Respuestas |
| Ollama embeddings | 0.5–2 GB | 1–2 vCPU o GPU | cientos de MB–varios GB | Vectores |
| Neo4j | 1–3 GB | 0.5–2 vCPU | 1–10 GB | Grafo, índices y logs |
| Docker Desktop/WSL2 | 1–3 GB | overhead | variable | Runtime |
| **Total recomendado** | **16 GB mínimo; 24–32 GB cómodo** | **6–8 cores** | **20–40 GB libres** | Desarrollo serio |

Los servicios no necesariamente consumen el máximo simultáneamente, pero Ollama y Neo4j pueden coincidir durante indexación o consultas. Para producción pequeña conviene fijar límites de memoria y observarlos antes de dimensionar.

## 5. Almacenamiento

El coste de datos del manual es pequeño. El consumo importante procede de imágenes Docker y modelos Ollama. Deben presupuestarse:

- Imágenes base de .NET, PostgreSQL, pgvector, Neo4j y Ollama.
- Modelo de generación `qwen3:1.7b`.
- Modelo `qwen3-embedding:0.6b` sólo en el completo.
- Volúmenes PostgreSQL y Neo4j.
- Logs, capas de build y cachés.
- Copias de seguridad.

Para una instalación limpia reservaría 10 GB para el mínimo y 20–40 GB para el completo. Son cifras de planificación; medir con `docker system df` después del primer arranque.

```powershell
docker system df
docker volume ls
```

## 6. Coste local con Ollama

Ollama evita pagar una tarifa por petición y mantiene los datos en el equipo. El coste mensual aproximado de electricidad se calcula así:

```text
coste mensual = kW medios × horas/día × días/mes × precio por kWh
```

Ejemplo mínimo: 0,08 kW durante 8 horas diarias y 30 días, a 0,20 €/kWh:

```text
0,08 × 8 × 30 × 0,20 = 3,84 €/mes
```

Ejemplo completo: 0,15 kW durante 8 horas diarias:

```text
0,15 × 8 × 30 × 0,20 = 7,20 €/mes
```

Si se usa GPU, el consumo puede ser considerablemente mayor. Si el equipo ya está encendido por otros motivos, el coste incremental del proyecto será menor que el consumo total medido.

Coste de hardware: `0 €` incremental si se reutiliza un equipo adecuado. Si hay que comprarlo, el presupuesto debe incluir RAM, SSD, GPU opcional, ventilación y sustitución/amortización. Para este modelo no recomiendo comprar una GPU antes de medir la latencia CPU.

## 7. Coste de API externa

En el escenario API, PostgreSQL, Docker y la lógica siguen locales, pero la generación se envía a un proveedor. El coste variable se aproxima por tokens:

```text
coste = (tokens entrada / 1.000.000 × precio entrada)
      + (tokens salida / 1.000.000 × precio salida)
```

Hay que contar como entrada la pregunta más todos los fragmentos recuperados y las instrucciones. Una consulta RAG puede enviar mucho más texto que una conversación corta.

### Ventajas

- Menor RAM/GPU local.
- Modelos potencialmente más capaces.
- Escalado sencillo por concurrencia.
- Sin descarga ni mantenimiento local del modelo.

### Costes y riesgos

- Pago recurrente por tokens y embeddings.
- Dependencia de conectividad y disponibilidad del proveedor.
- Revisión legal y de privacidad del manual enviado.
- Coste impredecible si no se aplican límites, cuotas y alertas.
- Posible coste adicional por almacenamiento vectorial gestionado.

El precio concreto debe tomarse de la página oficial del proveedor elegido en el momento de contratar. Por ejemplo, [OpenAI API Pricing](https://platform.openai.com/pricing) publica precios por modelo y modalidad; no se debe copiar un precio histórico al presupuesto sin verificarlo.

## 8. Escenario híbrido

Una arquitectura híbrida mantiene PostgreSQL y la recuperación local, pero usa API externa sólo para preguntas complejas o cuando Ollama no está disponible.

```text
pregunta -> recuperación local ->
  respuesta local si la confianza es suficiente
  API externa si falta capacidad o calidad
```

El híbrido reduce el coste medio si la mayoría de las preguntas se resuelven localmente, pero introduce dos flujos de seguridad, dos métricas de calidad y reglas para decidir cuándo se envían datos fuera del equipo. Deben registrarse proveedor, modelo, tokens y motivo del fallback.

## 9. Licencias y servicios

- .NET, PostgreSQL y pgvector: sin coste de licencia por uso del software; PostgreSQL usa una licencia permisiva.
- Ollama y modelos locales: sin coste por petición local; revisar siempre la licencia específica del modelo antes de redistribuirlo comercialmente.
- Neo4j Community: puede ejecutarse localmente sin el precio de un servicio gestionado; el soporte, edición y alojamiento gestionado son partidas separadas.
- Docker Engine e imágenes: sin coste de licencia del motor open source. Docker Desktop Personal es gratuito para uso personal y ciertos usos pequeños; Docker Pro aparece actualmente desde 9 USD/usuario/mes con facturación anual o 11 USD mensual en su página de precios. La elegibilidad empresarial debe revisarse en los términos oficiales.
- GitHub: el repositorio puede ser público sin coste de alojamiento básico; CI, almacenamiento adicional y runners pueden tener límites o cargos según el plan.

Referencias: [Docker Pricing](https://www.docker.com/pricing/), [licencia de Docker Desktop](https://docs.docker.com/subscription-billing/desktop-license/), [Ollama](https://ollama.com/), [PostgreSQL FAQ](https://www.postgresql.org/about/press/faq/) y [Neo4j Pricing](https://neo4j.com/pricing/).

## 10. Coste de operación mensual orientativo

| Partida | Mínimo local | Completo local | API/híbrido |
|---|---:|---:|---:|
| Licencias open source | 0 € | 0 € | 0 € local |
| Docker Desktop | 0 € personal/elegible | 0 € personal/elegible | Igual |
| Electricidad incremental | ~4–10 € | ~7–25 € | Menor local, más API |
| API de generación | 0 € | 0 € | Variable por tokens |
| Backups | SSD local o coste del destino | Mayor por Neo4j + PostgreSQL | Igual + posible backup gestionado |
| Soporte/mantenimiento | Bajo | Medio/alto | Medio por dependencia externa |

Los rangos eléctricos son ejemplos calculados, no una factura prevista. Un servidor encendido 24/7 multiplica las horas: con 0,15 kW constantes y 0,20 €/kWh serían unos 21,60 €/mes sólo de electricidad.

## 11. Recomendación económica

1. Ejecutar el MVP mínimo local y medir RAM, latencia y exactitud.
2. Mantenerlo como baseline y entorno de demostración.
3. Activar el completo sólo si pgvector o Neo4j mejoran preguntas reformuladas, cobertura o mantenimiento.
4. Considerar API externa cuando la calidad o concurrencia requerida supere el hardware local.
5. Aplicar límites de tokens, presupuestos, logs y alertas antes de usar una API.
6. Revisar licencias del modelo, privacidad y retención de datos antes de enviar manuales a terceros.

Para el alcance actual, la opción con mejor relación coste/control es `mvp-minimo + Ollama en Docker`. El `mvp-completo` es una inversión de arquitectura, no un ahorro automático.

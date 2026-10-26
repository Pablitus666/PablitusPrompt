# ADR 0001 — Núcleo .NET para Pablitus Prompt Framework

- **Estado:** aceptado para la Fase 1
- **Fecha:** 2026-10-24
- **Contexto:** Pablitus Prompt Framework (PPF) es hoy un módulo de PowerShell 7
  con segmentos basados en scriptblocks, temas `.Theme.ps1` y renderers
  registrados en runtime.
- **Decisión estratégica:** evolucionar hacia un motor de prompt declarativo,
  asíncrono y extensible, con **núcleo .NET/C#**, **plugins PowerShell**,
  **configuración JSON con schema** e **importador de temas de Oh My Posh**.

## 1. Contexto

El motor actual funciona y debe seguir siendo el motor por defecto. Su flujo es:

```text
prompt -> Invoke-Prompt -> providers secuenciales -> pipeline
       -> segmentos (scriptblocks) -> renderer -> string ANSI
```

Las limitaciones relevantes para esta evolución son:

- Los temas son código PowerShell, no datos declarativos; no son portables fuera
  de PowerShell.
- La recolección de segmentos es secuencial en `Get-PromptSegments`.
- No existe un scheduler con timeouts por segmento ni cancelación cooperativa.
- El formato de temas no es compatible con Oh My Posh, aunque el repositorio ya
  incluye `src/Themes/Pablitus.omp.json`.
- La validación de configuración y temas no tiene un contrato único ni schema.

La Fase 1 es **aditiva**. No se modifica ningún archivo de `src/` ni de
`tests/`, no se altera la suite Pester y no se elimina ningún comportamiento
existente.

## 2. Decisión

Se crea un núcleo .NET 8 aislado en `dotnet/` con esta forma:

```text
dotnet/
  PablitusPrompt.sln
  Directory.Build.props
  src/
    PablitusPrompt.Core/     class library net8.0
    PablitusPrompt.Cli/      CLI ppf (net8.0)
  tests/
    PablitusPrompt.Core.Tests/  xUnit
```

El módulo PowerShell continúa siendo el motor por defecto. La integración con el
núcleo .NET será opt-in en una fase posterior (`PPF_USE_DOTNET_CORE=1`) y con
fallback al motor PowerShell.

### Capas del núcleo

```text
PpfConfig / ThemeConfig (JSON + System.Text.Json + validación)
  -> TemplateEngine (lexer + parser + AST + evaluación)
  -> SegmentScheduler (Task.WhenAll, timeout, cancelación, captura de errores)
  -> ISegmentProvider (session, path, git, text, time, exit)
  -> IRenderer (PlainRenderer, PowerLineRenderer)
  -> CLI ppf (import, validate, render, debug)
```

La CLI es un consumidor del núcleo, no una dependencia del módulo.

## 3. Modelo declarativo

Los documentos PPF se cargan con `System.Text.Json` y se validan en dos etapas:

1. **Deserialización:** errores de sintaxis o de tipo con `JsonException.Path`,
   línea y columna.
2. **Validación semántica:** errores con la ruta exacta del campo, por ejemplo
   `theme.blocks[0].segments[1].timeoutMs`.

Modelos principales:

- `PpfConfig`: renderer, `finalSpace`, caché, plantillas, tema embebido o bloques
  raíz.
- `ThemeConfig`: nombre, versión, procedencia, renderer sugerido, paleta, bloques.
- `BlockConfig`: tipo (`prompt`/`rprompt`), alineación, `newline`, segmentos.
- `SegmentConfig`: tipo, nombre, estilo, colores, plantilla, icono, timeouts,
  caché y propiedades del proveedor.
- `CacheConfig`: habilitación, TTL, máximo de entradas y directorio.
- `TemplateConfig`: plantillas reservadas de prompt, right prompt y transient
  prompt.

La validación compila además todas las plantillas, de modo que un error de
sintaxis se detecta al cargar el tema y no en el primer prompt.

### Schemas

- `schemas/ppf.schema.json`
- `schemas/theme.schema.json`

Ambos usan JSON Schema Draft 2020-12, `$id`, `$defs`, descripciones y ejemplos.
Cubren configuración, bloques, segmentos, estilos, colores, plantillas, caché y
timeouts. Los ejemplos de `examples/dotnet/` validan con `Test-Json`.

## 4. Motor de plantillas

Se implementó un lexer y un parser recursivo reales, no una cadena de
`Regex.Replace`. El resultado se compila a un AST y se cachea por texto de
plantilla.

Sintaxis soportada:

- Variables y propiedades anidadas: `{{ .UserName }}`, `{{ .Path.Current }}`.
- Propiedades faltantes: resuelven a `null` y renderizan cadena vacía, sin
  excepciones.
- Condicionales: `{{ if ... }}`, `{{ else }}`, `{{ else if ... }}`,
  `{{ end }}`.
- Comparaciones y lógica: `eq`, `ne`, `contains`, `and`, `or`, `not`.
- Funciones: `upper`, `lower`, `trim`, `replace`, `default`.
- Literales: cadenas con escapes (`\"`, `\\`, `\n`, `\r`, `\t`, `\uXXXX`),
  números, `true`, `false`, `nil`/`null`.
- Anidamiento de funciones con paréntesis: `{{ upper (trim .Name) }}`.
- Marcadores de recorte `{{- ... -}}`.
- Errores con posición absoluta, línea y columna.

Decisiones de compatibilidad:

- `contains` sigue el orden de Sprig/Oh My Posh: `contains <needle> <haystack>`.
- `replace` sigue el orden `replace <old> <new> <value>`.
- `default` recibe `default <fallback> <value>`.
- Las funciones usadas como argumento deben ir entre paréntesis.

Limitaciones deliberadas de la Fase 1: no hay pipelines (`|`), funciones de
fecha, diccionarios de Sprig ni evaluación de expresiones arbitrarias.

## 5. Segmentos y renderizado

### Segmentos

Contratos públicos:

- `PromptContext`: datos de sesión, path, git, timestamp, exit code y
  propiedades.
- `PromptSegment`: instancia normalizada de configuración.
- `SegmentDefinition`: metadatos del proveedor (tipo, plantilla y timeout por
  defecto).
- `SegmentResult`: texto, colores, estilo, visibilidad, estado, duración y error.
- `ISegmentProvider`: contrato asíncrono de recolección.

Proveedores nativos iniciales: `session`, `path`, `git`, `text`, `time`, `exit`.
El contexto de git se obtiene leyendo `.git/HEAD` sin lanzar procesos; no
calcula dirty/ahead/behind en esta fase.

### Renderers

`IRenderer` recibe un `PromptRenderModel` sin estado de consola, por lo que la
salida es determinista y testeable.

- `PlainRenderer`: texto plano, colores ANSI/truecolor opcionales, sin glifos
  PowerLine.
- `PowerLineRenderer`: estilos `plain`, `powerline`, `diamond` y `accordion`,
  separadores `\uE0B0`, diamantes `\uE0B6`/`\uE0B4` y contraste automático para
  foreground faltante.
- `AnsiColor`: colores ANSI clásicos y `#RGB`, `#RRGGBB`, `#RRGGBBAA` a
  `38;2`/`48;2`; reset `\u001b[0m` después de cada segmento coloreado.
- `ColorResolver`: resuelve primero la paleta del tema y luego ANSI/hex. Una
  referencia desconocida se renderiza sin color, nunca rompe el prompt.

## 6. Scheduler asíncrono

`SegmentScheduler` ejecuta todos los segmentos con `Task.WhenAll`.

- **Timeout por segmento:** `segment.TimeoutMs`, luego
  `provider.Definition.DefaultTimeoutMs`, luego el default del scheduler.
- **Cancelación externa:** el token se propaga a cada proveedor mediante un
  `CancellationTokenSource` enlazado.
- **Aislamiento de fallos:** una excepción o un timeout produce un
  `SegmentResult` con estado `Failed`/`TimedOut`; los demás segmentos continúan.
- **Resultados parciales y orden estable:** los resultados se escriben en un
  array por índice de declaración, independientemente del orden de finalización.
- **Proveedores que ignoran cancelación:** el scheduler abandona la tarea,
  observa su excepción eventual y devuelve `TimedOut` sin bloquear el prompt.

La configuración de caché (`CacheConfig`) está modelada y validada, pero el
scheduler no implementa caché persistente en la Fase 1. Es una limitación
explícita, no un comportamiento silencioso; se conectará en la Etapa 2 cuando
exista un host de larga vida.

## 7. Importador de Oh My Posh

`OmpThemeImporter` acepta el subconjunto inicial:

- `blocks`, `type`, `alignment`, `newline`, `final_space`.
- `segments`, `type`, `style`, `foreground`, `background`, `template`,
  `properties`, `leading_diamond`, `trailing_diamond`.
- Paleta opcional, incluyendo `p:Name` como referencia a la paleta.
- Segmentos mapeados: `session`, `path`, `git`, `text`, `time`, `exit`.

Un tipo de segmento no soportado produce `OmpImportException` con la ruta
`blocks[i].segments[j].type` y la lista de tipos soportados. La CLI permite
`--ignore-unsupported` para importar el resto de forma explícita.

Valores por defecto razonables: `renderer: powerline`, plantillas básicas para
los seis tipos, `final_space` según el tema y nombre derivado del archivo.
Los estilos `minimal` y desconocidos se normalizan a `plain`.

La ruta `src/Themes/Pablitus.omp.json` se usa como caso de prueba real, además de
`examples/dotnet/theme.omp.json`.

## 8. Compatibilidad con el módulo PowerShell

- **Etapa 0 (actual):** el módulo PowerShell sigue siendo el motor por defecto.
  `src/PablitusPrompt.psm1`, los temas `.Theme.ps1`, los segmentos scriptblock y
  la suite Pester de 192 tests no se modifican.
- **Etapa 1 (esta fase):** núcleo .NET aislado, JSON themes, CLI e importador
  OMP. La CLI no se carga desde el perfil de PowerShell.
- **Etapa 2:** adaptador PowerShell → núcleo .NET, flag opt-in
  `PPF_USE_DOTNET_CORE=1`, temas JSON nativos y fallback automático al motor
  PowerShell si el flag no está activo o el host falla.
- **Etapa 3:** host de plugins PowerShell en runspaces para segmentos de usuario.
- **Etapa 4:** multi-shell, transient prompt, tooltips, right prompt, packaging y
  galería.

Nunca se elimina el motor anterior. Cualquier integración futura debe ser
opt-in, con telemetría desactivada y sin llamadas de red.

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Divergencia entre el motor PowerShell y el núcleo .NET | Prompts distintos según el motor | Contratos de contexto/renderer alineados; suite Pester intacta; comparación en Etapa 2 |
| Cobertura incompleta de Oh My Posh | Temas que no importan | Error explícito, `--ignore-unsupported`, mapa documentado y ampliación incremental |
| Caché modelada pero no implementada | Expectativa de rendimiento | Limitación documentada; `CacheConfig` validado y listo para Etapa 2 |
| Git sin dirty/ahead/behind | Prompt menos informativo | Contexto mínimo basado en `.git/HEAD`; proveedor ampliable sin cambiar contratos |
| Right prompt y transient prompt no renderizados | Paridad parcial con OMP | Campos modelados y validados; renderizado reservado para Etapa 4 |
| Ambigüedad entre nombre ANSI y clave de paleta | Color inesperado | La paleta tiene prioridad; luego ANSI/hex; referencia desconocida = sin color |
| Timeout de proveedores que ignoran cancelación | Tareas abandonadas | El scheduler no bloquea y observa excepciones; el contrato pide cooperación |
| Sin benchmarks en Fase 1 | Regresiones de rendimiento invisibles | Plantillas compiladas/cacheadas y scheduler concurrente; benchmarks en Etapa 2 |

## 10. Verificación

Comandos de aceptación:

```powershell
dotnet build dotnet/PablitusPrompt.sln -c Release
dotnet test dotnet/PablitusPrompt.sln -c Release
dotnet run --project dotnet/src/PablitusPrompt.Cli -- theme import src/Themes/Pablitus.omp.json --output out.ppf.json
dotnet run --project dotnet/src/PablitusPrompt.Cli -- theme validate out.ppf.json
dotnet run --project dotnet/src/PablitusPrompt.Cli -- render --config examples/dotnet/config.ppf.json
```

Criterios:

- La solución compila y los tests xUnit pasan.
- El importador convierte el tema OMP real y el tema de ejemplo.
- La validación acepta los ejemplos y rechaza JSON inválido con ruta de campo.
- El render produce ANSI sin excepciones y `debug` informa timings por segmento.
- La suite Pester existente no cambia.

## 11. Consecuencias

Positivas:

- Base declarativa y testeable para temas y configuración.
- Motor asíncrono con aislamiento de fallos desde el primer día.
- Camino de importación real desde Oh My Posh.
- Contratos públicos que permiten integrar PowerShell y otros hosts sin reescribir
  el núcleo.

Costos:

- Dos motores conviven durante las etapas 1–2.
- Hay que mantener paridad de comportamiento y documentar divergencias.
- La cobertura de segmentos y funciones crecerá por incrementos pequeños y
  verificables.

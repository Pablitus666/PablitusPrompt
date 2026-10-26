# ADR 0002 — Integración opt-in del módulo PowerShell con el núcleo .NET

- **Estado:** aceptado para la Fase 2
- **Fecha:** 2026-10-25
- **Contexto:** la Fase 1 creó el núcleo .NET 8, la CLI `ppf`, los schemas y el
  importador de temas de Oh My Posh, pero el módulo PowerShell seguía siendo el
  único motor. La Fase 2 conecta ambos sin reemplazar el motor existente.
- **Decisión:** cargar el núcleo .NET como DLL desde un adaptador PowerShell,
  activarlo de forma **opt-in** y conservar `Invoke-Prompt` como fallback
  automático.

## 1. Contexto

El módulo actual es estable y tiene una suite Pester de 192 tests. Cualquier
integración debe cumplir estas restricciones:

- No cambiar la firma pública de `Get-PromptString`.
- Con un `-Context` explícito, el comportamiento debe ser exactamente el legacy.
- Si el núcleo .NET falla, el prompt debe seguir funcionando con PowerShell.
- No ejecutar la CLI `ppf` en el hot path.
- No modificar `build/`, `artifacts/` ni `archive/`.

La Fase 1 dejó disponibles:

- `PablitusPrompt.Core.dll` con `PromptEngine`, `PpfConfigSerializer`,
  `OmpThemeImporter`, `PromptContextFactory`, renderers y scheduler.
- `dotnet/publish` como destino previsto para la DLL de producción.
- La ruta de desarrollo
  `dotnet/src/PablitusPrompt.Core/bin/Release/net8.0/PablitusPrompt.Core.dll`.

## 2. Decisión

Se agrega `src/Core/Prompt.DotNet.ps1`, que el bootstrap carga automáticamente
porque no está en la lista explícita de `CoreLoadOrder`. El archivo no se
ejecuta desde el perfil: solo registra funciones y mantiene estado en el scope
del módulo.

### API pública nueva

| Función | Contrato |
| --- | --- |
| `Test-PPFDotNetCoreAvailable` | Indica si la DLL resuelta existe. `-Refresh` ignora el estado cacheado. |
| `Enable-PPFDotNetCore -ThemePath <ruta> [-IgnoreUnsupported]` | Carga la DLL, importa/valida el tema, crea un `PromptEngine` y activa el modo .NET. Devuelve el estado. |
| `Disable-PPFDotNetCore` | Desactiva el adaptador y libera motor/configuración. Si `PPF_USE_DOTNET_CORE=1`, deja una supresión explícita hasta el próximo `Enable`. |
| `Get-PPFDotNetCoreStatus` | Estado de diagnóstico: disponibilidad, DLL, tema, tipo detectado, contadores de render/fallback y último error. |
| `Import-PPFDotNetTheme -Path <ruta> [-IgnoreUnsupported] [-Activate]` | Importa y valida un tema PPF u OMP. Devuelve el `PpfConfig` listo para el motor; con `-Activate` también lo activa. |
| `Invoke-PPFDotNetPrompt` | Interno, no exportado. Crea el contexto, llama a `RenderAsync(...).GetAwaiter().GetResult()` y devuelve el string. |

No se modifican firmas existentes. `Get-PromptString` conserva sus parámetros
`-Context` y `-Renderer`.

### Resolución de la DLL

Orden exacto:

1. `$env:PPF_DOTNET_CORE_DLL` (si está definido, es la única ruta aceptada).
2. `<raíz>/dotnet/publish/PablitusPrompt.Core.dll`.
3. `<raíz>/dotnet/src/PablitusPrompt.Core/bin/Release/net8.0/PablitusPrompt.Core.dll`.

La raíz se deriva de `$global:PPF_InstallRoot`; como el manifiesto vive en
`src/`, el adaptador sube un nivel cuando esa raíz no contiene `dotnet/`.

La carga usa `Add-Type -Path`. Si la ruta no existe o `Add-Type` falla, el error
se registra en el estado y **no se rompe el módulo**. `Test-PPFDotNetCoreAvailable`
devuelve `false`; el prompt sigue por PowerShell.

### Detección de formato de tema

Un archivo se trata como Oh My Posh si cumple cualquiera de estas condiciones:

- La extensión termina en `.omp.json`.
- El `$schema` contiene `oh-my-posh` o `JanDeDobbeleer`.
- La forma del documento tiene `blocks`, no tiene `theme` y presenta marcadores
  de OMP (`final_space`, `console_title_template`, `secondary_prompt`,
  `transient_prompt`, `tooltips`, `version` numérico o `properties` en algún
  segmento).

Si el `$schema` apunta a `pablitus.dev/schemas/ppf.schema.json` o
`theme.schema.json`, se trata como PPF. El resto se carga con
`PpfConfigSerializer`. Los temas OMP usan `OmpThemeImporter`; luego se
serializan y se vuelven a cargar para aplicar la misma validación semántica que
un tema PPF escrito a mano.

### Flag y activación

El modo .NET está activo si:

1. `Enable-PPFDotNetCore` o `Import-PPFDotNetTheme -Activate` activaron el
   estado interno, o
2. `PPF_USE_DOTNET_CORE=1` y existe un tema en `PPF_DOTNET_THEME` (o el último
   tema importado en la sesión).

`Disable-PPFDotNetCore` con el flag de entorno en `1` establece una supresión
explícita para que una llamada posterior a `Get-PromptString` no reactive el
motor. `Enable-PPFDotNetCore` limpia la supresión.

### Contrato de `Get-PromptString`

```text
Get-PromptString [-Context <PromptContext>] [-Renderer <nombre>]
```

- `-Context` explícito y no nulo: se usa `Invoke-PromptRenderer` como siempre.
  No se toca el contador del núcleo .NET.
- Sin contexto:
  1. Si el modo .NET está activo, se llama al adaptador.
  2. Si el adaptador lanza, se registra el error, se incrementa
     `FallbackCount` y se continúa con `Invoke-Prompt`.
  3. Si el modo .NET no está activo, se crea el contexto con `Invoke-Prompt`
     dentro del cuerpo de la función (no en el valor por defecto del parámetro).
- `-Renderer` se mantiene para compatibilidad. En modo .NET solo se mapean
  `PowerLine -> powerline` y `Plain -> plain`. Cualquier otro renderer legacy
  (`Minimal`, `JSON`, `HTML`, `Markdown`, `Rich`, `ANSI` o uno personalizado)
  permanece en el motor PowerShell para no cambiar silenciosamente el formato de
  salida.

La rama .NET no dispara `BeforeRender`/`AfterRender` porque no construye un
`PromptContext` legacy. Es una divergencia documentada y explícita; los hooks
siguen funcionando en el motor PowerShell.

### Caché del scheduler

La Fase 2 conecta la caché que la Fase 1 solo modelaba:

- `ISegmentCache` e `InMemorySegmentCache` viven en C#.
- La clave incluye tipo, nombre, estilo, colores, icono, diamantes, plantilla,
  propiedades del proveedor, directorio, rama Git, exit code, usuario, host y
  shell.
- TTL por segmento (`cacheTtlSeconds`) gana sobre el TTL global
  (`cache.ttlSeconds`). `cacheTtlSeconds: 0` desactiva la caché para ese
  segmento.
- `time` y `exit` no se cachean por defecto.
- Solo se cachean resultados `Success`.
- `cache.maxEntries` limita las entradas y expulsa la más antigua.
- `PromptEngine` conserva una instancia de caché durante su vida, por lo que el
  adaptador PowerShell obtiene hits entre prompts.
- La CLI acepta `--no-cache` para `render` y `debug`.

La caché es en memoria: no hay persistencia en disco ni coordinación entre
procesos. Es una decisión deliberada para esta etapa.

## 3. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Divergencia de salida entre motores | Prompts distintos según el flag | Motor PowerShell por defecto; comparación manual; tests de contrato; flag opt-in |
| DLL ausente o incompatible | Excepción al activar | `Test-PPFDotNetCoreAvailable`, error en `LastError`, fallback automático |
| Tema inválido o con segmentos OMP no soportados | Prompt vacío o excepción | Validación al activar; `OmpImportException` con ruta; `-IgnoreUnsupported` explícito |
| Caché obsoleta tras cambiar de tema | Texto viejo | Cada activación crea un `PromptEngine` nuevo; la clave incluye la plantilla |
| `PPF_USE_DOTNET_CORE=1` sin tema | Activación fallida en cada prompt | `LastError` claro; se reintenta solo si cambia la ruta o el timestamp; supresión tras `Disable` |
| Hooks de render no disparados en modo .NET | Integraciones que dependen de eventos | Divergencia documentada; los hooks siguen activos en el motor legacy |
| Costo de `Add-Type` en el primer prompt | Latencia inicial | Carga perezosa solo al activar; nunca en el bootstrap ni en el perfil |
| Dependencia de .NET 8 en PowerShell | Fallo de carga en hosts viejos | PowerShell 7.6 ejecuta sobre .NET moderno; la DLL se resuelve y falla de forma controlada |

## 4. Verificación

```powershell
dotnet build dotnet/PablitusPrompt.sln -c Release
dotnet test dotnet/PablitusPrompt.sln -c Release

# Publicar la DLL que busca el adaptador
./scripts/Build-PPFDotNetCore.ps1

Import-Module ./src/PablitusPrompt.psd1 -Force

Enable-PPFDotNetCore -ThemePath ./examples/dotnet/theme.nord.ppf.json
$env:PPF_USE_DOTNET_CORE = "1"
Get-PromptString

# Fallback: sin tema o sin DLL
Disable-PPFDotNetCore
$env:PPF_DOTNET_THEME = "missing.json"
Get-PromptString
```

La suite Pester incluye `tests/DotNet.Core.Tests.ps1`, con `Skip` explícito
cuando la DLL no está compilada. Los tests xUnit cubren la caché: hit,
expiración, límite, TTL por segmento, segmentos no cacheables y errores.

## 5. Plan de retiro del flag

1. **Fase 3A:** host de plugins PowerShell en runspaces y paridad de segmentos
   de usuario. Ver `docs/adr/0003-powershell-plugin-host.md`.
2. **Fase 3B/4:** comparar salida entre motores en CI y documentar diferencias
   restantes (hooks, renderers legacy, right prompt).
3. **Fase 4:** si la paridad es suficiente, convertir el núcleo .NET en motor
   por defecto. `PPF_USE_DOTNET_CORE` pasaría a significar "forzar .NET" y se
   agregaría un flag de escape temporal para el motor PowerShell.
4. **Retiro:** mantener el motor PowerShell y los temas `.Theme.ps1` durante al
   menos una versión menor después del cambio de default. No se elimina
   `Invoke-Prompt` ni el fallback sin una ADR posterior.

El flag no se retira en la Fase 2. La compatibilidad sigue siendo un requisito,
no un detalle.

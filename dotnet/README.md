# Pablitus Prompt Core (.NET)

Núcleo experimental en .NET 8 para evolucionar PPF hacia un motor de prompt
declarativo, asíncrono y extensible. La integración es **aditiva y opt-in**: el
módulo de PowerShell sigue siendo el motor por defecto.

## Estado

- Motor de configuración/temas JSON.
- Motor de plantillas con lexer, parser y AST.
- Scheduler asíncrono con timeout, cancelación y caché en memoria.
- Renderers `plain` y `powerline`.
- Importador del subconjunto inicial de temas de Oh My Posh.
- CLI `ppf`, incluyendo `render`/`debug --no-cache`.
- Adaptador PowerShell opt-in (`PPF_USE_DOTNET_CORE=1`) con fallback automático.
- Host de plugins PowerShell en runspaces para segmentos de usuario.
- Paridad legacy/.NET para plugins y benchmark con presupuesto de latencia en CI.
- **Fase 3C:** prompt transitorio, tooltips y right prompt.

Multi-shell queda para la Fase 3D.

## Estructura

```text
dotnet/
  PablitusPrompt.sln
  Directory.Build.props
  src/
    PablitusPrompt.Core/     # motor, configuración, plantillas, renderers
    PablitusPrompt.Cli/      # CLI ppf
  tests/
    PablitusPrompt.Core.Tests/  # xUnit
```

## Compilar y probar

```powershell
dotnet build dotnet/PablitusPrompt.sln -c Release
dotnet test dotnet/PablitusPrompt.sln -c Release
```

## CLI

```powershell
# Importar un tema de Oh My Posh a JSON PPF
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  theme import src/Themes/Pablitus.omp.json `
  --output examples/dotnet/pablitus.ppf.json

# Validar un tema o configuración PPF
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  theme validate examples/dotnet/theme.nord.ppf.json

# Renderizar un prompt
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  render --config examples/dotnet/config.ppf.json

# Renderizar solo el prompt transitorio
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  render --config examples/dotnet/config.ppf.json --transient --terminal-width 80

# Renderizar el tooltip de un comando (alineado a la derecha)
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  render --config examples/dotnet/config.ppf.json --tooltip git --column 5 --terminal-width 80

# Ver timings por segmento
dotnet run --project dotnet/src/PablitusPrompt.Cli -- `
  debug --config examples/dotnet/config.ppf.json
```

Los comandos `render` y `debug` aceptan `--no-cache` para desactivar la caché
en memoria del scheduler.

## Integración con el módulo PowerShell

El adaptador es **opt-in**: si no se activa, el módulo sigue usando el motor
PowerShell de siempre.

```powershell
# 1. Compilar/publicar la DLL que busca el adaptador
./scripts/Build-PPFDotNetCore.ps1

# 2. Importar el módulo
Import-Module ./src/PablitusPrompt.psd1 -Force

# 3. Activar un tema JSON PPF u OMP
Enable-PPFDotNetCore -ThemePath ./examples/dotnet/theme.nord.ppf.json

# 4. Pedir el prompt (sin -Context: usa el motor .NET)
$env:PPF_USE_DOTNET_CORE = "1"
Get-PromptString

# Alternativa: activar solo por entorno
$env:PPF_USE_DOTNET_CORE = "1"
$env:PPF_DOTNET_THEME = (Resolve-Path ./examples/dotnet/theme.omp.json).Path
Get-PromptString

# Diagnóstico
Get-PPFDotNetCoreStatus

# Volver al motor PowerShell
Disable-PPFDotNetCore
```

Contrato importante:

- `Get-PromptString -Context $ctx` siempre usa el renderer PowerShell legacy.
- Sin `-Context`, si el flag/estado está activo, se usa el núcleo .NET.
- En modo .NET solo se mapean `PowerLine` y `Plain`; `Minimal`, `JSON`, `HTML`,
  `Markdown`, `Rich`, `ANSI` y renderers personalizados siguen en PowerShell.
- Si la DLL no existe, el tema es inválido o el render falla, el adaptador
  registra el error y continúa con `Invoke-Prompt`.
- La DLL se busca en `PPF_DOTNET_CORE_DLL`, `dotnet/publish` y
  `dotnet/src/PablitusPrompt.Core/bin/Release/net8.0`, en ese orden.
- `Import-PPFDotNetTheme -Path <ruta> [-IgnoreUnsupported] [-Activate]` importa
  y valida sin activar, salvo que se pase `-Activate`.

### Fase 3C: transitorio, tooltips y right prompt

```powershell
# Prompt transitorio tras aceptar un comando
$env:PPF_USE_DOTNET_CORE = "1"
Get-PromptString -Transient -TerminalWidth 80

# Tooltip de un comando (alineado a la derecha)
Get-PromptTooltip -Command "git" -TerminalWidth 80 -Column 5

# El núcleo .NET también devuelve RightPrompt aparte de Output
$result = Invoke-PPFDotNetPrompt -TerminalWidth 100
$result.Output      # prompt principal (incluye right prompt compuesto)
$result.RightPrompt # solo el right prompt, sin posicionamiento de cursor
```

`Get-PromptString -Transient` requiere que el tema defina `template.transientPrompt`
(o `transient_prompt` en temas OMP). `Get-PromptTooltip` requiere que el tema
defina `tooltips` con al menos una entrada cuyo `tips` coincida con la primera
palabra del comando.

La caché del scheduler respeta `cache.ttlSeconds`, `cache.maxEntries` y
`cacheTtlSeconds` por segmento. La clave incluye las propiedades del segmento,
sus diamantes y el shell, además del contexto. `time` y `exit` no se cachean por
defecto; un segmento puede desactivar la caché con `cacheTtlSeconds: 0`.

### Plugins de usuario

Un segmento registrado con `Register-PromptSegment` se ejecuta también en modo
.NET. No hace falta registrarlo dos veces:

```powershell
Register-PromptSegment -Name "Deploy" -Priority 120 -Script {
    param([PromptContext]$Context)

    $config = Get-SegmentConfiguration -Name "Deploy"
    New-PromptSegment -Name "Deploy" -Text "deploy:$($config.Environment)"
}
```

El tema JSON lo referencia por tipo:

```json
{
  "type": "Deploy",
  "name": "deploy",
  "style": "plain",
  "timeoutMs": 1500,
  "properties": {
    "environment": "production"
  }
}
```

El host compila el puente C# la primera vez, importa el módulo en un
`RunspacePool` dedicado y mapea el contexto .NET al `PromptContext` legacy. Las
propiedades del tema quedan disponibles con `Get-SegmentConfiguration`. Un
plugin que falla o expira se oculta sin romper el resto del prompt.

Los tipos nativos `session`, `path`, `git`, `text`, `time` y `exit` no pueden
ser reemplazados por un plugin. El runspace aísla estado de módulo, pero no es
un sandbox de seguridad: los plugins corren con los permisos del usuario.

### Paridad y benchmark

`tests/DotNet.Parity.Tests.ps1` ejecuta el mismo plugin con el motor legacy y
con el host .NET, y compara el texto del segmento. La suite se ejecuta en CI
después de publicar la DLL, por lo que no queda en `Skip`.

Para medir el costo del host:

```powershell
./scripts/Measure-PPFDotNetCore.ps1 -Iterations 20 -WarmupIterations 3

# JSON para comparar entre ejecuciones
./scripts/Measure-PPFDotNetCore.ps1 `
  -Iterations 20 `
  -OutputPath ./benchmarks/ppf-dotnet-benchmark.json
```

El script mide el motor nativo, el primer render con plugin y el estado warm.
Falla si se exceden los presupuestos de cold start, mediana warm u overhead.
CI publica el JSON como artefacto `ppf-dotnet-benchmark`.

## Documentación

- `docs/adr/0001-dotnet-core.md`: decisión, arquitectura, compatibilidad,
  riesgos y plan de migración.
- `docs/adr/0002-powershell-integration.md`: contrato del adaptador, flag,
  fallback, carga de DLL, caché y plan de retiro del flag.
- `docs/adr/0003-powershell-plugin-host.md`: runspaces, mapeo de contexto,
  configuración, timeout, errores y limitaciones del host de plugins.
- `docs/adr/0004-ci-parity-and-benchmarks.md`: jobs de CI, paridad legacy/.NET
  y presupuesto de latencia.
- `schemas/ppf.schema.json`: schema de configuración.
- `schemas/theme.schema.json`: schema de temas.
- `examples/dotnet/`: configuración y temas de ejemplo.

## Próxima etapa

1. Fase 3E: características avanzadas (pendiente de definir).

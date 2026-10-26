# ADR 0005 — Prompt transitorio, tooltips y right prompt (Fase 3C)

- **Estado:** aceptado para la Fase 3C
- **Fecha:** 2026-10-26
- **Contexto:** la Fase 3B completó CI, paridad y benchmarks. El núcleo .NET ya
  modelaba `RightPrompt`, `TransientPrompt` y bloques `rprompt`, pero el motor
  no los renderizaba. Falta integrar el diseño de Oh My Posh para la línea de
  comandos: prompt transitorio tras aceptar un comando, tooltips mientras el
  usuario escribe palabras clave y right prompt alineado a la derecha.
- **Decisión:** implementar transient prompt, tooltips y right prompt en el
  núcleo .NET y exponerlos a través del adaptador PowerShell, manteniendo el
  contrato opt-in con fallback al motor PowerShell.

## 1. Alcance

| Funcionalidad | Modelo .NET | Renderizado | PowerShell |
|---|---|---|---|
| Right prompt | `BlockConfig.Type = "rprompt"`, `Alignment = "right"`, `Filler`, `Overflow` | `PromptEngine.RenderAsync` produce `RightPrompt` y compone con `TerminalWidth` | `Get-PromptString` (Output incluye right prompt cuando hay ancho) |
| Transient prompt | `TransientPromptConfig` (Template, RightTemplate, Filler, Newline, Foreground, Background) | `PromptEngine.RenderTransient` | `Get-PromptString -Transient -TerminalWidth <n>` |
| Tooltips | `TooltipConfig` (Tips + segment fields), `TooltipsAction` | `PromptEngine.RenderTooltipAsync` | `Get-PromptTooltip -Command <cmd> -TerminalWidth <n> -Column <n>` |

## 2. Cambios en el núcleo .NET

### 2.1 Modelos de configuración (`PpfConfig.cs`)

- `PpfConfig.TransientPrompt` (`TransientPromptConfig?`): plantilla de reemplazo.
- `PpfConfig.Tooltips` (`List<TooltipConfig>`): segmentos activados por palabras clave.
- `PpfConfig.TooltipsAction` (`string`): `replace` (default), `extend`, `prepend`.
- `ThemeConfig.TransientPrompt`, `ThemeConfig.Tooltips`, `ThemeConfig.TooltipsAction`: idénticos en tema embebido.
- `BlockConfig.Filler` y `BlockConfig.Overflow`: texto repetido entre bloques y comportamiento ante desbordamiento.

### 2.2 Validación (`PpfConfigValidator.cs`)

- Un solo bloque `rprompt` por configuración/tema.
- `overflow` solo `hide` o `break`; `tooltipsAction` solo `replace`/`extend`/`prepend`.
- Cada tooltip requiere al menos un `tip` sin espacios en blanco.
- `transientPrompt.template`, `rightTemplate` y `filler` se compilan como plantillas.
- `foreground`/`background` de transientPrompt validados como referencia de color.

### 2.3 Importador OMP (`OmpThemeImporter.cs`)

- Lee `transient_prompt` (incluye `right_template`, `filler`, `newline`, `foreground`, `background`).
- Lee `tooltips` (array con `tips` y campos de segmento) y `tooltips_action`.
- Lee `filler` y `overflow` de cada bloque.
- Los segmentos `tooltips` de tipo no soportado siguen la regla `ignoreUnsupportedSegments`.

### 2.4 Contexto (`PromptContext.cs`, `PromptContextFactory.cs`)

- `PromptContext.CommandLine`, `TerminalWidth`, `Column`, `Interrupted` para soportar transiente y tooltips.
- `PromptContextFactory.Create` acepta `terminalWidth`, `commandLine`, `interrupted`, `column`.

### 2.5 Motor (`PromptEngine.cs`)

- `PromptRunResult.RightPrompt`: texto del right prompt sin posicionamiento de cursor.
- `PromptEngine.RenderAsync` combina bloques left y right. Cuando `TerminalWidth > 0`, compone con `PromptLayout.Compose` (filler, cursor save/restore o absoluto, overflow hide/break).
- `PromptEngine.RenderTransient`: renderiza la plantilla transiente con colores y right template opcional. Devuelve `null` si no está configurado.
- `PromptEngine.RenderTooltipAsync`: encuentra tooltips cuyo `Tips` contenga la primera palabra del comando, ejecuta sus segmentos y alinea el resultado a la derecha con `PromptLayout.RightAlign`. Soporta `replace`/`extend`/`prepend` respecto al right prompt.

### 2.6 Layout (`PromptLayout.cs` — nuevo)

- `Measure` / `MeasureLastLine`: ancho de visualización sin secuencias ANSI, incluyendo ancho de doble byte (CJK/emoji).
- `StripAnsi`: elimina secuencias CSI y OSC.
- `Compose`: combina prompt left y right con filler repetido, cursor save/restore (ANSI) o espacios (sin ANSI), y modos `hide`/`break`.
- `RightAlign`: alinea texto a la derecha desde una columna del cursor.
- `Fit`: repite una plantilla de filler hasta un ancho exacto.

### 2.7 CLI (`Program.cs`)

- `ppf render --config ... --terminal-width <n>`: ancho para right prompt.
- `ppf render --config ... --transient`: renderiza solo el prompt transitorio.
- `ppf render --config ... --tooltip <comando> --column <n>`: renderiza el tooltip de un comando.
- `--command-line <txt>` expone la línea de comandos a las plantillas.

## 3. Cambios en el adaptador PowerShell

### 3.1 `Prompt.DotNet.ps1`

- `Invoke-PPFDotNetPrompt` agrega `-Transient`, `-CommandLine`, `-TerminalWidth`, `-Column`.
- Devuelve un objeto con `Output` y `RightPrompt` (antes solo `Output`).
- Nueva función `Invoke-PPFDotNetTooltip` que ejecuta `PromptEngine.RenderTooltipAsync`.

### 3.2 `Prompt.Rendering.ps1`

- `Get-PromptString` agrega `-Transient`, `-CommandLine`, `-TerminalWidth`, `-Column`.
  Cuando se usa `-Transient`, llama al núcleo .NET y devuelve el texto transiente (fallback a legacy si falla).
- Nueva función `Get-PromptTooltip -Command <cmd> [-TerminalWidth <n>] [-Column <n>]`.
  Devuelve el tooltip alineado a la derecha o `$null` si no hay coincidencia.

### 3.3 Exportación

- `Get-PromptTooltip` se agrega a `$PublicFunctions` en `PablitusPrompt.psm1` y a `FunctionsToExport` en `PablitusPrompt.psd1`.

## 4. Semántica de Oh My Posh respetada

- **Transient prompt**: reemplaza el prompt principal tras aceptar un comando. Soporta `template`, `right_template`, `filler`, `newline`, `foreground`, `background`.
- **Tooltips**: segmento right-aligned mostrado al escribir una palabra clave (`tips`). `tooltips_action: replace` (default) reemplaza el right prompt; `extend` lo añade al final; `prepend` al principio.
- **Right prompt**: un solo bloque `rprompt`, alineado a la derecha. `filler` rellena el espacio entre bloques; `overflow: hide` oculta el right prompt si desborda; `overflow: break` lo lleva a una nueva línea.
- Solo se implementa en PowerShell 7+ (PSReadLine). Windows PowerShell 5.1 se queda en el motor legacy.

## 5. Riesgos y limitaciones

- El ancho de terminal y la columna del cursor se pasan desde el llamador (CLI o adaptador). El núcleo .NET no consulta la consola, por lo que el resultado es determinista y testeable.
- El ancho de caracteres Unicode (doble ancho, combinaciones) usa una heurística basada en rangos Unicode; puede no coincidir exactamente con todos los terminales.
- Los tooltips son síncronos/bloqueantes durante el renderizado del segmento, igual que en Oh My Posh.
- `images/screenshot.png` y `images/Preview.png` continúan diferidos (no se toca).

## 6. Verificación

- `dotnet build` y `dotnet test`: 0 warnings/errors, 125 xUnit tests.
- Pester: 104 tests, 0 failed, 0 skipped (incluye `tests/DotNet.Phase3C.Tests.ps1`).
- PSScriptAnalyzer: sin nuevos warnings respecto a la línea base.
- Cambios sin commitear (pendiente de solicitud explícita).

## 7. Documentación relacionada

- `docs/Architecture.md` sección 5 (modo .NET) actualizada con transiente, tooltips y right prompt.
- `dotnet/README.md` actualizado con estado de Fase 3C y ejemplos de CLI.
- `schemas/ppf.schema.json` y `schemas/theme.schema.json` actualizados con los nuevos campos.
- `.opencode/agents/ppf-platform-architect.md` actualizado: Fase 3C ya no es "no implementar".

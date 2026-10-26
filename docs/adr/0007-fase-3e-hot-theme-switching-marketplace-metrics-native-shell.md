# ADR 0007 — Fase 3E: tema caliente, marketplace de temas, métricas y prompt nativo multipl-shell

- **Estado:** propuesto
- **Fecha:** 2026-10-26
- **Contexto:** PPF v1.5 distribuye un módulo de PowerShell (`.nupkg`) usable desde bash/zsh/fish/cmd mediante los scripts de `src/ShellInit/`, que arrancan `pwsh` por render (ADR 0006). Los temas se instalan copiando archivos `.Theme.ps1` o mediante `Import-PromptTheme` sobre archivos locales; cambiar de tema requiere reiniciar la sesión o recargar el módulo. No hay métricas persistentes de uso del prompt más allá de `Get-PromptHealth` en memoria. El núcleo .NET existe (Fases 2 y 3A) pero, desde shells no-PowerShell, sigue requiriendo un host `pwsh` por render, con un coste de arranque de unos ~300 ms (limitación documentada en el ADR 0006).

- **Decisión:** en la Fase 3E se añaden cuatro entregables acotados: (1) cambio de tema en caliente sin reiniciar la sesión; (2) marketplace de temas instalable desde PowerShell Gallery; (3) métricas y observabilidad local del prompt; (4) CLI nativo (.NET) que emite el prompt string invocable desde cualquier shell sin arrancar `pwsh`.

## 1. Alcance

| # | Entregable | Descripción |
|---|------------|-------------|
| 1 | **Tema caliente** (hot theme switching) | `Switch-PromptTheme -Name <tema>` cambia el tema activo en la sesión en curso sin reiniciar PowerShell. `Get-PromptTheme` lista los temas instalados y muestra el activo. Incluye validación, rollback al tema anterior y prevención de fuga de configuración (iconos, colores, segmentos ocultos) entre temas. |
| 2 | **Marketplace de temas desde PowerShell Gallery** | Paquete separado `PablitusPrompt.Themes` con temas adicionales. `Install-PromptTheme -Name <tema>` instala desde la galería, descompone el `.Theme.ps1` en la carpeta de temas de usuario y lo registra con `Import-PromptTheme`. Verificación de checksum antes de escribir en disco. |
| 3 | **Métricas y observabilidad del prompt** | Registro local opcional en JSON diario (`metrics-yyyy-MM-dd.json`) en el directorio de caché multiplataforma: tiempos de render, ratio de caché, tema activo y proveedores más lentos. Exposición mediante `Get-PromptMetrics` y extensión de `Get-PromptHealth`. Opt-in, sin PII y sin I/O en el camino crítico del render. |
| 4 | **Prompt nativo multipl-shell** | Executable .NET (`ppf` / `ppf.exe`) que recibe el contexto (ruta, rama Git, ancho de terminal, columna del cursor, etc.) e imprime el prompt string. Invocable desde bash/zsh/fish/cmd sin `pwsh` en el PATH, eliminando el coste de arranque del ADR 0006. Requiere .NET 8 runtime. |

## 2. No objetivos

- Publicación automática en PowerShell Gallery (se genera el `.nupkg`; publicar requiere cuenta y API key, igual que en el ADR 0006).
- Sincronización de configuración entre dispositivos en la nube (requiere autenticación y almacenamiento; se deja para una fase posterior).
- Soporte de PowerShell 5.1 / Windows PowerShell (se mantiene el requisito de PowerShell 7+ y .NET 8).
- Editor visual o GUI de temas.
- Integración profunda con Windows Terminal o WezTerm (se limita a documentar `profile.json` y secuencias de escape).

## 3. Riesgos y limitaciones

- **Fuga de estado entre temas:** los segmentos y la caché de proveedores pueden retener datos del tema anterior. Se invalida la caché por tema y se restaura la configuración base antes de aplicar el nuevo tema.
- **Confianza en temas de terceros:** los temas de la galería ejecutan código PowerShell. Se recomienda instalar solo de fuentes confiadas y se verifica el checksum antes de escribir en disco.
- **PII en métricas:** rutas de proyecto, nombres de rama y usuario pueden ser sensibles. Las métricas se escriben localmente, son opt-in y se ofuscan u omiten las rutas completas.
- **Paridad del shell nativo:** el executable .NET debe producir el mismo texto que el motor PowerShell para el mismo contexto de entrada. Pruebas de paridad obligatorias (línea ADR 0004).
- **Dependencia de .NET 8 runtime:** el prompt nativo requiere .NET 8 instalado en el equipo.
- **Costo de mantenimiento:** cuatro entregables en una sola fase dispersan el foco; si el CI o la cobertura se resienten, se recorta a los entregables 1 y 3.

## 4. Verificación en CI

- Job `test` (windows-latest): Pester + cobertura (>90%) + PSScriptAnalyzer, incluyendo pruebas de paridad del shell nativo frente al motor PowerShell.
- Job `package`: generación del `.nupkg` de temas (`PablitusPrompt.Themes`) y validación del `.nuspec`.
- Artefactos publicados: `.nupkg` del núcleo, `.nupkg` de temas y binario `ppf`.

## 5. Criterios de aceptación sugeridos (resumen)

Ver la sección "Criterios de aceptación sugeridos" del plan de la Fase 3E. Puntos clave: cambio de tema sin reinicio y sin leak de configuración; `Install-PromptTheme` desde PSGallery con checksum verificado; archivo de métricas JSON diario opt-in sin PII y con overhead < 1 ms por render; `ppf` funcionando desde bash/zsh/fish/cmd sin `pwsh` con salida idéntica al motor PowerShell; 0 fallos en Pester, cobertura >= 90%, 0 hallazgos de PSScriptAnalyzer.
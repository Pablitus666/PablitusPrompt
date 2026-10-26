# ADR 0006 — Multi-shell y packaging (Fase 3D)

- **Estado:** aceptado para la Fase 3D
- **Fecha:** 2026-10-26
- **Contexto:** PPF era un módulo exclusivo de PowerShell 7+ sin forma estandarizada
  de distribuirse ni de usarse desde shells no-PowerShell (bash, zsh, fish, cmd).
- **Decisión:** empaquetar el módulo como `.nupkg` para PowerShell Gallery y
  proporcionar scripts de inicialización en `src/ShellInit/` para shells no-PowerShell.

## 1. Alcance

| Entregable | Descripción |
|------------|-------------|
| `PablitusPrompt.nuspec` | Manifiesto NuGet para PowerShell Gallery (id, versión, dependencias, archivos) |
| `build.ps1` | Paso de empaquetado `.nupkg` además del ZIP existente |
| `src/ShellInit/ppf.ps1` | Entry point de PowerShell que imprime el prompt para shells anfitriones |
| `src/ShellInit/ppf.bash` | Inicialización para bash (`source` en `~/.bashrc`) |
| `src/ShellInit/ppf.zsh` | Inicialización para zsh (`source` en `~/.zshrc`) |
| `src/ShellInit/ppf.fish` | Inicialización para fish (`source` en `~/.config/fish/config.fish`) |
| `src/ShellInit/ppf.cmd` | Inicialización para cmd (macro / AutoRun) |
| `.github/workflows/ci.yml` | Validación del `.nuspec`, ejecución de `build.ps1`, subida de artefactos |
| `docs/Architecture.md` | Sección 5.6 documentando multi-shell y packaging |
| `README.md` | Documentación de instalación desde PowerShell Gallery y multi-shell |

## 2. Cambios en `build.ps1`

Se agregó un paso de empaquetado `.nupkg` después del ZIP:

1. Crea `$buildDir/PablitusPrompt.nupkg_content/` con la estructura:
   ```
   PablitusPrompt.nuspec          (versión inyectada desde el manifiesto)
   LICENSE, README.md, CHANGELOG.md
   PablitusPrompt/                (todo el módulo: src/ copiado)
   ```
2. Reemplaza la versión en el `.nuspec` copiado con la versión del manifiesto PSD1.
3. Comprime usando `[System.IO.Compression.ZipFile]::CreateEntryFromFile` para
   preservar la estructura de subdirectorios (`CreateFromDirectory` aplanaba las
   entradas).
4. Copia el `.nupkg` a `artifacts/` junto con el ZIP.

## 3. Multi-shell

PPF es un módulo de PowerShell. Los scripts de `src/ShellInit/` inician `pwsh`
para renderizar el prompt y lo inyectan como `PS1`/`PROMPT` del shell anfitrión:

- **bash**: `ppf.bash` usa `PROMPT_COMMAND` para llamar a `pwsh -NoProfile -File ppf.ps1`.
- **zsh**: `ppf.zsh` usa `precmd` para lo mismo.
- **fish**: `ppf.fish` define `function fish_prompt` que llama a `pwsh`.
- **cmd**: `ppf.cmd` usa un bucle `for /f` para capturar la salida de `pwsh`.

Todos los scripts precargan el módulo una vez al iniciar la sesión para reducir
el coste de arranque posterior.

### Limitaciones

- Iniciar `pwsh` en cada prompt añade un coste de arranque (~300 ms). Para uso
  diario se recomienda usar PPF directamente desde PowerShell 7+.
- El ancho de terminal y la columna del cursor se pasan desde el llamador; el
  núcleo .NET no consulta la consola.
- Todo sigue bajo el contrato opt-in (`PPF_USE_DOTNET_CORE=1`) con fallback al
  motor PowerShell.

## 4. Verificación en CI

El job `test` (windows-latest) ahora:

1. Valida que `PablitusPrompt.nuspec` es XML bien formado.
2. Ejecuta `./build.ps1` (pruebas Pester, cobertura, benchmarks, empaquetado ZIP + .nupkg).
3. Sube el `.nupkg` como artefacto `ppf-nupkg`.
4. Sube el `.zip` como artefacto `ppf-zip`.
5. Sigue subiendo el benchmark JSON como `ppf-dotnet-benchmark`.

## 5. Riesgos

- PowerShell Gallery requiere una cuenta de publicación y una clave de API;
  este ADR no cubre el proceso de publicación (`Publish-Module`), solo la
  generación del paquete `.nupkg`.
- Los scripts de multi-shell dependen de que `pwsh` esté en el PATH del shell
  anfitrión.
- Los scripts de ShellInit se instalan junto con el módulo vía `.nuspec`
  (`<file src="src\**" target="PablitusPrompt\" />`).

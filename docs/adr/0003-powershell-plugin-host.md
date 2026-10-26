# ADR 0003 — Host de plugins PowerShell en runspaces

- **Estado:** aceptado para la Fase 3A
- **Fecha:** 2026-10-26
- **Contexto:** el núcleo .NET ya ejecuta el motor, los renderers, el scheduler
  y la caché. Para que el modo .NET no pierda los segmentos de usuario, los
  scriptblocks registrados con `Register-PromptSegment` deben ejecutarse sin
  agregar una dependencia de `System.Management.Automation` al proyecto
  `PablitusPrompt.Core`.
- **Decisión:** compilar en runtime un puente C# (`Add-Type`) que implementa
  `ISegmentProvider`, mantiene un `RunspacePool` dedicado y traduce el contexto
  .NET al `PromptContext` legacy.

## 1. Contexto

La Fase 2 dejó el motor PowerShell como fallback y permitió activar el núcleo
.NET con temas JSON. Sin embargo, un tema JSON que declara un segmento de
usuario no podía ejecutar el scriptblock de `Register-PromptSegment`.

Restricciones de la Fase 3A:

- El core .NET no debe referenciar PowerShell (`System.Management.Automation`).
- Los segmentos nativos del core (`session`, `path`, `git`, `text`, `time`,
  `exit`) tienen prioridad y no pueden ser tapados por un plugin con el mismo
  nombre.
- Un plugin defectuoso, lento o cancelado no puede romper el prompt.
- El contexto legacy debe seguir siendo válido para los plugins existentes:
  `$Context.Session`, `$Context.Path`, `$Context.Git`, `$Context.Timestamp`,
  `$LASTEXITCODE`, `$PWD` y `Get-SegmentConfiguration`.
- La configuración declarativa del tema debe llegar al plugin como propiedades
  y ser convertible a hashtables, arrays y valores anidados.
- La activación y el apagado deben liberar los runspaces.

## 2. Decisión

Se agrega `src/Core/PpfPowerShellPluginHost.cs`, que se compila con `Add-Type`
la primera vez que se sincroniza un plugin en el adaptador
`src/Core/Prompt.DotNet.ps1`.

```text
PromptEngine
  -> SegmentScheduler
       -> PpfPowerShellSegmentProvider (ISegmentProvider)
            -> RunspacePool (1 runspace)
                 -> importa PablitusPrompt.psd1 una vez
                 -> mapea el contexto
                 -> ejecuta el scriptblock del plugin
                 -> devuelve PablitusPrompt.PluginResult
```

### Por qué un puente compilado en runtime

El proyecto `PablitusPrompt.Core` debe poder compilarse, probarse y publicarse
sin el SDK de PowerShell. El puente vive fuera del proyecto .NET y solo se carga
cuando el adaptador PowerShell activa el modo .NET con al menos un plugin. Esto
evita agregar `System.Management.Automation` a la DLL principal y conserva la
posibilidad de usar el core desde la CLI sin PowerShell.

El costo es una compilación `Add-Type` en la primera activación. Se paga una sola
vez por sesión y no ocurre en el bootstrap ni en el primer prompt si no hay
plugins que registrar.

### Descubrimiento y versionado

`Get-PPFDotNetPluginDefinitions` lee `$script:PromptSegments` y conserva nombre,
prioridad y el texto del scriptblock. `Register-PromptSegment` incrementa
`$script:PromptSegmentsVersion`; el adaptador compara esa versión con
`PluginRegistryVersion` para no recorrer y recompilar proveedores en cada
prompt.

Un plugin puede registrarse o reemplazarse en caliente. Si el texto del
scriptblock cambia, el proveedor anterior se libera y se registra uno nuevo. Si
el plugin desaparece del registro, su proveedor también se elimina.

Los tipos nativos del `PromptEngine` se consultan antes de registrar plugins:
un scriptblock llamado `text`, `path` o `git` no reemplaza al proveedor nativo.
La comparación no distingue mayúsculas de minúsculas.

### Runspace y ciclo de vida

Cada `PpfPowerShellSegmentProvider` posee un `RunspacePool` con un mínimo y un
máximo de un runspace. El pool:

1. Importa `src/PablitusPrompt.psd1` una sola vez.
2. Registra y activa un tema vacío `__PPFPluginHost` para que las claves de
   paleta queden sin resolver; el renderer .NET aplica los colores reales del
   tema JSON.
3. Ejecuta una invocación por segmento, serializada por el pool.

El proveedor implementa `IDisposable`. `Disable-PPFDotNetCore`, un cambio de
proveedor y el `OnRemove` del módulo liberan los pools. Si el pool no puede
iniciarse, el segmento devuelve un error controlado y el resto del prompt sigue
funcionando.

### Mapeo del contexto

El script de invocación recibe el `PromptContext` del core y crea un
`PromptContext` legacy. La correspondencia es:

| Core .NET | Contexto legacy |
| --- | --- |
| `UserName` | `Session.User` |
| `HostName` | `Session.Host` |
| `Path.Current` | `Path.Current` |
| `Path.Display` | `Path.Friendly` |
| `Git.IsRepository` | `Git.IsRepository` |
| `Git.Branch` | `Git.Branch` |
| `Git.IsDirty` | `Git.Dirty` |
| `Git.Ahead` / `Git.Behind` | `Git.Ahead` / `Git.Behind` |
| `Timestamp` | `Timestamp` (`LocalDateTime`) |
| `ExitCode` | `$global:LASTEXITCODE` |
| `Properties` | `Metrics` (conversión recursiva) |
| `Path.Current` | `$PWD` del runspace |

`Session.IsAdmin` se calcula dentro del runspace con `WindowsIdentity` y
`WindowsPrincipal`. Si la comprobación falla, el valor queda en `$false`.

El `$PWD` se cambia al path del contexto para que los plugins que usan rutas
relativas se comporten como en el motor legacy. Un path obsoleto no impide
ejecutar el segmento.

### Configuración del tema

Las propiedades del segmento del tema se convierten de `JsonElement` (o
diccionarios) a hashtables, arrays y escalares de PowerShell. Luego se aplican
con `Set-SegmentConfiguration` para tres alias, en este orden:

1. El nombre del plugin.
2. El nombre del segmento en el tema.
3. El tipo del segmento.

También se inyectan `Visible`, `Icon`, `Foreground` y `Background`. Un plugin
existente puede seguir usando `Get-SegmentConfiguration -Name <nombre>` sin
cambios.

### Resultado

El script de invocación devuelve un objeto con el tipo
`PablitusPrompt.PluginResult`. El puente busca ese tipo en la salida del
pipeline y lo convierte a `SegmentResult`:

- `Name`, `Text`, `Icon`, `Foreground` y `Background` se conservan.
- `Visible` se respeta; un resultado sin texto queda invisible.
- `Status` se parsea como `SegmentStatus`; un estado distinto de `Success`
  fuerza `Visible = false`.
- Los valores de color o icono vacíos usan los del segmento del tema.
- Si el plugin no devuelve un `PromptSegment`, el resultado es invisible pero
  no falla.
- Si el scriptblock lanza, el wrapper captura la excepción y devuelve un
  resultado `Failed` con `Error`; el scheduler no propaga la excepción.

### Timeout y cancelación

El scheduler aplica el timeout del segmento (`timeoutMs`) o el default del
proveedor (2000 ms). El proveedor escucha el `CancellationToken` enlazado y
detiene el pipeline en segundo plano. Si el token corresponde al timeout, el
scheduler marca el resultado como `TimedOut`; si corresponde a una cancelación
externa, lo marca como `Cancelled`. En ambos casos el prompt continúa y los
demás segmentos se renderizan.

`Stop()` puede bloquear si un plugin ignora la cancelación. Por eso se ejecuta
en segundo plano y el prompt no espera a que termine. La Fase 3A no recrea un
pool que quede bloqueado por un plugin patológico; esa recuperación queda para
una fase posterior.

## 3. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Plugin lento o bloqueante | Prompt congelado | Timeout por segmento, `Stop()` en segundo plano y scheduler no bloqueante |
| Plugin con excepción | Prompt roto | Wrapper con resultado `Failed`; el scheduler aísla el error |
| Plugin con el nombre de un proveedor nativo | Comportamiento inesperado | Los tipos nativos se filtran antes de registrar plugins |
| Cambio de script en caliente | Texto viejo | `PromptSegmentsVersion` y comparación del texto del script |
| Propiedades JSON anidadas | Errores de tipo en plugins | Conversión recursiva a hashtables/arrays de PowerShell |
| `$PWD` distinto al del prompt | Rutas relativas incorrectas | `Set-Location` al path del contexto antes de invocar |
| Pool que no inicia | Segmento vacío | Error controlado y resto del prompt intacto |
| Código de plugin malicioso | Acceso con permisos del usuario | Los plugins son código confiable; el runspace no es un sandbox de seguridad |
| Compilación `Add-Type` inicial | Latencia en la primera activación | Solo se compila al registrar el primer plugin; se reutiliza el tipo |

## 4. Limitaciones de la Fase 3A

- Un solo runspace por plugin y ejecución serializada.
- Sin sandbox de seguridad: un plugin puede acceder al filesystem, red y
  variables del proceso con los permisos del usuario.
- Sin recuperación automática de un pool bloqueado por un plugin que ignora
  `Stop()`.
- Sin prompt transitorio, tooltips, right prompt ni multi-shell.
- Los segmentos del tema siguen usando el `template` del core; el texto que
  devuelve el plugin es el valor final del segmento.
- Los hooks `BeforeRender`/`AfterRender` siguen sin ejecutarse en la rama .NET.

## 5. Verificación

```powershell
dotnet build dotnet/PablitusPrompt.sln -c Release
dotnet test dotnet/PablitusPrompt.sln -c Release
./scripts/Build-PPFDotNetCore.ps1
Invoke-Pester -Path tests/DotNet.PluginHost.Tests.ps1 -Output Detailed
Invoke-Pester -Path tests/DotNet.Parity.Tests.ps1 -Output Detailed
./scripts/Measure-PPFDotNetCore.ps1 -Iterations 20 -WarmupIterations 3
```

La suite `tests/DotNet.PluginHost.Tests.ps1` cubre:

- descubrimiento y limpieza de proveedores,
- prioridad de los segmentos nativos,
- propiedades de tema anidadas,
- mapeo de sesión, path, git, timestamp, exit code y `$PWD`,
- aislamiento de errores,
- timeout y cancelación externa.

## 6. Siguientes pasos

1. **Fase 3B (completada):** benchmarks del host, comparación de salida entre
   motores en CI y presupuesto de latencia. Ver
   `docs/adr/0004-ci-parity-and-benchmarks.md`.
2. Fase 3C: prompt transitorio, tooltips y right prompt.
3. Fase 3D: multi-shell y packaging.

# ADR 0004 — CI, paridad de motores y presupuesto de latencia

- **Estado:** aceptado para la Fase 3B
- **Fecha:** 2026-10-26
- **Contexto:** la Fase 3A agregó el host de plugins PowerShell. La DLL se
  compilaba y probaba localmente, pero CI solo ejecutaba Pester y no construía
  el core. Tampoco existía una verificación automática de que el plugin
  produjera el mismo texto en el motor legacy y en .NET, ni un presupuesto de
  latencia para el host.
- **Decisión:** construir y probar el core en CI, comparar ambos motores con un
  plugin determinista y medir el costo del host con un benchmark reproducible.

## 1. Pipeline de CI

El workflow `.github/workflows/ci.yml` tiene dos jobs:

1. **`dotnet-core` (`ubuntu-latest`)**
   - `dotnet build dotnet/PablitusPrompt.sln -c Release`
   - `dotnet test dotnet/PablitusPrompt.sln -c Release --no-build`
   - Valida que el core y la CLI no dependan de Windows.

2. **`test` (`windows-latest`)**
   - instala Pester y PSScriptAnalyzer,
   - ejecuta PSScriptAnalyzer sobre `src`, `scripts` y la prueba de paridad,
   - compila y prueba el core,
   - publica la DLL en `dotnet/publish` con
     `scripts/Build-PPFDotNetCore.ps1 -NoRestore`,
   - ejecuta toda la suite Pester,
   - ejecuta el benchmark del host y publica el JSON como artefacto.

El orden es importante: Pester no debe hacer `Skip` por falta de DLL en CI. La
publicación ocurre antes de la suite para que `DotNet.Core.Tests.ps1`,
`DotNet.PluginHost.Tests.ps1` y `DotNet.Parity.Tests.ps1` prueben el mismo
binario que usa el adaptador.

## 2. Paridad entre motores

`tests/DotNet.Parity.Tests.ps1` registra un plugin determinista que produce:

```text
parity=<config>;user=<user>;host=<host>;path=<path>;year=<year>
```

El test:

1. Ejecuta el plugin con el motor legacy mediante `Invoke-Prompt`.
2. Activa el tema JSON y ejecuta el mismo plugin en el host .NET.
3. Compara el texto de los dos `PromptSegment` / `SegmentResult`.
4. Verifica que el texto aparezca en la salida de `Get-PromptString` de ambos
   motores.

No se comparan prompts completos porque los temas `.Theme.ps1` y los temas JSON
no modelan exactamente los mismos iconos, colores ni símbolos de prompt. La
paridad de la Fase 3B se concentra en el contrato que agregó la Fase 3A: el
mismo scriptblock, el mismo contexto y la misma configuración deben producir el
mismo texto de segmento.

## 3. Benchmark

`scripts/Measure-PPFDotNetCore.ps1` mide:

- **Native warm:** mediana y p95 del motor .NET con el proveedor nativo `text`.
- **Plugin cold:** activación del tema, compilación del host, creación del
  runspace, importación del módulo y primer render del plugin.
- **Plugin warm:** mediana y p95 después de warmup.
- **Plugin delta:** diferencia entre la mediana warm del plugin y la nativa.

Parámetros relevantes:

| Parámetro | Default | Uso |
| --- | --- | --- |
| `-Iterations` | 10 | Muestras warm por escenario. |
| `-WarmupIterations` | 2 | Render previos descartados. |
| `-ColdBudgetMs` | 15000 | Presupuesto del primer render con plugin. |
| `-WarmBudgetMs` | 500 | Presupuesto de la mediana warm. |
| `-OverheadBudgetMs` | 250 | Presupuesto del delta sobre el motor nativo. |
| `-OutputPath` | vacío | Escribe un JSON con el resultado. |
| `-NoThreshold` | apagado | Reporta sin fallar por presupuesto. |

CI usa `-Iterations 20 -WarmupIterations 3`. Los presupuestos son deliberadamente
holgados: el objetivo es detectar regresiones grandes en un runner compartido,
no establecer un récord de microbenchmark. Un desarrollador puede ejecutar el
script con presupuestos más estrictos:

```powershell
./scripts/Measure-PPFDotNetCore.ps1 `
  -Iterations 50 `
  -WarmupIterations 5 `
  -ColdBudgetMs 5000 `
  -WarmBudgetMs 100 `
  -OverheadBudgetMs 75
```

El JSON incluye muestras agregadas (`Min`, `Median`, `Mean`, `P95`, `Max`),
presupuestos y el resultado booleano de cada check. El artefacto se llama
`ppf-dotnet-benchmark` en GitHub Actions.

## 4. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Runner lento o ruidoso | Falso positivo de latencia | Presupuestos holgados y warmup; el benchmark no bloquea por microvariaciones |
| Cold start incluye compilación `Add-Type` | Número alto y variable | Se mide aparte del warm y tiene presupuesto propio |
| Paridad limitada al plugin | Diferencias de temas no detectadas | Se documenta el alcance; la paridad visual completa queda para una fase posterior |
| CI duplica build en Windows | Más tiempo | Se usa `--no-build` en tests y `-NoRestore` al publicar |
| Pester hace `Skip` sin DLL | Falsa cobertura verde | La DLL se publica antes de Pester y los tests fallan si el core está disponible pero roto |
| Benchmark escribe en el repo | Ruido en el working tree | CI escribe en `$RUNNER_TEMP`; localmente `-OutputPath` es opcional |

## 5. Criterios de aceptación

- `dotnet-core` y `test` en verde.
- Pester incluye `DotNet.Parity.Tests.ps1` sin `Skip` cuando la DLL existe.
- El benchmark produce JSON y falla si supera alguno de los presupuestos.
- El artefacto de benchmark se publica incluso si el step falla.
- Sin `git commit` ni `git push` desde el agente.

## 6. Limitaciones

- La paridad compara el texto del plugin, no el render completo de todos los
  temas y renderers.
- El benchmark mide un plugin trivial; plugins que consultan red o disco pueden
  dominar el tiempo.
- La latencia de un runner de CI no representa necesariamente una máquina de
  desarrollo.
- El host sigue sin recuperación automática de un pool bloqueado por un plugin
  que ignora `Stop()`.

# PPF Statistical Performance Report
Generado el: 2026-07-06 19:48:18 | Iteraciones: 50

## Resumen de Cache
- **Hits**: 444
- **Misses**: 158
- **Expiraciones**: 1
- **Refrescos (Writes)**: 8

## Métricas Principales
| Categoría | Componente | Mín (ms) | Q1 (ms) | Mediana (ms) | Q3 (ms) | Máx (ms) | Promedio (ms) | P95 (ms) | P99 (ms) | Desv. Est. (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Total** | Prompt | 20,86 | 23,43 | 23,91 | 24,84 | 220,72 | 28,40 | 26,91 | 220,72 | 27,70 |
| **Renderer** | Plain | 0,26 | 0,27 | 0,28 | 0,29 | 2,45 | 0,47 | 2,02 | 2,45 | 0,55 |
| Provider | Battery | 0,15 | 0,15 | 0,15 | 0,16 | 7,93 | 0,32 | 0,28 | 7,93 | 1,09 |
| Provider | Battery_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Battery_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Battery_ReadTimeMs | 0,00 | 0,15 | 0,15 | 0,16 | 0,32 | 0,16 | 0,19 | 0,32 | 0,04 |
| Provider | Battery_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Battery_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Battery_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 7,93 | 0,16 | 0,00 | 7,93 | 1,11 |
| Provider | CPU | 0,14 | 0,14 | 0,15 | 0,16 | 1,04 | 0,17 | 0,27 | 1,04 | 0,13 |
| Provider | CPU_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,96 | 1,00 | 1,00 | 0,20 |
| Provider | CPU_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,04 | 0,00 | 1,00 | 0,20 |
| Provider | CPU_ReadTimeMs | 0,00 | 0,14 | 0,15 | 0,15 | 0,29 | 0,15 | 0,18 | 0,29 | 0,04 |
| Provider | CPU_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,04 | 0,00 | 1,00 | 0,20 |
| Provider | CPU_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | CPU_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 1,04 | 0,03 | 0,00 | 1,04 | 0,15 |
| Provider | Docker | 0,17 | 0,17 | 0,18 | 0,18 | 2,02 | 0,22 | 0,30 | 2,02 | 0,26 |
| Provider | Docker_CacheHit | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Docker_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_ReadTimeMs | 0,17 | 0,17 | 0,18 | 0,18 | 2,02 | 0,22 | 0,30 | 2,02 | 0,26 |
| Provider | Docker_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet | 5,18 | 5,32 | 5,48 | 6,00 | 8,54 | 5,81 | 7,79 | 8,54 | 0,78 |
| Provider | DotNet_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | DotNet_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_UpdateTimeMs | 5,18 | 5,32 | 5,48 | 6,00 | 8,54 | 5,81 | 7,79 | 8,54 | 0,78 |
| Provider | Git | 0,45 | 0,47 | 0,49 | 0,52 | 67,33 | 1,88 | 0,62 | 67,33 | 9,35 |
| Provider | Git_CacheHit | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Git_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Git_ReadTimeMs | 0,00 | 0,47 | 0,49 | 0,51 | 2,49 | 0,53 | 0,62 | 2,49 | 0,29 |
| Provider | Git_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Git_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Git_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 67,33 | 1,35 | 0,00 | 67,33 | 9,43 |
| Provider | Kubernetes | 0,17 | 0,18 | 0,18 | 0,20 | 0,44 | 0,20 | 0,30 | 0,44 | 0,05 |
| Provider | Kubernetes_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Kubernetes_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Kubernetes_ReadTimeMs | 0,00 | 0,17 | 0,18 | 0,20 | 0,32 | 0,19 | 0,27 | 0,32 | 0,04 |
| Provider | Kubernetes_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Kubernetes_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Kubernetes_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,44 | 0,01 | 0,00 | 0,44 | 0,06 |
| Provider | Memory | 0,14 | 0,14 | 0,15 | 0,15 | 118,60 | 2,66 | 1,95 | 118,60 | 16,57 |
| Provider | Memory_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Memory_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Memory_ReadTimeMs | 0,00 | 0,14 | 0,15 | 0,15 | 2,09 | 0,29 | 1,93 | 2,09 | 0,49 |
| Provider | Memory_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Memory_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Memory_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 118,60 | 2,37 | 0,00 | 118,60 | 16,60 |
| Provider | Node | 5,46 | 5,66 | 5,84 | 6,34 | 9,31 | 6,12 | 7,86 | 9,31 | 0,75 |
| Provider | Node_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Node_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_UpdateTimeMs | 5,46 | 5,66 | 5,84 | 6,34 | 9,31 | 6,12 | 7,86 | 9,31 | 0,75 |
| Provider | Path | 0,13 | 0,13 | 0,14 | 0,15 | 0,91 | 0,16 | 0,24 | 0,91 | 0,11 |
| Provider | Path_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Project | 0,16 | 0,17 | 0,18 | 0,19 | 0,51 | 0,19 | 0,29 | 0,51 | 0,05 |
| Provider | Project_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Project_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Project_ReadTimeMs | 0,00 | 0,17 | 0,18 | 0,19 | 0,32 | 0,18 | 0,24 | 0,32 | 0,04 |
| Provider | Project_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Project_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Project_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,51 | 0,01 | 0,00 | 0,51 | 0,07 |
| Provider | Python | 2,14 | 2,20 | 2,24 | 2,31 | 26,68 | 2,92 | 4,30 | 26,68 | 3,44 |
| Provider | Python_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Python_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_UpdateTimeMs | 2,14 | 2,20 | 2,24 | 2,31 | 26,68 | 2,92 | 4,30 | 26,68 | 3,44 |
| Provider | Session | 0,18 | 0,19 | 0,19 | 0,20 | 0,53 | 0,21 | 0,38 | 0,53 | 0,06 |
| Provider | Session_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL | 0,15 | 0,16 | 0,16 | 0,17 | 1,86 | 0,24 | 0,34 | 1,86 | 0,33 |
| Provider | WSL_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Segment | Battery | 0,10 | 0,10 | 0,10 | 0,11 | 0,50 | 0,11 | 0,15 | 0,50 | 0,06 |
| Segment | CPU | 0,22 | 0,23 | 0,24 | 0,26 | 2,24 | 0,30 | 0,44 | 2,24 | 0,28 |
| Segment | Docker | 0,10 | 0,10 | 0,10 | 0,11 | 0,13 | 0,10 | 0,12 | 0,13 | 0,01 |
| Segment | DotNet | 0,11 | 0,11 | 0,12 | 0,12 | 0,27 | 0,12 | 0,17 | 0,27 | 0,02 |
| Segment | Git | 0,23 | 0,24 | 0,25 | 0,26 | 1,21 | 0,28 | 0,45 | 1,21 | 0,14 |
| Segment | Kubernetes | 0,10 | 0,10 | 0,10 | 0,11 | 0,15 | 0,10 | 0,12 | 0,15 | 0,01 |
| Segment | Memory | 0,22 | 0,23 | 0,23 | 0,24 | 0,43 | 0,24 | 0,27 | 0,43 | 0,03 |
| Segment | Node | 0,10 | 0,10 | 0,11 | 0,11 | 1,93 | 0,14 | 0,12 | 1,93 | 0,25 |
| Segment | Path | 0,20 | 0,21 | 0,22 | 0,23 | 0,32 | 0,23 | 0,27 | 0,32 | 0,02 |
| Segment | Project | 0,20 | 0,21 | 0,21 | 0,22 | 0,24 | 0,21 | 0,24 | 0,24 | 0,01 |
| Segment | Python | 0,10 | 0,10 | 0,10 | 0,11 | 0,13 | 0,11 | 0,12 | 0,13 | 0,01 |
| Segment | Session | 0,20 | 0,20 | 0,21 | 0,22 | 2,80 | 0,42 | 2,21 | 2,80 | 0,64 |
| Segment | WSL | 0,10 | 0,10 | 0,10 | 0,11 | 0,49 | 0,12 | 0,16 | 0,49 | 0,06 |

## Histograma de Latencia Total
| Rango de Tiempo | Frecuencia | Porcentaje | Gráfico |
| --- | --- | --- | --- |
| 20.86 - 60.84 ms | 49 | 98,00% | ######################## |
| 60.84 - 100.81 ms | 0 | 0,00% |  |
| 100.81 - 140.78 ms | 0 | 0,00% |  |
| 140.78 - 180.75 ms | 0 | 0,00% |  |
| 180.75 - 220.72 ms | 1 | 2,00% |  |

## Curva Acumulativa de Latencia
| Hito | Valor Límite (ms) | Porcentaje Acumulado |
| --- | --- | --- |
| Min | 20,86 ms | 0,0% |
| Q1 | 23,43 ms | 25,0% |
| Median | 23,91 ms | 50,0% |
| Q3 | 24,84 ms | 75,0% |
| P95 | 26,91 ms | 95,0% |
| P99 | 220,72 ms | 99,0% |
| Max | 220,72 ms | 100,0% |


# PPF Statistical Performance Report
Generado el: 2026-07-05 10:36:29 | Iteraciones: 50

## Resumen de Cache
- **Hits**: 444
- **Misses**: 158
- **Expiraciones**: 1
- **Refrescos (Writes)**: 8

## Métricas Principales
| Categoría | Componente | Mín (ms) | Q1 (ms) | Mediana (ms) | Q3 (ms) | Máx (ms) | Promedio (ms) | P95 (ms) | P99 (ms) | Desv. Est. (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Total** | Prompt | 20,60 | 22,82 | 23,17 | 24,25 | 203,58 | 27,85 | 35,19 | 203,58 | 25,34 |
| **Renderer** | Plain | 0,25 | 0,26 | 0,27 | 0,29 | 0,81 | 0,29 | 0,36 | 0,81 | 0,08 |
| Provider | Battery | 0,15 | 0,15 | 0,15 | 0,16 | 7,55 | 0,32 | 0,50 | 7,55 | 1,04 |
| Provider | Battery_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Battery_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Battery_ReadTimeMs | 0,00 | 0,15 | 0,15 | 0,16 | 0,53 | 0,17 | 0,24 | 0,53 | 0,08 |
| Provider | Battery_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Battery_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Battery_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 7,55 | 0,15 | 0,00 | 7,55 | 1,06 |
| Provider | CPU | 0,14 | 0,15 | 0,15 | 0,17 | 2,12 | 0,30 | 2,11 | 2,12 | 0,48 |
| Provider | CPU_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,96 | 1,00 | 1,00 | 0,20 |
| Provider | CPU_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,04 | 0,00 | 1,00 | 0,20 |
| Provider | CPU_ReadTimeMs | 0,00 | 0,15 | 0,15 | 0,16 | 2,12 | 0,27 | 2,11 | 2,12 | 0,47 |
| Provider | CPU_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,04 | 0,00 | 1,00 | 0,20 |
| Provider | CPU_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | CPU_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,99 | 0,03 | 0,00 | 0,99 | 0,14 |
| Provider | Docker | 0,17 | 0,18 | 0,18 | 0,19 | 1,99 | 0,23 | 0,33 | 1,99 | 0,26 |
| Provider | Docker_CacheHit | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Docker_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_ReadTimeMs | 0,17 | 0,18 | 0,18 | 0,19 | 1,99 | 0,23 | 0,33 | 1,99 | 0,26 |
| Provider | Docker_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Docker_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet | 4,99 | 5,16 | 5,29 | 5,87 | 8,79 | 5,63 | 7,18 | 8,79 | 0,78 |
| Provider | DotNet_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | DotNet_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | DotNet_UpdateTimeMs | 4,99 | 5,16 | 5,29 | 5,87 | 8,79 | 5,63 | 7,18 | 8,79 | 0,78 |
| Provider | Git | 0,45 | 0,46 | 0,48 | 0,52 | 59,82 | 1,91 | 2,97 | 59,82 | 8,30 |
| Provider | Git_CacheHit | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Git_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Git_ReadTimeMs | 0,00 | 0,46 | 0,48 | 0,52 | 3,97 | 0,72 | 2,51 | 3,97 | 0,74 |
| Provider | Git_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Git_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Git_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 59,82 | 1,20 | 0,00 | 59,82 | 8,37 |
| Provider | Kubernetes | 0,16 | 0,17 | 0,17 | 0,20 | 0,64 | 0,21 | 0,44 | 0,64 | 0,09 |
| Provider | Kubernetes_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Kubernetes_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Kubernetes_ReadTimeMs | 0,00 | 0,17 | 0,17 | 0,20 | 0,64 | 0,20 | 0,43 | 0,64 | 0,09 |
| Provider | Kubernetes_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Kubernetes_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Kubernetes_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,44 | 0,01 | 0,00 | 0,44 | 0,06 |
| Provider | Memory | 0,14 | 0,14 | 0,15 | 0,15 | 108,39 | 2,32 | 0,29 | 108,39 | 15,15 |
| Provider | Memory_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Memory_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Memory_ReadTimeMs | 0,00 | 0,14 | 0,15 | 0,15 | 0,34 | 0,15 | 0,21 | 0,34 | 0,04 |
| Provider | Memory_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Memory_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Memory_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 108,39 | 2,17 | 0,00 | 108,39 | 15,17 |
| Provider | Node | 5,35 | 5,52 | 5,67 | 6,00 | 9,21 | 6,08 | 8,32 | 9,21 | 0,94 |
| Provider | Node_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Node_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Node_UpdateTimeMs | 5,35 | 5,52 | 5,67 | 6,00 | 9,21 | 6,08 | 8,32 | 9,21 | 0,94 |
| Provider | Path | 0,13 | 0,13 | 0,13 | 0,14 | 0,85 | 0,15 | 0,16 | 0,85 | 0,10 |
| Provider | Path_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Path_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Project | 0,16 | 0,17 | 0,17 | 0,18 | 0,51 | 0,19 | 0,25 | 0,51 | 0,05 |
| Provider | Project_CacheHit | 0,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,98 | 1,00 | 1,00 | 0,14 |
| Provider | Project_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Project_ReadTimeMs | 0,00 | 0,17 | 0,17 | 0,18 | 0,28 | 0,18 | 0,23 | 0,28 | 0,03 |
| Provider | Project_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 1,00 | 0,02 | 0,00 | 1,00 | 0,14 |
| Provider | Project_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Project_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,51 | 0,01 | 0,00 | 0,51 | 0,07 |
| Provider | Python | 2,08 | 2,17 | 2,20 | 2,64 | 4,87 | 2,55 | 4,24 | 4,87 | 0,69 |
| Provider | Python_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_CacheMiss | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 0,00 |
| Provider | Python_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Python_UpdateTimeMs | 2,08 | 2,17 | 2,20 | 2,64 | 4,87 | 2,55 | 4,24 | 4,87 | 0,69 |
| Provider | Session | 0,18 | 0,19 | 0,20 | 0,21 | 2,68 | 0,38 | 2,14 | 2,68 | 0,58 |
| Provider | Session_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | Session_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL | 0,15 | 0,16 | 0,16 | 0,17 | 0,28 | 0,17 | 0,20 | 0,28 | 0,02 |
| Provider | WSL_CacheHit | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_CacheMiss | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_ReadTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_Refresh | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_TTLExpired | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Provider | WSL_UpdateTimeMs | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| Segment | Battery | 0,10 | 0,10 | 0,10 | 0,10 | 2,16 | 0,15 | 0,14 | 2,16 | 0,29 |
| Segment | CPU | 0,23 | 0,23 | 0,24 | 0,25 | 0,41 | 0,25 | 0,34 | 0,41 | 0,03 |
| Segment | Docker | 0,10 | 0,10 | 0,10 | 0,11 | 0,18 | 0,11 | 0,13 | 0,18 | 0,01 |
| Segment | DotNet | 0,11 | 0,11 | 0,12 | 0,12 | 0,21 | 0,12 | 0,19 | 0,21 | 0,02 |
| Segment | Git | 0,23 | 0,24 | 0,25 | 0,26 | 2,95 | 0,41 | 2,22 | 2,95 | 0,54 |
| Segment | Kubernetes | 0,10 | 0,10 | 0,10 | 0,10 | 0,16 | 0,11 | 0,13 | 0,16 | 0,01 |
| Segment | Memory | 0,22 | 0,23 | 0,24 | 0,24 | 0,38 | 0,24 | 0,31 | 0,38 | 0,03 |
| Segment | Node | 0,10 | 0,10 | 0,11 | 0,11 | 0,28 | 0,11 | 0,15 | 0,28 | 0,03 |
| Segment | Path | 0,20 | 0,21 | 0,21 | 0,23 | 1,32 | 0,25 | 0,46 | 1,32 | 0,16 |
| Segment | Project | 0,20 | 0,21 | 0,21 | 0,22 | 0,54 | 0,23 | 0,29 | 0,54 | 0,05 |
| Segment | Python | 0,10 | 0,10 | 0,10 | 0,11 | 2,24 | 0,29 | 2,09 | 2,24 | 0,56 |
| Segment | Session | 0,20 | 0,21 | 0,21 | 0,22 | 0,41 | 0,22 | 0,29 | 0,41 | 0,03 |
| Segment | WSL | 0,10 | 0,10 | 0,10 | 0,11 | 0,13 | 0,11 | 0,12 | 0,13 | 0,01 |

## Histograma de Latencia Total
| Rango de Tiempo | Frecuencia | Porcentaje | Gráfico |
| --- | --- | --- | --- |
| 20.6 - 57.2 ms | 49 | 98,00% | ######################## |
| 57.2 - 93.79 ms | 0 | 0,00% |  |
| 93.79 - 130.39 ms | 0 | 0,00% |  |
| 130.39 - 166.98 ms | 0 | 0,00% |  |
| 166.98 - 203.58 ms | 1 | 2,00% |  |

## Curva Acumulativa de Latencia
| Hito | Valor Límite (ms) | Porcentaje Acumulado |
| --- | --- | --- |
| Min | 20,60 ms | 0,0% |
| Q1 | 22,82 ms | 25,0% |
| Median | 23,17 ms | 50,0% |
| Q3 | 24,25 ms | 75,0% |
| P95 | 35,19 ms | 95,0% |
| P99 | 203,58 ms | 99,0% |
| Max | 203,58 ms | 100,0% |


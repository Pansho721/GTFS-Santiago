# Diccionario de datos — GTFS Santiago

Describe cada archivo de `DATA/`: qué representa, qué columnas tiene y cómo se relaciona con el resto.
Las cifras corresponden al feed **V168.20261003** (Red Metropolitana de Movilidad, vigente del 2026-10-03 al 2026-12-31).

GTFS (*General Transit Feed Specification*) es un estándar abierto para describir la oferta programada de transporte público. Cada archivo `.txt` es un CSV con cabecera. La especificación completa está en <https://gtfs.org/documentation/schedule/reference/>.

---

## Resumen

| Archivo | Filas | Qué identifica | Clave primaria |
|---|---:|---|---|
| [agency.txt](#agencytxt) | 4 | Operadores del sistema | `agency_id` |
| [routes.txt](#routestxt) | 428 | Líneas o recorridos (ej. 101, L1) | `route_id` |
| [trips.txt](#tripstxt) | 26 159 | Viajes concretos de una ruta | `trip_id` |
| [stop_times.txt](#stop_timestxt) | 1 098 529 | Horario de paso de cada viaje por cada parada | `trip_id` + `stop_sequence` |
| [stops.txt](#stopstxt) | 18 455 | Paraderos, estaciones, andenes, accesos | `stop_id` |
| [calendar.txt](#calendartxt) | 6 | Qué días de la semana opera cada servicio | `service_id` |
| [calendar_dates.txt](#calendar_datestxt) | 12 | Excepciones al calendario (feriados) | `service_id` + `date` |
| [frequencies.txt](#frequenciestxt) | 14 542 | Intervalo entre buses por franja horaria | `trip_id` + `start_time` |
| [shapes.txt](#shapestxt) | 456 573 | Trazado geográfico de los recorridos | `shape_id` + `shape_pt_sequence` |
| [levels.txt](#levelstxt) | 474 | Pisos o niveles dentro de estaciones | `level_id` |
| [pathways.txt](#pathwaystxt) | 7 388 | Conexiones peatonales dentro de estaciones | `pathway_id` |
| [feed_info.txt](#feed_infotxt) | 1 | Metadatos del feed (versión, vigencia) | — |

## Relaciones

```
agency ─1:N─ routes ─1:N─ trips ─1:N─ stop_times ─N:1─ stops ─N:1─ levels
                            │  │                         │
                            │  └─N:1─ shapes             └─ pathways (stop → stop)
                            ├─N:1─ calendar / calendar_dates  (service_id)
                            └─1:N─ frequencies
```

- `routes.agency_id` → `agency.agency_id`
- `trips.route_id` → `routes.route_id`
- `trips.service_id` → `calendar.service_id` / `calendar_dates.service_id`
- `trips.shape_id` → `shapes.shape_id`
- `stop_times.trip_id` → `trips.trip_id`
- `stop_times.stop_id` → `stops.stop_id`
- `frequencies.trip_id` → `trips.trip_id`
- `stops.parent_station` → `stops.stop_id` (autorreferencia)
- `stops.level_id` → `levels.level_id`
- `pathways.from_stop_id` / `to_stop_id` → `stops.stop_id`

---

## agency.txt

**Qué identifica:** las empresas u organismos que operan el transporte.

| Columna | Tipo | Descripción |
|---|---|---|
| `agency_id` | texto | Identificador del operador. |
| `agency_name` | texto | Nombre legible. |
| `agency_url` | URL | Sitio web del operador. |
| `agency_timezone` | texto | Zona horaria (`America/Santiago`). Todos los horarios del feed están en esta zona. |
| `agency_phone` | texto | Teléfono (solo lo informa Metro). |
| `agency_fare_url` | URL | Página de tarifas. |
| `agency_email` | texto | Correo de contacto (solo Metro). |
| `agency_lang` | texto | Idioma (solo Metro: `es`). |

Valores en este feed:

| `agency_id` | Operador | Rutas |
|---|---|---:|
| `RM` | Red Metropolitana de Movilidad (buses) | 418 |
| `M` | Metro de Santiago | 7 |
| `MT` | EFE Trenes de Chile | 2 |
| `BAA` | Bus de Acercamiento Aeropuerto | 1 |

---

## routes.txt

**Qué identifica:** cada línea de transporte tal como la conoce el usuario (el "recorrido 101", la "Línea 1").

| Columna | Tipo | Descripción |
|---|---|---|
| `route_id` | texto | Identificador de la ruta (ej. `101`, `L1`, `MTN`). |
| `agency_id` | texto | Operador → `agency.txt`. |
| `route_short_name` | texto | Nombre corto que aparece en el bus o en la señalética. |
| `route_long_name` | texto | Nombre descriptivo, normalmente "origen - destino" (ej. `Recoleta - Cerrillos`). `(M)` indica que conecta con Metro. |
| `route_desc` | texto | Descripción. Vacía en todo el feed. |
| `route_type` | entero | Modo de transporte (ver tabla). |
| `route_url` | URL | Página de la ruta. Solo la tienen Metro y EFE. |
| `route_color` | hex | Color de la línea, sin `#` (ej. `C8102E` es el rojo de L1). |
| `route_text_color` | hex | Color del texto sobre `route_color`. |

`route_type`:

| Valor | Significado | Rutas |
|---:|---|---:|
| 0 | Tren ligero / tranvía (EFE: `MTN`, `MTR`) | 2 |
| 1 | Metro / subterráneo (L1, L2, L3, L4, L4A, L5, L6) | 7 |
| 3 | Bus | 419 |

---

## trips.txt

**Qué identifica:** cada viaje individual: una ruta, en un sentido, con un tipo de día y un trazado. Por ejemplo, "el 101 hacia Cerrillos en día laboral".

| Columna | Tipo | Descripción |
|---|---|---|
| `route_id` | texto | Ruta a la que pertenece → `routes.txt`. |
| `service_id` | texto | Días en que opera → `calendar.txt`. |
| `trip_id` | texto | Identificador único del viaje. |
| `trip_headsign` | texto | Destino que muestra el letrero (ej. `Cerrillos`). |
| `direction_id` | 0/1 | Sentido: `0` = ida, `1` = regreso. |
| `shape_id` | texto | Trazado geográfico → `shapes.txt`. |
| `trip_short_name` | texto | Nombre corto del viaje. Solo Metro. |
| `wheelchair_accessible` | 0/1/2 | Accesibilidad del vehículo (0 = sin info, 1 = sí, 2 = no). Solo Metro. |
| `bikes_allowed` | 0/1/2 | Si se permiten bicicletas (misma codificación). Solo Metro. |

**Formato de `trip_id`:**
- Buses: `<ruta>-<sentido>-<servicio>-<bloque>`, por ejemplo `101-I-D-B23` (ruta 101, **I**da, **D**omingo, bloque horario B23). `R` = regreso.
- Metro: `DL_L1_140_192110_V1`. Son viajes con hora exacta (ver `stop_times`).

Los buses y el BAA no tienen viajes con hora exacta. Cada `trip_id` es una **plantilla** que se repite según `frequencies.txt`. Metro y parte de EFE sí publican cada salida con su horario.

| Operador | Viajes con frecuencia | Viajes con horario explícito |
|---|---:|---:|
| RM | 14 486 | 0 |
| M | 0 | 11 528 |
| MT | 38 | 89 |
| BAA | 18 | 0 |

---

## stop_times.txt

**Qué identifica:** la secuencia de paradas de cada viaje y la hora de llegada y salida en cada una. Es el archivo más grande del feed (~49 MB) y el núcleo del horario.

| Columna | Tipo | Descripción |
|---|---|---|
| `trip_id` | texto | Viaje → `trips.txt`. |
| `arrival_time` | HH:MM:SS | Hora de llegada a la parada. |
| `departure_time` | HH:MM:SS | Hora de salida de la parada. |
| `stop_id` | texto | Parada → `stops.txt`. |
| `stop_sequence` | entero | Orden de la parada dentro del viaje (creciente, no necesariamente consecutivo). |
| `pickup_type` | 0–3 | Si se puede subir: 0 = normal, 1 = no se puede subir. Vacío equivale a 0. |
| `drop_off_type` | 0–3 | Si se puede bajar (misma codificación). |
| `timepoint` | 0/1 | 1 = la hora es exacta, 0 = es aproximada. |

**Cómo interpretar las horas:**
- En los **viajes con frecuencia** (buses), las horas son **relativas al inicio del viaje**: la primera parada es `0:00:00` y las siguientes indican cuánto tiempo pasa desde la salida. Para obtener horas reales hay que sumarlas a cada salida generada desde `frequencies.txt`.
- En los **viajes con horario** (Metro), las horas son reales (ej. `19:29:59`).
- GTFS permite horas ≥ 24:00:00 para viajes que cruzan la medianoche. En este feed no hay ninguna (el máximo es `23:47:28`).
- **Ojo:** 13 541 filas vienen sin el cero inicial (`0:00:00` en vez de `00:00:00`). Hay que normalizarlas antes de parsearlas o compararlas como texto.

---

## stops.txt

**Qué identifica:** todos los puntos físicos de la red. Incluye paraderos de bus, estaciones de Metro y, dentro de ellas, andenes, accesos y nodos de circulación.

| Columna | Tipo | Descripción |
|---|---|---|
| `stop_id` | texto | Identificador único (ej. `PD1641` para un paradero, `AG` para una estación de Metro). |
| `stop_code` | texto | Código visible para el público. Solo 28 registros lo tienen. |
| `stop_name` | texto | Nombre. Los paraderos de bus siguen el formato `<código>-<descripción>`. |
| `stop_lat` | decimal | Latitud WGS84. Vacía en los nodos internos de estación. |
| `stop_lon` | decimal | Longitud WGS84. |
| `stop_url` | URL | Vacía en todo el feed. |
| `wheelchair_boarding` | 0/1/2 | Accesibilidad en silla de ruedas (0 = sin info, 1 = accesible, 2 = no accesible). |
| `location_type` | 0–4 | Tipo de punto (ver tabla). Vacío equivale a 0. |
| `parent_station` | texto | Estación que contiene a este punto → `stops.stop_id`. |
| `level_id` | texto | Nivel o piso en que está → `levels.txt`. |

`location_type`:

| Valor | Significado | Registros |
|---:|---|---:|
| vacío / 0 | Parada o andén donde se sube al vehículo. Los paraderos de bus vienen vacíos; los andenes de Metro vienen con `0` | 12 180 + 286 |
| 1 | Estación (agrupa andenes, accesos y nodos) | 126 |
| 2 | Entrada o salida de la estación | 298 |
| 3 | Nodo genérico (pie de una escalera, ascensor, zona paga, etc.) | 5 031 |
| 4 | Área de abordaje (punto específico del andén) | 534 |

**Jerarquía dentro de una estación**, con Camino Agrícola (`AG`) como ejemplo:
```
AG                 (1, estación)
├── AG:A           (2, acceso "El Pinar / Av. Escuela Agrícola", nivel AG:L0)
├── AG:ZP          (3, nodo "zona paga", nivel AG:L1)
├── AG:ASC03_TOP   (3, nodo: parte superior de un ascensor)
└── AG_L5_V1       (0, andén L5 vía 1, nivel AG:L2)
    └── AG:L5-V1_BA_01 (4, punto medio del andén)
```

---

## calendar.txt

**Qué identifica:** los tipos de día de servicio y en qué días de la semana aplica cada uno.

| Columna | Tipo | Descripción |
|---|---|---|
| `service_id` | texto | Identificador del tipo de servicio. |
| `monday` … `sunday` | 0/1 | 1 = el servicio opera ese día. |
| `start_date` | YYYYMMDD | Inicio de vigencia. |
| `end_date` | YYYYMMDD | Fin de vigencia. |

Servicios en este feed (todos vigentes del 20261003 al 20261231):

| `service_id` | Días | Interpretación |
|---|---|---|
| `L` | lun–vie | Laboral |
| `S` | sáb | Sábado |
| `D` | dom | Domingo |
| `F` | dom | Feriado (opera el domingo y los feriados de `calendar_dates`) |
| `LJ` | lun–jue | Laboral lunes a jueves (Metro) |
| `V` | vie | Viernes (Metro) |

---

## calendar_dates.txt

**Qué identifica:** las excepciones puntuales al calendario semanal, que en la práctica son los **feriados**.

| Columna | Tipo | Descripción |
|---|---|---|
| `service_id` | texto | Servicio afectado → `calendar.txt`. |
| `date` | YYYYMMDD | Fecha de la excepción. |
| `exception_type` | 1/2 | `1` = el servicio **se agrega** ese día, `2` = el servicio **se quita** ese día. |

Ejemplo: el 2026-10-12 (lunes feriado) se quita `L` y se agregan `D` y `F`, así que ese día opera con horario de domingo. Feriados incluidos: 12-oct, 31-oct, 08-dic y 25-dic.

Para saber qué servicios operan en una fecha: se toman los de `calendar` según el día de la semana y el rango de vigencia, se agregan los que tengan `exception_type = 1` en esa fecha y se quitan los que tengan `exception_type = 2`.

---

## frequencies.txt

**Qué identifica:** cada cuánto pasa un bus en una franja horaria. En vez de listar cada salida, GTFS define un viaje plantilla y el intervalo con que se repite.

| Columna | Tipo | Descripción |
|---|---|---|
| `trip_id` | texto | Viaje plantilla → `trips.txt`. |
| `start_time` | HH:MM:SS | Inicio de la franja. |
| `end_time` | HH:MM:SS | Fin de la franja. |
| `headway_secs` | entero | Segundos entre salidas consecutivas (en este feed van de 186 s ≈ 3 min a 19 800 s = 5,5 h). |
| `exact_times` | 0/1 | `0` = frecuencia aproximada ("pasa cada ~X min"), `1` = salidas exactas. Aquí siempre es `0`. |

Ejemplo: `101-I-D-B23, 05:30:00, 07:30:00, 1200` significa que el 101 en sentido ida sale cada 20 minutos entre las 05:30 y las 07:30 los domingos.

Cada `trip_id` de este archivo aparece una sola vez. Es decir, cada bloque horario (`B23`, `B24`, …) es un `trip_id` distinto, y su secuencia de paradas en `stop_times` puede tener tiempos de viaje diferentes según la congestión de esa franja.

---

## shapes.txt

**Qué identifica:** el recorrido geográfico que sigue el vehículo, como una polilínea de puntos. Sirve para dibujar las rutas en un mapa y calcular distancias.

| Columna | Tipo | Descripción |
|---|---|---|
| `shape_id` | texto | Identificador del trazado (ej. `101I` = ruta 101, ida). |
| `shape_pt_lat` | decimal | Latitud del punto. |
| `shape_pt_lon` | decimal | Longitud del punto. |
| `shape_pt_sequence` | entero | Orden del punto dentro del trazado. |

Hay 981 trazados en el archivo, pero `trips.txt` solo usa 859. Para reconstruir una línea hay que agrupar por `shape_id` y ordenar por `shape_pt_sequence`.

---

## levels.txt

**Qué identifica:** los niveles o pisos dentro de las estaciones de Metro. Se usa junto con `pathways` para modelar la navegación interna (accesibilidad, transbordos).

| Columna | Tipo | Descripción |
|---|---|---|
| `level_id` | texto | Identificador con formato `<estación>:L<n>` (ej. `AG:L0`). |
| `level_index` | decimal | Posición vertical: `0` = calle; los valores mayores son niveles más profundos o más altos según la estación. |
| `level_name` | texto | Nombre legible (ej. `Nivel 1 – Acceso / Calle`, `Nivel 3 – Andenes`). |

Hay 474 niveles repartidos en 149 estaciones.

---

## pathways.txt

**Qué identifica:** las conexiones peatonales entre puntos de una estación (pasillos, escaleras, ascensores, torniquetes). Forma un grafo que permite calcular rutas internas y tiempos de transbordo.

| Columna | Tipo | Descripción |
|---|---|---|
| `pathway_id` | texto | Identificador de la conexión. |
| `from_stop_id` | texto | Punto de origen → `stops.txt`. |
| `to_stop_id` | texto | Punto de destino → `stops.txt`. |
| `pathway_mode` | 1–7 | Tipo de conexión (ver tabla). |
| `is_bidirectional` | 0/1 | `1` = se puede recorrer en ambos sentidos. |
| `length` | decimal | Largo en metros. |
| `traversal_time` | entero | Segundos que toma recorrerla. |
| `stair_count` | entero | Número de escalones. Negativo = se baja de `from` a `to`. |
| `max_slope` | decimal | Pendiente máxima. Casi siempre vacía. |
| `min_width` | decimal | Ancho mínimo en metros. Casi siempre vacío. |

`pathway_mode`:

| Valor | Significado | Registros |
|---:|---|---:|
| 1 | Pasillo / caminata | 4 714 |
| 2 | Escalera | 1 023 |
| 4 | Escalera mecánica | 459 |
| 5 | Ascensor | 509 |
| 6 | Torniquete de entrada (paso a zona paga) | 302 |
| 7 | Salida de zona paga | 381 |

---

## feed_info.txt

**Qué identifica:** los metadatos del propio feed. Sirve para saber qué versión se está procesando y hasta cuándo es válida.

| Columna | Valor en este feed | Descripción |
|---|---|---|
| `feed_publisher_name` | Red Metropolitana | Quién publica el feed. |
| `feed_publisher_url` | http://www.red.cl | Sitio del publicador. |
| `feed_lang` | es | Idioma. |
| `feed_start_date` | 20261003 | Inicio de vigencia. |
| `feed_end_date` | 20261231 | Fin de vigencia (`setup.sh` avisa cuando el feed está vencido). |
| `feed_version` | V168.20261003 | Versión. Útil para versionar las cargas del ETL. |

---

## Notas para el ETL

- **Leer todo como texto primero** (`all_varchar=true` en DuckDB, `dtype=str` en pandas). Así no se pierden ceros a la izquierda en los IDs y se evita que las horas ≥ 24:00 fallen al parsearlas.
- **Normalizar horas** a `HH:MM:SS` (13 541 filas de `stop_times` vienen como `H:MM:SS`) y convertirlas a segundos desde medianoche para operar.
- **Expandir frecuencias** para obtener las salidas reales de los buses: por cada fila de `frequencies`, generar salidas en `start_time, start_time + headway, …` mientras sean menores que `end_time`, y sumar los tiempos relativos de `stop_times`.
- **Separar paradas de nodos internos:** para análisis de red de buses, filtrar `stops` con `location_type` vacío o `0`. Los nodos 2–4 solo sirven para la navegación interna de estaciones.
- **Fechas** en formato `YYYYMMDD` → convertir a `DATE`.

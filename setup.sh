#!/usr/bin/env bash
# Verifica que el dataset GTFS de Santiago esté disponible en DATA/.
# Si faltan archivos pero hay un .zip en DATA/ZIP/, lo descomprime.
# Si no hay nada, indica cómo descargarlo.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$ROOT_DIR/DATA"
ZIP_DIR="$DATA_DIR/ZIP"
GTFS_URL="https://www.dtpm.cl/index.php/gtfs-vigente"

# Archivos obligatorios según la especificación GTFS
REQUIRED_FILES=(agency.txt stops.txt routes.txt trips.txt stop_times.txt)
# Al menos uno de estos debe existir
CALENDAR_FILES=(calendar.txt calendar_dates.txt)
# Opcionales que usa el feed de Santiago
OPTIONAL_FILES=(feed_info.txt frequencies.txt shapes.txt levels.txt pathways.txt)

if [[ -t 1 ]]; then
    RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
    RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

ok()   { echo "  ${GREEN}✔${RESET} $1"; }
warn() { echo "  ${YELLOW}!${RESET} $1"; }
fail() { echo "  ${RED}✘${RESET} $1"; }

# Devuelve los archivos obligatorios que faltan
missing_files() {
    local missing=()
    for f in "${REQUIRED_FILES[@]}"; do
        [[ -s "$DATA_DIR/$f" ]] || missing+=("$f")
    done
    local has_calendar=0
    for f in "${CALENDAR_FILES[@]}"; do
        [[ -s "$DATA_DIR/$f" ]] && has_calendar=1
    done
    (( has_calendar )) || missing+=("calendar.txt|calendar_dates.txt")
    echo "${missing[@]:-}"
}

print_download_instructions() {
    cat <<EOF

${BOLD}No se encontró el dataset GTFS de Santiago.${RESET}

Para obtenerlo:
  1. Entra a la página de GTFS vigente del DTPM:
       ${GTFS_URL}
  2. Descarga el archivo .zip del GTFS vigente.
  3. Guárdalo en:
       ${ZIP_DIR}/
  4. Vuelve a ejecutar:
       ./setup.sh
     (el script lo descomprimirá en DATA/ automáticamente)

EOF
}

extract_zip() {
    local zip="$1"
    echo "Descomprimiendo $(basename "$zip") en DATA/ ..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -o -q -j "$zip" '*.txt' -d "$DATA_DIR"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$zip" "$DATA_DIR" <<'PY'
import sys, zipfile, os
zip_path, out_dir = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as z:
    for name in z.namelist():
        if name.endswith(".txt"):
            with open(os.path.join(out_dir, os.path.basename(name)), "wb") as f:
                f.write(z.read(name))
PY
    else
        fail "Se necesita 'unzip' o 'python3' para descomprimir el archivo."
        exit 1
    fi
}

echo "${BOLD}Verificando dataset GTFS en ${DATA_DIR}${RESET}"
mkdir -p "$DATA_DIR" "$ZIP_DIR"

missing="$(missing_files)"

if [[ -n "$missing" ]]; then
    warn "Faltan archivos: $missing"
    # Busca el zip más reciente en DATA/ZIP
    latest_zip="$(ls -1t "$ZIP_DIR"/*.zip 2>/dev/null | head -n 1 || true)"
    if [[ -n "$latest_zip" ]]; then
        extract_zip "$latest_zip"
        missing="$(missing_files)"
    fi
fi

if [[ -n "$missing" ]]; then
    fail "Dataset incompleto. Faltan: $missing"
    print_download_instructions
    exit 1
fi

for f in "${REQUIRED_FILES[@]}" "${CALENDAR_FILES[@]}" "${OPTIONAL_FILES[@]}"; do
    if [[ -s "$DATA_DIR/$f" ]]; then
        ok "$f ($(du -h "$DATA_DIR/$f" | cut -f1))"
    else
        warn "$f no encontrado (opcional)"
    fi
done

# Muestra la vigencia del feed si existe feed_info.txt
if [[ -s "$DATA_DIR/feed_info.txt" ]]; then
    IFS=',' read -r -a header < <(head -n 1 "$DATA_DIR/feed_info.txt" | tr -d '\r')
    IFS=',' read -r -a values < <(sed -n '2p' "$DATA_DIR/feed_info.txt" | tr -d '\r')
    declare -A info
    for i in "${!header[@]}"; do info[${header[$i]}]="${values[$i]:-}"; done

    echo
    echo "Feed: ${info[feed_publisher_name]:-?} — versión ${info[feed_version]:-?}"
    echo "Vigencia: ${info[feed_start_date]:-?} → ${info[feed_end_date]:-?}"

    end_date="${info[feed_end_date]:-}"
    if [[ -n "$end_date" && "$end_date" < "$(date +%Y%m%d)" ]]; then
        warn "El feed está vencido. Descarga uno nuevo desde ${GTFS_URL}"
    fi
fi

echo
echo "${GREEN}${BOLD}Dataset GTFS listo.${RESET}"

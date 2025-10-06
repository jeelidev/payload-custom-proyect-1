#!/bin/bash

# ==============================================================================
# Script para sincronizar cambios incrementales (esquema y datos)
# de una base de datos SQLite local a una base de datos remota en Turso.
#
# Versión 2.0:
# - El snapshot se genera exportando desde Turso (la fuente de la verdad).
# - Se puede elegir un objetivo de aplicación (remote o local para simulación).
#
# Uso:
#   ./sync_turso.sh <ruta_db_local> <nombre_db_turso> [remote|local]
#
# Ejemplos:
#   # Genera y aplica el parche a la base de datos remota de Turso
#   ./sync_turso.sh db/custom-proyect-1.db custom-proyect-1
#
#   # Genera y aplica el parche a una copia local para probarlo (dry-run)
#   ./sync_turso.sh db/custom-proyect-1.db custom-proyect-1 local
# ==============================================================================

# --- Colores para los mensajes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin Color

# --- 1. Validación de parámetros de entrada ---
if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    echo -e "${RED}Error: Se requieren 2 o 3 parámetros.${NC}"
    echo "Uso: $0 <ruta_db_local> <nombre_db_turso> [remote|local]"
    exit 1
fi

LOCAL_DB_PATH=$1
TURSO_DB_NAME=$2
TARGET=${3:-remote} # El tercer parámetro es el objetivo, por defecto 'remote'

if [[ "$TARGET" != "remote" && "$TARGET" != "local" ]]; then
    echo -e "${RED}Error: El tercer parámetro (target) debe ser 'remote' o 'local'.${NC}"
    exit 1
fi

# --- 2. Comprobación de dependencias ---
command -v sqldiff >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: 'sqldiff' no está instalado. Instálalo con 'sudo apt-get install sqlite3-tools'.${NC}"; exit 1; }
command -v turso >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: La CLI de 'turso' no está instalada.${NC}"; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: 'sqlite3' no está instalado. Instálalo con 'sudo apt-get install sqlite3'.${NC}"; exit 1; }

# --- 3. Definición de rutas y nombres de archivo ---
DB_DIR=$(dirname "$LOCAL_DB_PATH")
DB_FILENAME=$(basename "$LOCAL_DB_PATH")
DB_BASENAME="${DB_FILENAME%.*}"
SNAPSHOT_PATH="${DB_DIR}/${DB_BASENAME}_snapshot.db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PATCH_FILE_PATH="${DB_DIR}/incremental_changes_${TIMESTAMP}.sql"

# --- 4. Flujo principal ---
echo -e "${GREEN}--- Iniciando Sincronización Incremental (Modo: ${TARGET}) ---${NC}"
echo "Base de datos local (fuente de cambios): $LOCAL_DB_PATH"
echo "Base de datos remota (base de comparación): $TURSO_DB_NAME"
echo "------------------------------------------------------------------"

# 1. Descargar el estado actual de Turso para usarlo como snapshot
echo "1. Descargando snapshot actualizado de Turso a '$SNAPSHOT_PATH'..."
# Usamos --silent para una salida más limpia, pero puedes quitarlo para depurar
if ! turso db export "$TURSO_DB_NAME" --output-file "$SNAPSHOT_PATH"; then
    echo -e "${RED}ERROR: Falló la exportación desde Turso. ¿Existe la base de datos '$TURSO_DB_NAME'? ¿Estás autenticado?${NC}"
    exit 1
fi
echo -e "${GREEN}Snapshot descargado con éxito.${NC}"

# 2. Generar el parche de cambios
echo "2. Generando parche de cambios en '$PATCH_FILE_PATH'..."
sqldiff "$SNAPSHOT_PATH" "$LOCAL_DB_PATH" > "$PATCH_FILE_PATH"

# Si el archivo de parche está vacío, no hay cambios.
if [ ! -s "$PATCH_FILE_PATH" ]; then
    echo -e "${YELLOW}No se detectaron cambios. Tu base de datos local y la remota están sincronizadas.${NC}"
    rm "$PATCH_FILE_PATH" # Limpiamos el archivo vacío
    rm "$SNAPSHOT_PATH"   # Limpiamos el snapshot descargado
    exit 0
fi
echo -e "${GREEN}Cambios detectados. El parche se ha generado.${NC}"

# 3. Aplicar el parche según el objetivo (target)
echo "3. Aplicando parche al objetivo: ${YELLOW}${TARGET}${NC}..."

if [ "$TARGET" == "remote" ]; then
    # --- OBJETIVO: Remoto (Turso) ---
    if turso db shell "$TURSO_DB_NAME" < "$PATCH_FILE_PATH"; then
        echo -e "${GREEN}Parche aplicado con éxito a la base de datos remota de Turso.${NC}"
    else
        echo -e "${RED}ERROR: Falló la aplicación del parche a Turso. Revisa el error anterior.${NC}"
        rm "$SNAPSHOT_PATH" # Limpiamos el snapshot
        exit 1
    fi
elif [ "$TARGET" == "local" ]; then
    # --- OBJETIVO: Local (Simulación) ---
    # Creamos una copia del snapshot para no alterar el original
    TEMP_DB_PATH="${SNAPSHOT_PATH}.tmp"
    cp "$SNAPSHOT_PATH" "$TEMP_DB_PATH"

    echo "   (Simulando la aplicación en una copia temporal: $TEMP_DB_PATH)"
    if sqlite3 "$TEMP_DB_PATH" < "$PATCH_FILE_PATH"; then
        echo -e "${GREEN}Simulación exitosa. El parche SQL es válido y se aplicó a la copia local.${NC}"
    else
        echo -e "${RED}ERROR: Falló la aplicación del parche en la simulación local. El SQL puede ser inválido.${NC}"
        rm "$TEMP_DB_PATH" # Limpiamos la copia temporal
        rm "$SNAPSHOT_PATH" # Limpiamos el snapshot
        exit 1
    fi
    rm "$TEMP_DB_PATH" # Limpiamos la copia temporal al terminar
fi

# 4. Limpieza final
echo "4. Limpiando archivos temporales..."
rm "$SNAPSHOT_PATH"
echo -e "   (El archivo de parche ${YELLOW}${PATCH_FILE_PATH}${NC} se conserva para referencia)"

echo -e "\n${GREEN}--- Proceso completado ---${NC}"

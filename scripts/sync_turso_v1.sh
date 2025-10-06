#!/bin/bash

# ==============================================================================
# Script para sincronizar cambios incrementales (esquema y datos)
# de una base de datos SQLite local a una base de datos remota en Turso.
#
# Uso:
#   ./sync_turso.sh <ruta_al_archivo_db_local> <nombre_db_en_turso>
#
# Ejemplo:
#   ./sync_turso.sh db/custom-proyect-1.db custom-proyect-1
# ==============================================================================

# --- Colores para los mensajes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin Color

# --- 1. Validación de parámetros de entrada ---
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Error: Se requieren dos parámetros.${NC}"
    echo "Uso: $0 <ruta_al_archivo_db_local> <nombre_db_en_turso>"
    exit 1
fi

LOCAL_DB_PATH=$1
TURSO_DB_NAME=$2

# --- 2. Comprobación de dependencias ---
command -v sqldiff >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: 'sqldiff' no está instalado. Por favor, instálalo (ej. 'sudo apt-get install sqlite3-tools').${NC}"; exit 1; }
command -v turso >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: La CLI de 'turso' no está instalada. Por favor, instálala.${NC}"; exit 1; }

# --- 3. Definición de rutas y nombres de archivo ---
DB_DIR=$(dirname "$LOCAL_DB_PATH")
DB_FILENAME=$(basename "$LOCAL_DB_PATH")
DB_BASENAME="${DB_FILENAME%.*}"
SNAPSHOT_PATH="${DB_DIR}/${DB_BASENAME}_snapshot.db"

# --- 4. Flujo principal ---
echo -e "${GREEN}--- Iniciando Sincronización con Turso ---${NC}"
echo "Base de datos local: $LOCAL_DB_PATH"
echo "Base de datos remota: $TURSO_DB_NAME"
echo "Snapshot: $SNAPSHOT_PATH"
echo "-------------------------------------------"

# Si el snapshot no existe, es la primera ejecución. Lo creamos y salimos.
if [ ! -f "$SNAPSHOT_PATH" ]; then
  echo -e "${YELLOW}No se encontró un snapshot. Creando el snapshot inicial desde '$LOCAL_DB_PATH'...${NC}"
  cp "$LOCAL_DB_PATH" "$SNAPSHOT_PATH"
  echo -e "${GREEN}Snapshot '$SNAPSHOT_PATH' creado con éxito.${NC}"
  echo "Ahora, realiza cambios en tu base de datos local y vuelve a ejecutar este script."
  exit 0
fi

# Generar el parche con la fecha y hora en el nombre
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PATCH_FILE_PATH="${DB_DIR}/incremental_changes_${TIMESTAMP}.sql"
echo "1. Generando parche de cambios en '$PATCH_FILE_PATH'..."
sqldiff "$SNAPSHOT_PATH" "$LOCAL_DB_PATH" > "$PATCH_FILE_PATH"

# Si el archivo de parche está vacío, no hay cambios.
if [ ! -s "$PATCH_FILE_PATH" ]; then
    echo -e "${YELLOW}No se detectaron cambios. No hay nada que sincronizar.${NC}"
    rm "$PATCH_FILE_PATH" # Limpiamos el archivo vacío
    exit 0
fi

echo -e "${GREEN}Cambios detectados. El parche se ha generado.${NC}"

# Aplicar el parche a Turso
echo "2. Aplicando parche a la base de datos de Turso '$TURSO_DB_NAME'..."
if turso db shell "$TURSO_DB_NAME" < "$PATCH_FILE_PATH"; then
    echo -e "${GREEN}Parche aplicado con éxito a Turso.${NC}"
else
    echo -e "${RED}ERROR: Falló la aplicación del parche a Turso. Revisa el error anterior. El snapshot local NO será actualizado.${NC}"
    exit 1
fi

# Actualizar el snapshot local si todo salió bien
echo "3. Actualizando el snapshot local..."
cp "$LOCAL_DB_PATH" "$SNAPSHOT_PATH"
echo -e "${GREEN}Snapshot '$SNAPSHOT_PATH' actualizado al estado actual.${NC}"

echo -e "\n${GREEN}--- Sincronización completada con éxito ---${NC}"

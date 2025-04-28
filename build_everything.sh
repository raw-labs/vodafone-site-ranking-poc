#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 0 . Decide where things live -------------------------------------------------
#    • 1st CLI arg → SQLite file (defaults to output_<timestamp>.db)
#    • 2nd CLI arg → folder with .sql scripts   (defaults to sql/)
#    • 3rd CLI arg → path to regexp extension   (defaults to /opt/projects/sqlite_ext/regexp)
###############################################################################
DB_FILE=${1:-output_$(date '+%Y%m%d_%H%M%S').db}
SQL_DIR=${2:-sqlite}
EXT_PATH=${3:-/opt/projects/sqlite_ext/regexp}

echo "═══════════════════════════════════════════════════════"
echo "SQLite database : $DB_FILE"
echo "SQL scripts dir : $SQL_DIR"
echo "REGEXP extension: $EXT_PATH"
echo "═══════════════════════════════════════════════════════"

###############################################################################
# 1 . Extract raw tables from XLSX --------------------------------------------
###############################################################################
bash run_sqlite.sh "$DB_FILE"

###############################################################################
# 2 . Apply post-processing SQL with the extension ----------------------------
###############################################################################
python apply_sql_scripts.py  "$DB_FILE"  "$SQL_DIR"  "$EXT_PATH"

echo "All done – refreshed $(basename "$DB_FILE")"

#!/usr/bin/env bash
set -e                                # stop on first error

###############################################################################
# 0. decide which SQLite file to use
###############################################################################
DB_FILE=${1:-sqlite.db}               # 1st CLI arg or fallback to output.db
echo "→ Writing to: $DB_FILE"

###############################################################################
# 1. helper to avoid repetition
###############################################################################
run() {
  local EXCEL="$1" CONFIG="$2"
  echo -e "\n\nProcessing $(basename "$CONFIG" .json)"
  python excel_to_sqlite.py "$EXCEL" "$CONFIG" "$DB_FILE"
}

###############################################################################
# 2. the actual jobs
###############################################################################
run "structured-data-poc/Network Site List Updated 240225.xlsx"      config_network_site.json
run "structured-data-poc/MTX Site Capacity (Dulux).xlsx"             config_mtx_capacity_dulux.json
run "structured-data-poc/MTX Site Capacity (Dulux).xlsx"             config_mtx_capacity_dulux_XGL001.json
run "structured-data-poc/MTX Site Capacity (Dulux).xlsx"             config_mtx_capacity_dulux_XGL001_room_capability.json
run "structured-data-poc/MTX Site Capacity (Dulux).xlsx"             config_mtx_capacity_dulux_BKLN06.json
run "structured-data-poc/MTX Site Capacity (Dulux).xlsx"             config_mtx_capacity_dulux_BKLN06_room_capability.json
run "structured-data-poc/Fixed Site Capacity (CROWN).xlsx"           config_fixed_capacity_crown.json
run "structured-data-poc/Fixed Site Capacity (CROWN).xlsx"           config_fixed_capacity_crown_cover.json
run "structured-data-poc/Opex Data/Book1 (1).xlsx"                   config_bridge.json
run "structured-data-poc/Opex Data/Network Elec.xlsx"                config_opex.json
run "structured-data-poc/All_Network_Site_data_AO_02_12_24 sanitised.xlsx" config_ownership.json
run ignore_this                                                     config_historic_mtx_capacity.json
run ignore_this                                                     config_historic_mtx_capacity_dulux_XGL001.json
run ignore_this                                                     config_historic_mtx_capacity_dulux_XGL001_room_capability.json
run ignore_this                                                     config_historic_mtx_capacity_dulux_BKLN06.json
run ignore_this                                                     config_historic_mtx_capacity_dulux_BKLN06_room_capability.json
run ignore_this                                                     config_historic_fixed_capacity.json
run ignore_this                                                     config_historic_fixed_capacity_cover.json
run ignore_this                                                     config_space.json

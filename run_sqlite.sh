#!/bin/bash

echo -e "\n\nProcessing site"
python excel_to_sqlite.py "structured-data-poc/Network Site List Updated 240225.xlsx" config_network_site.json

echo -e "\n\nProcessing mobile site capacity"
python excel_to_sqlite.py "structured-data-poc/MTX Site Capacity (Dulux).xlsx" config_mtx_capacity_dulux.json

echo -e "\n\nProcessing mobile site capacity for code XGL001"
python excel_to_sqlite.py "structured-data-poc/MTX Site Capacity (Dulux).xlsx" config_mtx_capacity_dulux_XGL001.json

echo -e "\n\nProcessing mobile room capability for code XGL001"
python excel_to_sqlite.py "structured-data-poc/MTX Site Capacity (Dulux).xlsx" config_mtx_capacity_dulux_XGL001_room_capability.json

echo -e "\n\nProcessing mobile site capacity for code BKLN06"
python excel_to_sqlite.py "structured-data-poc/MTX Site Capacity (Dulux).xlsx" config_mtx_capacity_dulux_BKLN06.json

echo -e "\n\nProcessing mobile room capability for code BKLN06"
python excel_to_sqlite.py "structured-data-poc/MTX Site Capacity (Dulux).xlsx" config_mtx_capacity_dulux_BKLN06_room_capability.json

echo -e "\n\nProcessing fixed site capacity"
python excel_to_sqlite.py "structured-data-poc/Fixed Site Capacity (CROWN).xlsx" config_fixed_capacity_crown.json

echo -e "\n\nProcessing fixed site capacity - cover"
python excel_to_sqlite.py "structured-data-poc/Fixed Site Capacity (CROWN).xlsx" config_fixed_capacity_crown_cover.json

echo -e "\n\nProcessing bridge"
python excel_to_sqlite.py "structured-data-poc/Opex Data/Book1 (1).xlsx" config_bridge.json

echo -e "\n\nProcessing opex data"
python excel_to_sqlite.py "structured-data-poc/Opex Data/Network Elec.xlsx" config_opex.json

echo -e "\n\nProcessing ownership"
python excel_to_sqlite.py "structured-data-poc/All_Network_Site_data_AO_02_12_24 sanitised.xlsx" config_ownership.json

echo -e "\n\nProcessing historic mobile site capacity"
python excel_to_sqlite.py ignore_this config_historic_mtx_capacity.json

echo -e "\n\nProcessing historic fixed site capacity"
python excel_to_sqlite.py ignore_this config_historic_fixed_capacity.json

echo -e "\n\nProcessing space data"
python excel_to_sqlite.py ignore_this config_space.json

#!/bin/bash

echo -e "\n\nProcessing site"
python excel_to_postgres.py "poc-data-sources/structured_data/Network Site List Updated 240225(1).xlsx" config_network_site.json data_network_site_stringAll.sql

echo -e "\n\nProcessing mobile site capacity"
python excel_to_postgres.py "poc-data-sources/structured_data/MTX Site Capacity (Dulux)(1).xlsx" config_mtx_capacity_dulux.json data_mtx_capacity_stringAll.sql

echo -e "\n\nProcessing fixed site capacity"
python excel_to_postgres.py "poc-data-sources/structured_data/Fixed Site Capacity (CROWN)(1).xlsx" config_fixed_capacity_crown.json data_fixed_capacity_stringAll.sql

echo -e "\n\nProcessing bridge"
python excel_to_postgres.py "poc-data-sources/structured_data/opex/Book1 (1).xlsx" config_bridge.json data_bridge_stringAll.sql

echo -e "\n\nProcessing opex data"
python excel_to_postgres.py "poc-data-sources/structured_data/opex/Network Elec.xlsx" config_opex.json data_opex_stringAll.sql

echo -e "\n\nProcessing ownership"
python excel_to_postgres.py "poc-data-sources/structured_data/All_Network_Site_data_AO_02_12_24 sanitised.xlsx" config_ownership.json data_ownership_stringAll.sql

echo -e "\n\nProcessing historic mobile site capacity"
python excel_to_postgres.py ignore_this config_historic_mtx_capacity.json data_historic_mtx.sql

echo -e "\n\nProcessing space data"
python excel_to_postgres.py ignore_this config_space.json data_space.sql


echo -e "SET search_path TO vodafone_pov_4;" > alldata.sql
echo -e "" >> alldata.sql
cat data*sql >> alldata.sql

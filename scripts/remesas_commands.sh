./get_remesas_shapefile.py
for f in $(find ../datos/shapefiles/inegi_vivienda_2010/ -name "*shp"); do ./get_inegi_polygons_casillas_2018.py $f; done
./merge_inegi_remesas_txts.py

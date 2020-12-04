#!/usr/bin/env python3.6
"""
02. Obtiene una tabla con las propiedades de los puntos de las casillas de remesas 2018 del shapefile y las variables de los poligonos de inegi 2010 que contienen cada punto  
NOTA: Los distritos de las remesas y de los poligonos de inegi 2010 no coinciden. Los distritos de las casillas 2018 son 'distrito_f' y esos son los que
coinciden con los distritos de la tabla de remesas. Los distritos de INEGI son DISTRITO. 

# usage: ./get_inegi_polygons_casillas_2018.py ../datos/shapefiles/inegi_vivienda_2010/25/datos_geolectorales/9deac1b9659067d923084003d2ee75ff_geolectorales.shp
Input:
    args[1] shp: Shapefile de inegi de algun estado 
    remesas_casillas_2018.shp: Shapefile con los puntos de casillas de 2018 de remesas en ../datos/shapefiles/casillas_2018_shape
Output:
    txt: tabla con las propiedades de puntos de remesas y variables de poligonos de inegi. El nombre del txt es el mismo del shapefile de inegi. En ../datos/inegi_vivienda_2010
"""

import pandas as pd
from shapely.geometry import shape
from fiona.crs import to_string
import fiona
import os
import sys

txt_path = '../datos/inegi_vivienda_2010'
casillas_path = '../datos/shapefiles/casillas_2018_shape'
inegi_filename = sys.argv[1]
remesas_casillas_filename = 'remesas_casillas_2018.shp'

# abre shapefile de puntos de casillas
with fiona.open(os.path.join(casillas_path, remesas_casillas_filename), encoding='utf-8') as src:
    ca_crs_str = to_string(src.crs)
    ca_fc = list(src)
    ca_schema = src.schema

# abre shapefile de poligonos de inegi
with fiona.open(os.path.join(inegi_filename), encoding='utf-8') as src:
    in_crs_str = to_string(src.crs)
    in_fc = list(src)
    in_schema = src.schema

# Con doble loop se encuentran los poligonos que contienen los puntos de casilla y se guardan las propiedades de los puntos y las de los poligonos
dict_list = [dict(**{'entidad': ca['properties']['entidad'],
              'distrito_f': ca['properties']['distrito_f'],
              'municipio': ca['properties']['municipio'],
              'seccion': ca['properties']['seccion'],
              'casilla_list': ca['properties']['casilla']},
              **inegi['properties'])
              for ca in ca_fc for inegi in in_fc
             if shape(inegi['geometry']).contains(shape(ca['geometry'])) ]

# se crea dataframe y se eliminan duplicados
df = pd.DataFrame(dict_list).drop_duplicates()

# se guarda txt con nombre de shapefile de inegi
df.to_csv(os.path.join(txt_path, inegi_filename.split('/')[-1].split('.')[0] + '.txt'), index=False, sep='|')

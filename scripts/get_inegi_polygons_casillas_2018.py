#!/usr/bin/env python3.6
# usage: ./get_inegi_polygons_casillas_2018.py ../datos/shapefiles/inegi_vivienda_2010/25/datos_geolectorales/9deac1b9659067d923084003d2ee75ff_geolectorales.shp

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

with fiona.open(os.path.join(casillas_path, remesas_casillas_filename), encoding='utf-8') as src:
    ca_crs_str = to_string(src.crs)
    ca_fc = list(src)
    ca_schema = src.schema

with fiona.open(os.path.join(inegi_filename), encoding='utf-8') as src:
    in_crs_str = to_string(src.crs)
    in_fc = list(src)
    in_schema = src.schema

dict_list = [dict(**{'entidad': ca['properties']['entidad'],
              'distrito_f': ca['properties']['distrito_f'],
              'municipio': ca['properties']['municipio'],
              'seccion': ca['properties']['seccion'],
              'casilla_list': ca['properties']['casilla']},
              **inegi['properties'])
              for ca in ca_fc for inegi in in_fc
             if shape(inegi['geometry']).contains(shape(ca['geometry'])) ]

df = pd.DataFrame(dict_list).drop_duplicates()

df.to_csv(os.path.join(txt_path, inegi_filename.split('/')[-1].split('.')[0] + '.txt'), index=False, sep='|')

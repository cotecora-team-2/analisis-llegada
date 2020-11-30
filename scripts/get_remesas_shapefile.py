#!/usr/bin/env python3.6

import numpy as np
import pandas as pd
from shapely.geometry import mapping, shape
import shapely.wkt
from fiona.crs import to_string
import fiona
import json
import os

remesas_path = '../datos'
casillas_path = '../datos/shapefiles/casillas_2018_shape'
remesas_filename = 'REMESAS0100012200.txt'
casillas_filename = 'casillas_2018.shp'
remesas_casillas_filename = 'remesas_casillas_2018.shp'
remesas_casillas_filename_csv = 'remesas_casillas_2018.txt'

with fiona.open(os.path.join(casillas_path, casillas_filename), encoding='utf-8') as src:
    crs_str = to_string(src.crs)
    ca_fc = list(src)
    schema = src.schema

remesas = pd.read_csv(os.path.join(remesas_path, remesas_filename), index_col=None, delimiter='|', skiprows=1)

remesas = remesas[['iD_ESTADO','ID_DISTRITO_FEDERAL','SECCION','ID_MUNICIPIO','TIPO_CASILLA','ID_CASILLA']]
remesas['casillaswid'] = remesas.apply(lambda x: str(x.TIPO_CASILLA) + str(x.ID_CASILLA), axis=1)

remesas = np.array(remesas[['iD_ESTADO','ID_DISTRITO_FEDERAL','SECCION','ID_MUNICIPIO','casillaswid']].drop_duplicates())

fc = [{'type': 'feature',
       'geometry_str': shape(ca['geometry']).wkt,
       'properties': {'entidad': ca['properties']['entidad'],
                      'nombre': ca['properties']['nombre'],
                      'distrito_f': ca['properties']['distrito_f'],
                      'distrito_l': ca['properties']['distrito_l'],
                      'municipio': ca['properties']['municipio'],
                      'nmunicipio': ca['properties']['nmunicipio'],
                      'seccion': ca['properties']['seccion'],
                      'localidad': ca['properties']['localidad'],
                      'nlocalidad': ca['properties']['nlocalidad'],
                      'manzana': ca['properties']['manzana'],
                      'casilla': ca['properties']['casilla'],
                      'domicilio': ca['properties']['domicilio'],
                      'ubicacion': ca['properties']['ubicacion'],
                      'referencia': ca['properties']['referencia'],
                      'cartografi': ca['properties']['cartografi'],
                      'cartogra_1': ca['properties']['cartogra_1'],
                      'google_x': ca['properties']['google_x'],
                      'google_y': ca['properties']['google_y']}}  for r in range(remesas.shape[0]) for ca in ca_fc
                                     if remesas[r][0] == ca['properties']['entidad'] and
                                        remesas[r][1] == ca['properties']['distrito_f'] and
                                        remesas[r][2] == ca['properties']['seccion'] and
                                        remesas[r][3] == ca['properties']['municipio'] and
                                        (remesas[r][4] in ca['properties']['casilla'].replace(" ", "").split(',') or
                                         remesas[r][4][0] in ca['properties']['casilla'].replace(" ", "").split(','))
                                         ]

fcdf = pd.DataFrame(fc)
fcdf['properties_str'] = fcdf.apply(lambda x: json.dumps(x.properties), axis=1)
fcdf = fcdf.drop(['properties'], axis=1).drop_duplicates()
fcdf['geometry'] = fcdf.apply(lambda x: mapping(shapely.wkt.loads(x.geometry_str)), axis=1)
fcdf['properties'] = fcdf.apply(lambda x: json.loads(x.properties_str.replace("'", "\"")),axis=1)
nfc = fcdf.drop(['properties_str','geometry_str'], axis=1).to_dict('r')

properties_list = []
for dict in nfc:
    properties_list.append(dict['properties'])

df = pd.DataFrame(properties_list)
#df = df.drop_duplicates()


with fiona.open(os.path.join(casillas_path, remesas_casillas_filename), 'w', schema=schema, crs=crs_str,
    driver='ESRI Shapefile') as dst:
    for row in nfc:
        dst.write(row)

df.to_csv(os.path.join(remesas_path, remesas_casillas_filename_csv),index=False, sep='|')

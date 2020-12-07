#!/usr/bin/env python3.6
"""
01. Obtiene un shapefile con las casillas de remesas a partir del total de casillas de 2018.
Para encontrar los puntos, tenian que coincidir los registros de remesas y los puntos del shapefile en 1) entidad o estado, 2) distrito_federal, 3) seccion y 
4) casilla.
Como en los shapefiles juntaban el tipo de casilla y el id de casilla en un solo campo i.e E1 o C1 hice una nueva columna en la tabla de remesas llamada 
'casillaswid' a partir de las columnas TIPO_CASILLA e ID_CASILLA. Otro problema es que para la casilla basica, como solo hay una, en lugar de poner B1 en el 
shapefile ponen solo B y ademas como en un mismo lugar, es decir un mismo punto del shapefile, puede haber mas de una casilla, el shapefile traia una lista 
de casillas i.e 'B, C1, C2'. Todo eso se considero para obtener el nuevo shapefile.

usage: ./get_remesas_shapefile.py
Input:
    REMESAS0100012200.txt: base de datos con remesas en ../datos
    casillas_2018.shp: Shapefile con los puntos del total de casillas de 2018 en ../datos/shapefiles/casillas_2018_shape
Output:
    remesas_casillas_2018.shp: Shapefile con los puntos de las casillas de la base de datos de remesas en ../datos/shapefiles/casillas_2018_shape
    remesas_casillas_2018.txt: tabla con las propiedades del shapefile remesas_casillas_2018.shp en ../datos
"""

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

# abre el shapefile del total de casillas y guarda en ca_fc las features de cada punto o casilla
with fiona.open(os.path.join(casillas_path, casillas_filename), encoding='utf-8') as src:
    crs_str = to_string(src.crs)
    ca_fc = list(src)
    schema = src.schema

# abre tabla de remesas
remesas = pd.read_csv(os.path.join(remesas_path, remesas_filename), index_col=None, delimiter='|', skiprows=1)

# selecciona las columnas que van a hacer match y las de tipo casilla e id de casilla para hacer nueva columna casillaswid que tambien va a hacer match con el shapefile
remesas = remesas[['iD_ESTADO','ID_DISTRITO_FEDERAL','SECCION','ID_MUNICIPIO','TIPO_CASILLA','ID_CASILLA']]
remesas['casillaswid'] = remesas.apply(lambda x: str(x.TIPO_CASILLA) + str(x.ID_CASILLA), axis=1)

# Como solo se seleccionaron algunas columnas, algunos renglones se repiten, por lo que se eliminan los repetidos
remesas = np.array(remesas[['iD_ESTADO','ID_DISTRITO_FEDERAL','SECCION','ID_MUNICIPIO','casillaswid']].drop_duplicates())

# Crea la features coleccion (fc). Cada feature contiene la geometria (Point, Polygon, etc) y sus propiedades. La crea a partir de dos bucles: uno de la tabla de remesas
# y el otro de la fc del shapefile con las casillas totales. En la condicion para agregar features a la nueva fc, la ultima condicion es un or, porque la casilla
# podria ser del tipo C1 o B. 
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

# pasos para crear un dataframe de la nueva fc para eliminar posibles puntos repetidos (muchas veces los shapefiles traen esos errores). Para poder eliminar
# los duplicados, todos los campos deben ser strings, por lo que los diccionarios y las geometrias se modificaron temporalemnte y una vez eliminados los
# duplicados se volvieron a modificar
fcdf = pd.DataFrame(fc)
fcdf['properties_str'] = fcdf.apply(lambda x: json.dumps(x.properties), axis=1)
fcdf = fcdf.drop(['properties'], axis=1).drop_duplicates()
fcdf['geometry'] = fcdf.apply(lambda x: mapping(shapely.wkt.loads(x.geometry_str)), axis=1)
fcdf['properties'] = fcdf.apply(lambda x: json.loads(x.properties_str.replace("'", "\"")),axis=1)
nfc = fcdf.drop(['properties_str','geometry_str'], axis=1).to_dict('r')

# crea lista con las propiedades de las features para crear un dataframe
properties_list = []
for dict in nfc:
    properties_list.append(dict['properties'])

# crea dataframe
df = pd.DataFrame(properties_list)

# guarda shapefile
with fiona.open(os.path.join(casillas_path, remesas_casillas_filename), 'w', schema=schema, crs=crs_str,
    driver='ESRI Shapefile') as dst:
    for row in nfc:
        dst.write(row)

# guarda propiedades en txt
df.to_csv(os.path.join(remesas_path, remesas_casillas_filename_csv),index=False, sep='|')

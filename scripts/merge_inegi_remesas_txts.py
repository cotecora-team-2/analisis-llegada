#!/usr/bin/env python3.6
"""
03. Concatena txt con variables de inegi y propiedades de puntos de casillas de remesas y eso lo junta a la tabla de remesas

usage: ./merge_inegi_remesas_txts.py
Input:
    REMESAS0100012200.txt: base de datos con remesas en ../datos
    *.txt: Todos los txt de cada estado con variables de inegi y propiedades de casillas en ../datos/inegi_vivienda_2010
Output:
    remesas_inegi_vivienda_2010.txt: tabla de remesas con propiedades de casillas y variables de inegi en ../datos
"""

import pandas as pd
import numpy as np
import glob
import os

path = '../datos'
remesas_filename = 'REMESAS0100012200.txt'
remesas_inegi_filename = 'remesas_inegi_vivienda_2010.txt'

# busca todos los txt con propiedades de casillas y variables de inegi de todos los estados y los concatena todos en un dataframe
txt_li = glob.glob(os.path.join(path, "inegi_vivienda_2010/*.txt"))
df_list = [pd.read_csv(txt, index_col=None, delimiter='|') for txt in txt_li ]
inegi_df = pd.concat(df_list)

# abre tabla de remesas y crea una columna 'CASILLA' del tipo E1 o C1 a partir de 'TIPO_CASILLA' e 'ID_CASILLA'
remesas = pd.read_csv(os.path.join(path, remesas_filename), index_col=None, delimiter='|', skiprows=1)
remesas['CASILLA'] = remesas.apply(lambda x: str(x.TIPO_CASILLA) + str(x.ID_CASILLA), axis=1)

# Crea columna 'casilla' a partir de 'casilla_list' que contiene strings del tipo 'B, C1, C2' que contiene una lista con cada una de las casillas del string y 
# a las casillas 'B' las renombra 'B1' quedando una lista del tipo ['B1', 'C1', 'C2']
inegi_df['casilla'] = inegi_df.apply(lambda x: ['B1' if f == 'B' else f for f in x.casilla_list.replace(" ", "").split(',')], axis=1)
inegi_df = inegi_df.drop(['casilla_list'],axis=1)

# desagrega las listas de casillas en la columna 'casilla' y crea un registro para cada casilla
lst_col = 'casilla'
inegi_df = pd.DataFrame({
          col:np.repeat(inegi_df[col].values, inegi_df[lst_col].str.len())
          for col in inegi_df.columns.difference([lst_col])
      }).assign(**{lst_col:np.concatenate(inegi_df[lst_col].values)})[inegi_df.columns.tolist()]

# junta el dataframe de remesas con el de propiedades de casillas y variables de inegi tomando como pivote 'iD_ESTADO','ID_DISTRITO_FEDERAL','ID_MUNICIPIO',
#'SECCION' y 'CASILLA'. Elimina el registro que tiene la clave geo 2700600400469 este registro está mal. Seguramente un punto de una casilla caia en la frontera
# entre dos estados y estan repetidas las propiedades de esa casilla en dos archivos txt con diferentes valores de las variables de inegi. 
merged_remesas_inegi = remesas.merge(inegi_df,how='left', left_on=['iD_ESTADO','ID_DISTRITO_FEDERAL','ID_MUNICIPIO','SECCION','CASILLA'],
                              right_on=['entidad','distrito_f','municipio','seccion','casilla'])
merged_remesas_inegi = merged_remesas_inegi[merged_remesas_inegi['CLAVEGEO'] != 2700600400469]

# se guarda la tabla completa
merged_remesas_inegi.to_csv(os.path.join(path, remesas_inegi_filename),index=False, sep='|')

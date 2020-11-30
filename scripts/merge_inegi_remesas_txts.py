#!/usr/bin/env python3.6

import pandas as pd
import numpy as np
import glob
import os

path = '/workspace/llevar/workspace/cotecora_2021/repos/analisis-llegada/datos'
remesas_filename = 'REMESAS0100012200.txt'
remesas_inegi_filename = 'remesas_inegi_vivienda_2010.txt'

txt_li = glob.glob(os.path.join(path, "inegi_vivienda_2010/*.txt"))
df_list = [pd.read_csv(txt, index_col=None, delimiter='|') for txt in txt_li ]
inegi_df = pd.concat(df_list)

remesas = pd.read_csv(os.path.join(path, remesas_filename), index_col=None, delimiter='|', skiprows=1)
remesas['CASILLA'] = remesas.apply(lambda x: str(x.TIPO_CASILLA) + str(x.ID_CASILLA), axis=1)

inegi_df['casilla'] = inegi_df.apply(lambda x: ['B1' if f == 'B' else f for f in x.casilla_list.replace(" ", "").split(',')], axis=1)
inegi_df = inegi_df.drop(['casilla_list'],axis=1)

lst_col = 'casilla'
inegi_df = pd.DataFrame({
          col:np.repeat(inegi_df[col].values, inegi_df[lst_col].str.len())
          for col in inegi_df.columns.difference([lst_col])
      }).assign(**{lst_col:np.concatenate(inegi_df[lst_col].values)})[inegi_df.columns.tolist()]

merged_remesas_inegi = remesas.merge(inegi_df,how='left', left_on=['iD_ESTADO','ID_DISTRITO_FEDERAL','ID_MUNICIPIO','SECCION','CASILLA'],
                              right_on=['entidad','distrito_f','municipio','seccion','casilla'])
merged_remesas_inegi = merged_remesas_inegi[merged_remesas_inegi['CLAVEGEO'] != 2700600400469]

merged_remesas_inegi.to_csv(os.path.join(path, remesas_inegi_filename),index=False, sep='|')



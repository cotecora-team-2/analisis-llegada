#!/usr/bin/env python3.6

import pandas as pd
import os

input_path = '../datos/vivienda_2005'
output_path = '../datos'
remesas_filename = 'REMESAS0100012200.txt'
filenames = ['{}vivienda_seccion.txt'.format(f) if f > 9 else '0{}vivienda_seccion.txt'.format(f) for f in range(1,33)]

csvs = []
for f in range(len(filenames)):
    csvs.append(pd.read_csv(os.path.join(input_path, filenames[f])))
df = pd.concat(csvs)
csvs = None

remesas = pd.read_csv(os.path.join(output_path, remesas_filename), index_col=None, delimiter='|', skiprows=1)

joined_df=remesas.merge(df, how='left', left_on=['iD_ESTADO','ID_DISTRITO_FEDERAL','SECCION'], right_on=['Entidad','Distrito','Seccion'])

joined_df.to_csv(os.path.join(output_path, 'REMESAS0100012200_.txt'),index=False)

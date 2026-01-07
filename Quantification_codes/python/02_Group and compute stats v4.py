# -*- coding: utf-8 -*-
"""
Created on Tue May 20 14:22:51 2025

@author: SuperServer
"""

# -*- coding: utf-8 -*-
"""
Created on Wed May 14 10:00:26 2025

@author: SuperServer

Script para agrupar resultados de FWHM y calcular estadísticas (promedio, SD, SEM,
razón lateral/axial (iso ratio), propagación de error) y generar tres hojas en Excel:
- "Raw Data": formato original con nombres, etiquetas de columnas y separación entre muestras
- "Summary": tabla resumen estadístico
- "Reordered": datos transpuestos: primero todas las mediciones laterales por muestra,
  Trabaja sobre un directorio que contiene una serie de carpetas, las cuales a su ves contienen los archivos .csv
  Está Hecho para todas las estructuras excepto núcleos, no realiza un cálculo fila por fila, si no un promedio de 
  cada columna que luego trabaja. El error se determina con la propagación del error.
  Funciona sobre varios directorios
"""
import os
import re
import numpy as np
import pandas as pd

# Función para ordenar modelos según sufijo (orden personalizable)
def ordenar_modelos_por_sufijo(lista_modelos):
    sufijos_orden = [
        'Microscopy', 'raw', 'CycleGAN', 'SNR_1', 'SNR_5', 'SNR_15', 'GT', 'iso2D',
        'RL20', 'RL10', 'RLF', 'RedLionFish20', 'RedLionFish10', 'CARE', 'SelfNet', 'SelfNetRL'
    ]
    def extraer_sufijo(nombre):
        partes = nombre.split('_')
        return partes[-1] if len(partes) > 1 else nombre
    def clave_orden(nombre):
        for i, s in enumerate(sufijos_orden):
            if nombre.endswith(s):
                return (i, nombre)
        return (len(sufijos_orden), nombre)
    return sorted(lista_modelos, key=clave_orden)

# ------------- CONFIGURACIÓN -------------
# Directorio raíz con subcarpetas a procesar
root_dir = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\BC_v2\snr_15"

# Carpeta común donde se guardarán los Excel resultantes
output_root = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\BC_v2"
# Crear carpeta de salida si no existe
os.makedirs(output_root, exist_ok=True)

# Recorrer cada subcarpeta
for sub in os.listdir(root_dir):
    input_folder = os.path.join(root_dir, sub)
    if not os.path.isdir(input_folder):
        continue  # Salta si no es carpeta

    print(f"Procesando: {input_folder}")

    # 1) Raw Data
    csv_files = [f for f in os.listdir(input_folder)
                 if f.startswith("resultados_fwhm_") and f.endswith(".csv")]
    modelos = [f.replace("resultados_fwhm_", "").replace(".csv", "") for f in csv_files]
    modelos_ordenados = ordenar_modelos_por_sufijo(modelos)

    dfs_raw = []
    for model_name in modelos_ordenados:
        df = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
        if df.columns[0] in ['Unnamed: 0', '']:
            df = df.iloc[:, 1:]
        title_row = pd.DataFrame([[model_name] + ['']*(df.shape[1]-1)], columns=df.columns)
        header_row = pd.DataFrame([df.columns.tolist()], columns=df.columns)
        block = pd.concat([title_row, header_row, df], ignore_index=True)
        dfs_raw.append(block)
        dfs_raw.append(pd.DataFrame([['']]*block.shape[0], columns=['']))
    raw_data = pd.concat(dfs_raw, axis=1)

    # 2) Summary con referencia
    mean_lat_orig = None
    mean_ax_orig = None
    ref_model = None
    for model_name in modelos_ordenados:
        if model_name.endswith('raw'):        #Nombre que usará de referencia
            df_ref = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
            if df_ref.columns[0] in ['Unnamed: 0', '']:
                df_ref = df_ref.iloc[:, 1:]
            mean_lat_orig = df_ref['FWHM_lateral'].mean()
            mean_ax_orig = df_ref['FWHM_axial'].mean()
            ref_model = model_name
            break

    summary_rows = []
    for model_name in modelos_ordenados:
        df = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
        if df.columns[0] in ['Unnamed: 0', '']:
            df = df.iloc[:, 1:]
        lat = df['FWHM_lateral'].dropna().values
        ax = df['FWHM_axial'].dropna().values
        n = len(lat)
        mean_lat = lat.mean(); sd_lat = lat.std(ddof=1); sem_lat = sd_lat / np.sqrt(n)
        mean_ax = ax.mean(); sd_ax = ax.std(ddof=1); sem_ax = sd_ax / np.sqrt(n)
        ratio = mean_lat/mean_ax if mean_ax else np.nan
        err_ratio = ratio * np.sqrt((sem_lat/mean_lat)**2 + (sem_ax/mean_ax)**2) if mean_lat>0 and mean_ax>0 else np.nan
        summary_rows.append({
            'model': model_name,
            'mean_lateral': mean_lat,
            'sem_lateral': sem_lat,
            'mean_axial': mean_ax,
            'sem_axial': sem_ax,
            'lat/orig_lat': mean_lat/mean_lat_orig if mean_lat_orig else np.nan,
            'ax/orig_lat': mean_ax/mean_lat_orig if mean_lat_orig else np.nan,    
            'lat/orig_ax': mean_lat/mean_ax_orig if mean_ax_orig else np.nan,
            'ax/orig_ax': mean_ax/mean_ax_orig if mean_ax_orig else np.nan,
            'lat/ax_ratio': ratio,
            'ratio_error': err_ratio,
            'sd_lateral': sd_lat,
            'sd_axial': sd_ax,
            'n': n,
        })
    summary_df = pd.DataFrame(summary_rows)

    # 3) Reordered
    reordered_rows = []
    lengths = []
    for model_name in modelos_ordenados:
        df = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
        if df.columns[0] in ['Unnamed: 0', '']:
            df = df.iloc[:, 1:]
        lat = df['FWHM_lateral'].dropna().tolist()
        ax = df['FWHM_axial'].dropna().tolist()
        reordered_rows.append({'model': model_name, 'type': 'lateral', 'values': lat})
        reordered_rows.append({'model': model_name, 'type': 'axial', 'values': ax})
        lengths.extend([len(lat), len(ax)])
    dmax = max(lengths) if lengths else 0
    data = []
    for row in reordered_rows:
        vals = row['values'] + ['']*(dmax-len(row['values']))
        data.append([f"{row['model']} ({row['type']})"] + vals)
    cols = ['sample'] + [f'M{i+1}' for i in range(dmax)]
    reordered_df = pd.DataFrame(data, columns=cols)

    # 4) Guardar Excel en carpeta común
    safe_ref = re.sub(r'[\/*?:"<>|]', '_', ref_model)
    # Limpiar también el nombre de subcarpeta
    safe_sub = re.sub(r'[\/*?:"<>|]', '_', sub)
    output_excel = os.path.join(output_root, f"Resultados_restoration_{safe_ref}.xlsx")
    with pd.ExcelWriter(output_excel, engine='xlsxwriter') as writer:
        raw_data.to_excel(writer, sheet_name='Raw Data', index=False, header=False)
        summary_df.to_excel(writer, sheet_name='Summary', index=False)
        reordered_df.to_excel(writer, sheet_name='Reordered', index=False)

    print(f"Generado: {output_excel}")





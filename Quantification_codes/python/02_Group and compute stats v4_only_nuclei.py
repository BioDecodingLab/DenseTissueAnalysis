'''
Script Hecho para entregar un directorio donde hay varias carpetas a procesar,
y las processa una a una.
Este es para núcleos (Realiza los cálculos fila por fila y luego promedia los resultados)
'''

import os
import re
import numpy as np
import pandas as pd

# Función para ordenar modelos según sufijo (orden personalizable)
def ordenar_modelos_por_sufijo(lista_modelos):
    sufijos_orden = [
        'Microscopy', 'raw', 'CycleGAN', 'SNR_1', 'SNR_5', 'SNR_15', 'GT', 'iso2D',
        'RL10', 'RLF10', 'RedLionFish10', 'CARE', 'SelfNet0', 'SelfNetRL'
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
root_dir = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\Nuclei_v2/snr 15"
# Carpeta común donde se guardarán los Excel resultantes
output_root = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\Nuclei_v2"
# Crear carpeta de salida si no existe
os.makedirs(output_root, exist_ok=True)

# Recorrer cada subcarpeta
for sub in os.listdir(root_dir):
    input_folder = os.path.join(root_dir, sub)
    if not os.path.isdir(input_folder):
        continue
    print(f"Procesando carpeta: {input_folder}")

    # Listar CSVs y ordenar modelos
    csv_files = [f for f in os.listdir(input_folder) if f.startswith("resultados_fwhm_") and f.endswith(".csv")]
    modelos = [f.replace("resultados_fwhm_", "").replace(".csv", "") for f in csv_files]
    modelos_ordenados = ordenar_modelos_por_sufijo(modelos)

    # 1) Raw Data
    dfs_raw = []
    for model_name in modelos_ordenados:
        df = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
        if df.columns[0] in ['Unnamed: 0', '']:
            df = df.iloc[:, 1:]
        title = pd.DataFrame([[model_name] + ['']*(df.shape[1]-1)], columns=df.columns)
        header = pd.DataFrame([df.columns.tolist()], columns=df.columns)
        block = pd.concat([title, header, df], ignore_index=True)
        dfs_raw.append(block)
        dfs_raw.append(pd.DataFrame([['']]*block.shape[0], columns=['']))
    raw_data = pd.concat(dfs_raw, axis=1)

    # 2) Summary valor-por-valor
    # Obtener valores de referencia (SNR_5)
    vals_lat_orig = None
    vals_ax_orig = None
    ref_model = None
    for model_name in modelos_ordenados:
        if model_name.endswith('raw'):
            df_ref = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
            if df_ref.columns[0] in ['Unnamed: 0', '']:
                df_ref = df_ref.iloc[:, 1:]
            vals_lat_orig = df_ref['FWHM_lateral'].dropna().values
            vals_ax_orig = df_ref['FWHM_axial'].dropna().values
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

        # Razones valor a valor
        lat_ax = [l/a for l, a in zip(lat, ax) if a != 0]
        lat_orig_lat = [l/o for l, o in zip(lat, vals_lat_orig) if o != 0]
        lat_orig_ax = [l/o for l, o in zip(lat, vals_ax_orig) if o != 0]
        orig_lat_ax = [o/a for o, a in zip(vals_lat_orig, ax) if a != 0]
        # NUEVA MÉTRICA: axial de cada modelo dividido por axial original
        ax_orig_ax = [a/o for a, o in zip(ax, vals_ax_orig) if o != 0]        
        ax_orig_lat = [a/o for a, o in zip(ax, vals_lat_orig) if o != 0]


        # Estadísticos de razones
        ratio_val = np.mean(lat_ax) if lat_ax else np.nan
        latol_val = np.mean(lat_orig_lat) if lat_orig_lat else np.nan
        latoa_val = np.mean(lat_orig_ax) if lat_orig_ax else np.nan
        origla_val = np.mean(orig_lat_ax) if orig_lat_ax else np.nan
        axora_val = np.mean(ax_orig_ax) if ax_orig_ax else np.nan
        axola_val = np.mean(ax_orig_lat) if ax_orig_lat else np.nan


        # Errores estándar de SEM
        sem_ratio = np.std(lat_ax, ddof=1)/np.sqrt(len(lat_ax)) if len(lat_ax)>1 else np.nan
        sem_origla = np.std(orig_lat_ax, ddof=1)/np.sqrt(len(orig_lat_ax)) if len(orig_lat_ax)>1 else np.nan
        sem_axora = np.std(ax_orig_ax, ddof=1)/np.sqrt(len(ax_orig_ax)) if len(ax_orig_ax)>1 else np.nan
        sem_axola = np.std(ax_orig_lat, ddof=1)/np.sqrt(len(ax_orig_lat)) if len(ax_orig_lat)>1 else np.nan
       
        # Promedios y SEM originales
        mean_lat = lat.mean(); sd_lat = lat.std(ddof=1); sem_lat = sd_lat/np.sqrt(n)
        mean_ax = ax.mean(); sd_ax = ax.std(ddof=1); sem_ax = sd_ax/np.sqrt(n)

        summary_rows.append({
            'model': model_name,
            'mean_lateral': mean_lat,
            'sem_lateral': sem_lat,
            'mean_axial': mean_ax,
            'sem_axial': sem_ax,
            'lat/orig_lat': latol_val,
            'ax/orig_lat': axola_val,
            'lat/orig_ax': latoa_val,
            'ax/orig_ax': axora_val, 
            'orig_lat/ax': origla_val,  
            'lat/ax_ratio': ratio_val, 
            'axola_error': sem_axola,        
            'origla_error': sem_origla,
            'axora_error': sem_axora,
            'ratio_error': sem_ratio,
            'sd_lateral': sd_lat,
            'sd_axial': sd_ax,
            'n': n
        })
    summary_df = pd.DataFrame(summary_rows)

    # 3) Reordered
    rows_reo = []
    lengths = []
    for model_name in modelos_ordenados:
        df = pd.read_csv(os.path.join(input_folder, f"resultados_fwhm_{model_name}.csv"))
        if df.columns[0] in ['Unnamed: 0', '']:
            df = df.iloc[:, 1:]
        lat = df['FWHM_lateral'].dropna().tolist()
        ax = df['FWHM_axial'].dropna().tolist()
        rows_reo.append({'model': model_name, 'type': 'lateral', 'values': lat})
        rows_reo.append({'model': model_name, 'type': 'axial', 'values': ax})
        lengths.extend([len(lat), len(ax)])
    dmax = max(lengths) if lengths else 0
    data = []
    for r in rows_reo:
        vals = r['values'] + ['']*(dmax-len(r['values']))
        data.append([f"{r['model']} ({r['type']})"] + vals)
    cols = ['sample'] + [f'M{i+1}' for i in range(dmax)]
    reordered_df = pd.DataFrame(data, columns=cols)

    # 4) Guardar Excel
    safe_sub = re.sub(r'[\\/*?:"<>|]', '_', sub)
    safe_ref = re.sub(r'[\\/*?:"<>|]', '_', ref_model)
    out_path = os.path.join(output_root, f"Resultados_restoration_{safe_ref}.xlsx")
    with pd.ExcelWriter(out_path, engine='xlsxwriter') as writer:
        raw_data.to_excel(writer, sheet_name='Raw Data', index=False, header=False)
        summary_df.to_excel(writer, sheet_name='Summary', index=False)
        reordered_df.to_excel(writer, sheet_name='Reordered', index=False)
    print(f"Archivo generado: {out_path}")

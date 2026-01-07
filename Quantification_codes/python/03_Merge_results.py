# -*- coding: utf-8 -*-
"""
Created on Wed Jun 11 09:53:12 2025

@author: SuperServer
"""
# Uner lso archivos excel que salen del paso anterior en uno solo

import os
import pandas as pd

# Carpeta de entrada y archivo de salida
input_folder = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\BC_v2"
output_file = os.path.join(input_folder, "resultados_unificados.xlsx")

summary_blocks = []
reordered_blocks = []
header_summary = None  # Guardará los nombres de columna

for file in sorted(os.listdir(input_folder)):
    if file.endswith(".xlsx") and file.startswith("Resultados_"):
        file_path = os.path.join(input_folder, file)
        try:
            xl = pd.ExcelFile(file_path, engine='openpyxl')

            # Leer hoja Summary
            if "Summary" in xl.sheet_names:
                df_summary = pd.read_excel(xl, sheet_name="Summary", engine='openpyxl')
                if header_summary is None:
                    header_summary = df_summary.columns.tolist()  # Guardar encabezado solo una vez
                df_summary.insert(0, "archivo_origen", file)
                summary_blocks.append(df_summary)

            # Leer hoja Reordered
            if "Reordered" in xl.sheet_names:
                df_reordered = pd.read_excel(xl, sheet_name="Reordered", engine='openpyxl')
                # Agrega una fila arriba con el nombre del archivo
                df_reordered.insert(0, "archivo_origen", file)
                reordered_blocks.append(df_reordered)

        except Exception as e:
            print(f"Error procesando {file}: {e}")

# Guardar solo si hay datos
if summary_blocks:
    summary_all = pd.concat(summary_blocks, ignore_index=True)
    reordered_all = pd.concat(reordered_blocks, ignore_index=True)

    with pd.ExcelWriter(output_file, engine='xlsxwriter') as writer:
        # Usamos header=True para escribir los nombres de columna en "Summary_All"
        summary_all.to_excel(writer, sheet_name='Summary_All', index=False, header=True)
        reordered_all.to_excel(writer, sheet_name='Reordered_All', index=False, header=True)

    print(f"Archivo generado: {output_file}")
else:
    print("No se encontraron archivos válidos para procesar.")


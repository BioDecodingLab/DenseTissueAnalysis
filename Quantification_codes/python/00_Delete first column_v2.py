# -*- coding: utf-8 -*-
"""
Created on Thu Mar 20 13:50:32 2025

@author: SuperServer
"""

#El macro que hice genera 3 columnas en el .csv
#Este script elimina la primera, crea una carpeta llamada procesados con los resultados de esto
#Lo hace sobre todas las carpetas en un directorio indicado
import pandas as pd
import os

# Carpeta exterior de entrada: contiene carpetas (por ejemplo, "100_5000", "83_10000", etc.)
input_folder = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Deconvolution test\Evaluation\Jupyter\BC_v2\FWHM"

# Recorrer únicamente las carpetas de primer nivel dentro de input_folder
for dir_name in os.listdir(input_folder):
    full_dir = os.path.join(input_folder, dir_name)
    
    # Se procesa solo si es una carpeta y no se llama "procesados"
    if os.path.isdir(full_dir) and dir_name != "procesados":
        for sub in ['Axial', 'Lateral']:
            input_path = os.path.join(full_dir, sub)
            
            # Solo se procede si la subcarpeta existe realmente
            if os.path.exists(input_path) and os.path.isdir(input_path):
                output_path = os.path.join(input_path, 'procesados')
                os.makedirs(output_path, exist_ok=True)
                
                # Procesar archivos CSV en la subcarpeta
                for file in os.listdir(input_path):
                    file_path = os.path.join(input_path, file)
                    
                    # Procesa solo archivos CSV y evita procesar los que estén ya en 'procesados'
                    if file.endswith(".csv") and not file_path.startswith(output_path):
                        df = pd.read_csv(file_path)
                        df = df.iloc[:, 1:]  # Eliminar la primera columna
                        df.to_csv(os.path.join(output_path, file), index=False)
                        print(f"Procesado: {dir_name}/{sub}/{file}")

print("Todos los archivos han sido procesados.")


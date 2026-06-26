# -*- coding: utf-8 -*-
"""
Created on Thu May 22 20:51:03 2025

@author: Jorge
"""
"Evaluation code for label images"


from glob import glob
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from tifffile import imread
from cc3d import connected_components
from stardist.matching import matching
from tqdm import tqdm
from skimage.segmentation import clear_border
from skimage.morphology import remove_small_objects

def normalize(img):
    return (img-img.min())/(img.max()-img.min())

def leer_imagenes(path):
    """Carga imágenes TIFF desde un directorio y las procesa como componentes conectados"""
    names = sorted(glob(os.path.join(path, "*.[tT][iI][fF]*")))
    if not names:
        raise ValueError(f"No se encontraron imágenes TIFF en {path}")
    print(f"Imágenes leídas desde {path}: {len(names)}")
    images = [clear_border(connected_components(imread(name))).astype(np.uint16) for name in names]
    images = [remove_small_objects(img, min_size=20) for img in images]
    # images = [connected_components(imread(name)) for name in names]
    names = [os.path.basename(name).split(".")[0] for name in names]
    return images, names

def evaluate_models(gt_images, preds_dict, output_dir=".", thresholds=np.linspace(0.5, 1.0, 11), fmt = ['o-', 's-', '^-', 'o-', 's-', '^-']):
    """
    Evalúa múltiples modelos de segmentación contra un ground truth y genera gráficos y resultados.
    
    Args:
        gt_images (list): Lista de imágenes ground truth
        preds_dict (dict): Diccionario {nombre_modelo: lista_de_imágenes_predichas}
        output_dir (str): Directorio para guardar resultados
        thresholds (array): Umbrales de IoU a evaluar
    
    Returns:
        tuple: (DataFrame con resultados, DataFrame con promedios, DataFrame con std)
    """
    # Crear directorio de salida si no existe
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. Evaluación con múltiples thresholds (para curvas AP)
    ap_results = {}
    std_results = {}
    
    for model_name, pred_images in preds_dict.items():
        print(f"\nEvaluando {model_name}...")
        matches = [
            [matching(gt_images[j], pred_images[j], thresh=i, report_matches=True) 
            for i in tqdm(thresholds, desc=f"Thresholds {model_name}")]
            for j in range(len(gt_images))
        ]
        ap_values = [[m.accuracy for m in match] for match in matches]
        ap_results[model_name] = np.mean(ap_values, axis=0)
        std_results[model_name] = np.std(ap_values, axis=0)
    
    # ---- después de terminar el for de modelos ----
    n_images = len(gt_images)  # número de muestras por threshold
    sem_results = {m: std_results[m] / np.sqrt(n_images) for m in preds_dict.keys()}

    # Graficar curvas AP
    plt.figure(figsize=(10, 6))
    for idx, model_name in enumerate(preds_dict.keys()):
        # plt.plot(
        #     thresholds, 
        #     ap_results[model_name], 
        #     '-o',
        #     label=model_name
        # )

        plt.errorbar(
            thresholds,
            ap_results[model_name],
            yerr=sem_results[model_name],
            fmt='-o',
            capsize=3,
            label=model_name,
        )
    # ajustar rango de ejes
    plt.ylim(-0.05, 1.05)
    plt.legend()
    plt.ylabel("AP")
    plt.xlabel(r"IoU threshold ($\tau$)")
    plt.title("Detection Scores")
    plt.savefig(os.path.join(output_dir, "detection_scores.svg"), dpi=300)
    plt.close()
    
    # 2. Evaluación con threshold fijo (0.5) para métricas detalladas
    thresh = 0.5
    detailed_results = []
    
    for model_name, pred_images in preds_dict.items():
        print(f"\nEvaluando detalladamente {model_name} con IoU={thresh}...")
        matches = [matching(gt_images[j], pred_images[j], thresh=thresh) 
                  for j in tqdm(range(len(gt_images)))]
        
        # Convertir a DataFrame
        keys = ['criterion', 'thresh', 'fp', 'tp', 'fn', 'precision', 'recall', 
                'accuracy', 'f1', 'n_true', 'n_pred', 'mean_true_score', 
                'mean_matched_score', 'panoptic_quality']
        df = pd.DataFrame([m._asdict() for m in matches], columns=keys)
        df.insert(0, 'Image', names)
        df.insert(0, 'Model', model_name)
        detailed_results.append(df)
    
    # Combinar todos los resultados
    df_results = pd.concat(detailed_results, ignore_index=True)
    
    # Formatear columnas
    float_cols = ['precision', 'recall', 'accuracy', 'f1', 'mean_true_score', 
                 'mean_matched_score', 'panoptic_quality']
    int_cols = ['fp', 'tp', 'fn', 'n_true', 'n_pred']
    
    df_results[float_cols] = df_results[float_cols].astype(float).round(4)
    df_results[int_cols] = df_results[int_cols].astype(int)
    
    # Renombrar columnas para mejor presentación
    new_names = {
        "fp": "FP", "tp": "TP", "fn": "FN",
        "precision": "Precision", "recall": "Recall",
        "accuracy": "Average Precision", "f1": "F1-Score",
        "n_true": "N True", "n_pred": "N Pred"
    }
    df_results = df_results.rename(columns=new_names)
    
    # Calcular porcentajes
    df_results['FP (%)'] = (df_results['FP'] / df_results['N Pred']).round(4)
    df_results['TP (%)'] = (df_results['TP'] / df_results['N Pred']).round(4)
    df_results['FN (%)'] = (df_results['FN'] / df_results['N True']).round(4)
    
    # Calcular promedios y std por modelo
    metrics = ['Precision', 'Recall', 'Average Precision', 'F1-Score']
    df_mean = df_results.groupby('Model', sort=False)[metrics].mean()
    df_std = df_results.groupby('Model', sort=False)[metrics].sem()
    
    # Guardar resultados
    df_results.to_csv(os.path.join(output_dir, "detailed_results.csv"), sep=";", index=False)
    df_mean.to_csv(os.path.join(output_dir, "mean_results.csv"), sep=";")
    df_std.to_csv(os.path.join(output_dir, "std_results.csv"), sep=";")
    
    # Generar gráficos comparativos
    plot_metrics_comparison(df_mean, df_std, output_dir)
    plot_violin_metrics(df_results, metrics, output_dir)  # Nueva función para gráfico de violines
    plot_boxplot_metrics(df_results, metrics, output_dir)  # Nueva función para boxplot
    
    return df_results, df_mean, df_std

def plot_metrics_comparison(df_mean, df_std, output_dir):
    """Genera gráfico de comparación de métricas entre modelos"""
    metrics = df_mean.columns
    x = np.arange(len(metrics))
    width = 0.8 / len(df_mean)  # Ajustar ancho según número de modelos
    
    plt.figure(figsize=(14, 6))
    
    for i, model in enumerate(df_mean.index):
        plt.bar(
            x + i * width,
            df_mean.loc[model],
            width,
            yerr=df_std.loc[model],
            label=model,
            capsize=5,
            alpha=0.8
        )
    
    plt.xticks(x + width*(len(df_mean)/2-0.5), metrics, rotation=45)
    plt.ylabel("Value")
    plt.title("Model Metrics Comparison (Mean ± STD)")
    plt.legend(title="Model")
    plt.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "metrics_comparison.svg"), dpi=300)
    plt.close()

def plot_violin_metrics(df_results, metrics, output_dir):
    """
    Genera gráfico de violines para visualizar distribución de métricas
    
    Args:
        df_results (DataFrame): DataFrame con todos los resultados
        metrics (list): Lista de métricas a visualizar
        output_dir (str): Directorio para guardar el gráfico
    """
    # Reestructurar los datos en formato "long" para Seaborn
    long_df = df_results.melt(
        id_vars=['Model'], 
        value_vars=metrics, 
        var_name='Métrica', 
        value_name='Valor'
    )
    
    # Crear el gráfico de violín
    plt.figure(figsize=(14, 8))
    sns.set_style("whitegrid")
    
    # Gráfico de violín
    sns.violinplot(
        data=long_df, 
        x='Métrica', 
        y='Valor', 
        hue='Model', 
        inner=None,
        palette="muted",
        split=False
    )
    
    # Puntos individuales
    sns.stripplot(
        data=long_df, 
        x='Métrica', 
        y='Valor', 
        hue='Model', 
        dodge=True, 
        jitter=True, 
        color='black', 
        size=4, 
        alpha=0.5, 
        linewidth=1, 
        legend=False
    )
    
    # Ajustes estéticos
    plt.title("Distribución de Métricas por Modelo")
    plt.xticks(rotation=45)
    plt.ylabel("Valor")
    plt.xlabel("Métricas")
    plt.grid(axis='y', alpha=0.3)
    
    # Mover la leyenda fuera del gráfico
    plt.legend(
        title="Modelos", 
        bbox_to_anchor=(1.05, 1), 
        loc='upper left', 
        borderaxespad=0.
    )
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "violin_metrics.svg"), dpi=300, bbox_inches='tight')
    plt.close()

import os
import seaborn as sns
import matplotlib.pyplot as plt

def plot_boxplot_metrics(df_results, metrics, output_dir):
    """
    Genera boxplots para visualizar la distribución de métricas
    
    Args:
        df_results (DataFrame): DataFrame con todos los resultados.
        metrics (list): Lista de métricas a visualizar.
        output_dir (str): Directorio para guardar el gráfico.
    """
    # Reestructurar a formato "long"
    long_df = df_results.melt(
        id_vars=['Model'],
        value_vars=metrics,
        var_name='Métrica',
        value_name='Valor'
    )

    plt.figure(figsize=(14, 8))
    sns.set_style("whitegrid")

    # Boxplot (sin outliers para que no choque visualmente con los puntos)
    ax = sns.boxplot(
        data=long_df,
        x='Métrica',
        y='Valor',
        hue='Model',
        palette='muted',
        showfliers=False,   # puedes poner True si quieres verlos
        linewidth=1.2
    )

    # Puntos individuales (no añadimos leyenda aquí para evitar duplicados)
    sns.stripplot(
        data=long_df,
        x='Métrica',
        y='Valor',
        hue='Model',
        dodge=True,
        jitter=True,
        color='black',
        size=4,
        alpha=0.5,
        linewidth=0.8,
        legend=False
    )

    # Estética
    plt.title("Distribución de Métricas por Modelo (Boxplot)")
    plt.xticks(rotation=45)
    plt.ylabel("Valor")
    plt.xlabel("Métricas")
    plt.grid(axis='y', alpha=0.3)

    # Mover la leyenda fuera (tomada del boxplot)
    handles, labels = ax.get_legend_handles_labels()
    # Quitar duplicados por seguridad manteniendo el orden
    seen = set()
    handles_unique, labels_unique = [], []
    for h, l in zip(handles, labels):
        if l not in seen:
            handles_unique.append(h)
            labels_unique.append(l)
            seen.add(l)

    plt.legend(
        handles_unique, labels_unique,
        title="Modelos",
        bbox_to_anchor=(1.05, 1),
        loc='upper left',
        borderaxespad=0.
    )

    plt.tight_layout()
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, "boxplot_metrics.svg"),
                dpi=300, bbox_inches='tight')
    plt.close()


# Ejemplo de uso:
if __name__ == "__main__":
# Definir datasets
    datasets = [
        "Nuclei"
    ]

    # Umbrales y formato de gráficas
    thresholds = np.linspace(0.5, 1.0, 11)
    fmt = ['o-', 's-', '^-', '*-', 'x-', 'd-', 'o-', 's-', '^-', '*-', 'x-', 'd-']

    # Definir los nombres de los modelos y sus carpetas relativas
    model_names = {
        "CycleGAN": "CycleGAN",
        "Microscopy": "Microscopy",
        "SNR_1": "SNR_1",
        "SNR_5": "SNR_5",    
        "SNR_15": "SNR_15",    
    }

    gt_name = "gt_IdT_v2"
    output_name = "results_gt_IdT_v2"

    # Recorrer todos los datasets
    for dataset_name in datasets:
        print(f"\n📊 Evaluando dataset: {dataset_name}")

        gt_dir = os.path.join(dataset_name, gt_name)
        output_dir = os.path.join(dataset_name, output_name)

        # Cargar ground truth
        gt, names = leer_imagenes(gt_dir)

        # Cargar predicciones de todos los modelos
        preds_dict = {}
        for model_name, rel_path in model_names.items():
            model_dir = os.path.join(dataset_name, rel_path)
            preds_dict[model_name] = leer_imagenes(model_dir)[0]

        # Evaluar
        results, mean_results, std_results = evaluate_models(
            gt, 
            preds_dict, 
            output_dir=output_dir,
            thresholds=thresholds,
            fmt=fmt
        )

        print("✔️ Resultados promedio:")
        print(mean_results)

    
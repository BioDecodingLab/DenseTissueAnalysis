#%%
# -*- coding: utf-8 -*-
"""
Created on Thu May 22 20:51:03 2025

@author: Jorge
"""
"Evaluation code for binary images"

from glob import glob
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from tifffile import imread
from cc3d import connected_components
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
    images = [imread(name).astype(np.uint16) for name in names]
    names = [os.path.basename(name).split(".")[0] for name in names]
    return images, names

def precision_score_(groundtruth_mask, pred_mask):
    intersect = np.sum(pred_mask*groundtruth_mask)
    total_pixel_pred = np.sum(pred_mask)
    precision = np.mean(intersect/total_pixel_pred)
    return round(precision, 3)

def recall_score_(groundtruth_mask, pred_mask):
    intersect = np.sum(pred_mask*groundtruth_mask)
    total_pixel_truth = np.sum(groundtruth_mask)
    recall = np.mean(intersect/total_pixel_truth)
    return round(recall, 3)

def f1_score_(groundtruth_mask, pred_mask):
    prec = precision_score_(groundtruth_mask, pred_mask)
    rec = recall_score_(groundtruth_mask, pred_mask)
    f1 = 2 * (prec * rec) / (prec + rec)
    return round(f1, 3)

def accuracy(groundtruth_mask, pred_mask):
    intersect = np.sum(pred_mask*groundtruth_mask)
    union = np.sum(pred_mask) + np.sum(groundtruth_mask) - intersect
    xor = np.sum(groundtruth_mask==pred_mask)
    acc = np.mean(xor/(union + xor - intersect))
    return round(acc, 3)

def dice_coef(groundtruth_mask, pred_mask):
    intersect = np.sum(pred_mask*groundtruth_mask)
    total_sum = np.sum(pred_mask) + np.sum(groundtruth_mask)
    dice = np.mean(2*intersect/total_sum)
    return round(dice, 3) #round up to 3 decimal places

def iou(groundtruth_mask, pred_mask):
    intersect = np.sum(pred_mask*groundtruth_mask)
    union = np.sum(pred_mask) + np.sum(groundtruth_mask) - intersect
    iou = np.mean(intersect/union)
    return round(iou, 3)

def to_binary(arr):
    # Binariza: cualquier valor > 0 cuenta como 1
    if arr.dtype != np.bool_:
        return (arr > 0).astype(np.uint8)
    return arr.astype(np.uint8)
import re
def safe_tag(tag: str) -> str:
    """Convierte 'GT/CycleGAN' en 'GT_CycleGAN', quita caracteres problemáticos."""
    tag = tag.replace(os.sep, "_").replace("/", "_")
    return re.sub(r"[^A-Za-z0-9._-]+", "_", tag)

# Ejemplo de uso:
# if __name__ == "__main__":
# Definir datasets
#%%

# ===============================================================
# FUNCIONES DE PLOTEO
# ===============================================================
def plot_metrics_comparison(df_mean, df_std, output_dir, file_name = "metrics_comparison.png"):
    """Genera gráfico de comparación de métricas entre modelos"""
    metrics = df_mean.columns
    x = np.arange(len(metrics))
    width = 0.8 / len(df_mean)

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
    plt.xticks(x + width * (len(df_mean) / 2 - 0.5), metrics, rotation=45)
    plt.ylabel("Valor")
    plt.title("Comparación de métricas (Media ± STD)")
    plt.legend(title="Modelos")
    plt.grid(axis="y", alpha=0.3)
    plt.tight_layout()

    # Guardar versiones .png y .svg
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, file_name), dpi=300)
    plt.close()

def plot_violin_metrics(df_results, metrics, output_dir, file_name = "violin_metrics.png"):
    """Gráfico de violín por modelo"""
    long_df = df_results.melt(
        id_vars=['Model'], value_vars=metrics,
        var_name='Métrica', value_name='Valor'
    )

    plt.figure(figsize=(14, 8))
    sns.set_style("whitegrid")

    sns.violinplot(
        data=long_df, x='Métrica', y='Valor', hue='Model',
        inner=None, palette="muted", split=False
    )
    sns.stripplot(
        data=long_df, x='Métrica', y='Valor', hue='Model',
        dodge=True, jitter=True, color='black', size=3.5,
        alpha=0.45, linewidth=0.8, legend=False
    )

    plt.title("Distribución de Métricas por Modelo (Violin)")
    plt.xticks(rotation=45)
    plt.ylabel("Valor")
    plt.xlabel("Métricas")
    plt.grid(axis='y', alpha=0.3)
    plt.legend(title="Modelos", bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()

    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, file_name), dpi=300, bbox_inches='tight')
    plt.close()

def plot_boxplot_metrics(df_results, metrics, output_dir, file_name = "boxplot_metrics.png"):
    """Gráfico boxplot de métricas por modelo"""
    long_df = df_results.melt(
        id_vars=['Model'], value_vars=metrics,
        var_name='Métrica', value_name='Valor'
    )

    plt.figure(figsize=(14, 8))
    sns.set_style("whitegrid")
    ax = sns.boxplot(
        data=long_df, x='Métrica', y='Valor', hue='Model',
        palette='muted', showfliers=False, linewidth=1.2
    )
    sns.stripplot(
        data=long_df, x='Métrica', y='Valor', hue='Model',
        dodge=True, jitter=True, color='black', size=3.5,
        alpha=0.45, linewidth=0.8, legend=False
    )

    plt.title("Distribución de Métricas por Modelo (Boxplot)")
    plt.xticks(rotation=45)
    plt.ylabel("Valor")
    plt.xlabel("Métricas")
    plt.grid(axis='y', alpha=0.3)
    handles, labels = ax.get_legend_handles_labels()
    seen = set()
    handles_unique, labels_unique = [], []
    for h, l in zip(handles, labels):
        if l not in seen:
            handles_unique.append(h)
            labels_unique.append(l)
            seen.add(l)
    plt.legend(handles_unique, labels_unique, title="Modelos", bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()

    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, file_name), dpi=300, bbox_inches='tight')
    plt.close()


# =============================
# Configuración
# =============================
datasets     = ["BC"]
network_names = ["Result_AttentionUnet3D", "Result_UNet3D"]
gt_names     = ["GT/CycleGAN", "GT/Microscopy"]   # debe corresponder 1:1 con datasets
model_subdirs = ["CycleGAN", "Microscopy", "SNR_1", "SNR_5", "SNR_15"]  # agrega más si quieres: ["CycleGAN","Microscopy","SNR_1",...]

# =============================
# Evaluación
# =============================
for dataset_name in datasets:
    print(f"\n📊 Evaluando dataset: {dataset_name}")

    # Cargar todas las GT una vez por cada tipo de GT
    gt_dict = {}
    for gt_name in gt_names:
        gt_dir = os.path.join(dataset_name, gt_name)
        try:
            gt_imgs, gt_names_list = leer_imagenes(gt_dir)
            gt_dict[gt_name] = (gt_imgs, gt_names_list)
            print(f"  → {len(gt_imgs)} GT leídas desde {gt_dir}")
        except Exception as e:
            print(f"❌ No se pudieron leer GT en {gt_dir}: {e}")
            gt_dict[gt_name] = ([], [])
    
    # Evaluar todas las combinaciones (network × GT)
    for network_name in network_names:
        for gt_name in gt_names:
            gt_imgs, names = gt_dict.get(gt_name, ([], []))
            if len(gt_imgs) == 0:
                print(f"⚠️  Saltando combinación {network_name} × {gt_name} (sin GT disponible)")
                continue

            print(f"\n🧠 Evaluando combinación: {network_name} × {gt_name}")
            gt_tag = safe_tag(gt_name)
            rows = []

            for model_subdir in model_subdirs:
                model_name = model_subdir
                model_dir  = os.path.join(dataset_name, network_name, model_subdir)

                try:
                    preds_list, _ = leer_imagenes(model_dir)
                except Exception as e:
                    print(f"⚠️  No se pudieron leer predicciones de {model_dir}: {e}")
                    continue

                n_gt, n_pred = len(gt_imgs), len(preds_list)
                if n_pred != n_gt:
                    print(f"⚠️  {model_name}: #preds ({n_pred}) ≠ #GT ({n_gt}). Se evaluará hasta el mínimo común.")
                K = min(n_gt, n_pred)

                for i in tqdm(range(K), desc=f"{model_name}", leave=False):
                    gt_img   = to_binary(gt_imgs[i])
                    pred_img = to_binary(preds_list[i])

                    if gt_img.shape != pred_img.shape:
                        print(f"  ⚠️  Omitida '{names[i]}' en {model_name}: shape GT {gt_img.shape} ≠ pred {pred_img.shape}")
                        continue

                    # Calcular métricas
                    p   = precision_score_(gt_img, pred_img)
                    r   = recall_score_(gt_img, pred_img)
                    f1  = f1_score_(gt_img, pred_img)
                    acc = accuracy(gt_img, pred_img)
                    dice = dice_coef(gt_img, pred_img)
                    iou_ = iou(gt_img, pred_img)

                    rows.append({
                        "Dataset": dataset_name,
                        "GT_Tag": gt_tag,
                        "Network": network_name,
                        "Model": model_name,
                        "Image": names[i],
                        "Precision": p,
                        "Recall": r,
                        "F1": f1,
                        "Accuracy": acc,
                        "Dice": dice,
                        "IoU": iou_
                    })

            # Crear carpeta de salida
            output_dir = os.path.join(dataset_name, network_name, "results")
            os.makedirs(output_dir, exist_ok=True)

            if len(rows) == 0:
                print(f"⚠️  No hay resultados para {dataset_name} / {network_name} / {gt_name}")
                continue

            # Guardar CSV detallado
            df_results = pd.DataFrame(rows)
            csv_detail = os.path.join(
                output_dir, f"{dataset_name}_{network_name}_{gt_tag}_metrics_detail.csv"
            )
            df_results.to_csv(csv_detail, index=False)
            print(f"✅ CSV detallado guardado en: {csv_detail}")

            # Calcular promedios y std por modelo
            metrics = ["Precision", "Recall", "F1", "Accuracy", "Dice", "IoU"]
            df_mean = df_results.groupby('Model', sort=False)[metrics].mean()
            df_sem = df_results.groupby('Model', sort=False)[metrics].sem()
            
            csv_summary = os.path.join(
                output_dir, f"{dataset_name}_{network_name}_{gt_tag}_metrics_summary.csv"
            )
            csv_sem = os.path.join(
                output_dir, f"{dataset_name}_{network_name}_{gt_tag}_metrics_sem.csv"
            )

            df_mean.to_csv(csv_summary, index=True)
            df_sem.to_csv(csv_sem, index=True)
            print(f"✅ CSV resumen guardado en: {csv_summary}")

            # =============================
            # GENERAR GRÁFICOS
            # =============================
           

            print("📈 Generando gráficos...")
            plot_metrics_comparison(df_mean, df_sem, output_dir, f"{dataset_name}_{network_name}_{gt_tag}_metrics_comparison.svg")
            plot_violin_metrics(df_results, ["Precision", "Recall", "F1", "Accuracy", "Dice", "IoU"], output_dir, f"{dataset_name}_{network_name}_{gt_tag}_violin.svg")
            plot_boxplot_metrics(df_results, ["Precision", "Recall", "F1", "Accuracy", "Dice", "IoU"], output_dir, f"{dataset_name}_{network_name}_{gt_tag}_boxplot.svg")
            print(f"✅ Gráficos guardados en: {output_dir}")

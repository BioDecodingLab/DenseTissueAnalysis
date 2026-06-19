# -*- coding: utf-8 -*-
"""
Created on Fri Jun 19 14:42:13 2026

@author: SuperServer
"""

from pathlib import Path
import re
import numpy as np
import pandas as pd
import tifffile as tiff

# =========================
# Editable variables
# =========================
GT_DIR = Path(r"/path/to/ground_truth_labels")
PRED_DIR = Path(r"/path/to/predicted_labels")
OUTPUT_XLSX = Path(r"/path/to/output/nuclei_counts.xlsx")

RECURSIVE_SEARCH = True

SAMPLES = {"Ch2", "Ch3", "G1", "G2"}
PRED_TYPES = {"Microscopy", "CycleGAN", "SNR_1", "SNR_5", "SNR_15"}
VALID_EXTENSIONS = {".tif", ".tiff", ".ome.tif", ".ome.tiff"}


# -------------------
# Helper functions
# -------------------
def base_name_without_suffixes(path: Path) -> str:
    name = path.name
    for suf in path.suffixes:
        name = name[: -len(suf)]
    return name


def load_label_image(path: Path) -> np.ndarray:
    return tiff.imread(str(path))


def count_objects_from_label_image(labels: np.ndarray) -> int:
    """
    Counts unique nonzero labels.
    Assumes 0 is background.
    """
    return int(np.count_nonzero(np.unique(labels)))


def count_predicted_objects_without_overlap(pred_labels: np.ndarray, gt_labels: np.ndarray) -> int:
    """
    Counts predicted objects that do not overlap any nonzero GT voxel.

    Faster approach:
    - get all predicted IDs that appear anywhere in GT-positive voxels
    - subtract from total predicted IDs
    """
    all_pred_ids = np.unique(pred_labels)
    all_pred_ids = all_pred_ids[all_pred_ids != 0]

    overlap_pred_ids = np.unique(pred_labels[gt_labels != 0])
    overlap_pred_ids = overlap_pred_ids[overlap_pred_ids != 0]

    # IDs that overlap GT
    n_overlap_objects = np.intersect1d(all_pred_ids, overlap_pred_ids, assume_unique=False).size

    return int(all_pred_ids.size - n_overlap_objects)


def parse_pred_name(base_name: str):
    """
    Expected:
      Nuclei_<sample>_<image_type>_cp_masks
    """
    pattern = r"^Nuclei_(Ch2|Ch3|G1|G2)_(Microscopy|CycleGAN|SNR_1|SNR_5|SNR_15)_cp_masks$"
    m = re.match(pattern, base_name)
    if not m:
        return None, None
    return m.group(1), m.group(2)


def get_gt_name(sample: str, image_type: str) -> str:
    if image_type == "Microscopy":
        return f"Nuclei_{sample}_Microscopy_Labels"
    return f"Nuclei_{sample}_IdT_Labels"


def build_file_map(folder: Path, recursive: bool = True):
    if recursive:
        files = [p for p in folder.rglob("*") if p.is_file()]
    else:
        files = [p for p in folder.iterdir() if p.is_file()]

    file_map = {}
    for p in files:
        lower_name = p.name.lower()
        if not any(lower_name.endswith(ext) for ext in VALID_EXTENSIONS):
            continue
        file_map[base_name_without_suffixes(p)] = p
    return file_map


# -------------------
# Main analysis
# -------------------
def main():
    gt_map = build_file_map(GT_DIR, recursive=RECURSIVE_SEARCH)
    pred_map = build_file_map(PRED_DIR, recursive=RECURSIVE_SEARCH)

    rows = []
    missing_gt = []
    shape_mismatch = []

    for pred_base, pred_path in sorted(pred_map.items()):
        sample, image_type = parse_pred_name(pred_base)

        if sample is None or sample not in SAMPLES or image_type not in PRED_TYPES:
            continue

        gt_base = get_gt_name(sample, image_type)
        gt_path = gt_map.get(gt_base)

        row = {
            "sample": sample,
            "image_type": image_type,
            "pred_file": pred_path.name,
            "gt_file": gt_path.name if gt_path is not None else None,
            "gt_name": gt_base,
            "pred_name": pred_base,
            "gt_count": np.nan,
            "pred_count": np.nan,
            "pred_without_overlap": np.nan,
            "pred_without_overlap_pct": np.nan,
            "count_difference_pred_minus_gt": np.nan,
            "count_difference_pct": np.nan,
            "status": "ok",
        }

        if gt_path is None:
            row["status"] = "missing_gt"
            missing_gt.append((pred_path.name, gt_base))
            rows.append(row)
            continue

        gt = load_label_image(gt_path)
        pred = load_label_image(pred_path)

        if gt.shape != pred.shape:
            row["status"] = "shape_mismatch"
            shape_mismatch.append((pred_path.name, gt_path.name, pred.shape, gt.shape))
            rows.append(row)
            continue

        gt_count = count_objects_from_label_image(gt)
        pred_count = count_objects_from_label_image(pred)
        pred_no_overlap = count_predicted_objects_without_overlap(pred, gt)

        row["gt_count"] = gt_count
        row["pred_count"] = pred_count
        row["pred_without_overlap"] = pred_no_overlap
        row["pred_without_overlap_pct"] = (pred_no_overlap / pred_count * 100.0) if pred_count > 0 else np.nan
        row["count_difference_pred_minus_gt"] = pred_count - gt_count
        row["count_difference_pct"] = ((pred_count - gt_count) / gt_count * 100.0) if gt_count > 0 else np.nan

        rows.append(row)

    results = pd.DataFrame(rows)
    if not results.empty:
        results = results[
            [
                "sample",
                "image_type",
                "pred_file",
                "gt_file",
                "gt_name",
                "pred_name",
                "gt_count",
                "pred_count",
                "pred_without_overlap",
                "pred_without_overlap_pct",
                "count_difference_pred_minus_gt",
                "count_difference_pct",
                "status",
            ]
        ].sort_values(["sample", "image_type"]).reset_index(drop=True)

    missing_df = pd.DataFrame(missing_gt, columns=["pred_file", "expected_gt_name"])
    shape_df = pd.DataFrame(shape_mismatch, columns=["pred_file", "gt_file", "pred_shape", "gt_shape"])

    OUTPUT_XLSX.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(OUTPUT_XLSX, engine="openpyxl") as writer:
        results.to_excel(writer, sheet_name="results", index=False)
        missing_df.to_excel(writer, sheet_name="missing_gt", index=False)
        shape_df.to_excel(writer, sheet_name="shape_mismatch", index=False)

    print(f"Done. Excel saved to: {OUTPUT_XLSX}")
    print(f"Rows written: {len(results)}")
    print(f"Missing GT files: {len(missing_df)}")
    print(f"Shape mismatches: {len(shape_df)}")


if __name__ == "__main__":
    main()
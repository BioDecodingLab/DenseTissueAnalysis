"""
------------------------------------------------------------
  OME-TIFF METADATA GENERATOR
  Segovia Lab - Liver Imaging Pipeline
-------------------------------------------------------------
Este es el bueno.
IMPORTANTE: Para que fiji lea correctamente el orden de los canales (mantenga el hyerstack)
la iamgen debe quedar en el orden CZYX.
Este script añade metadata a .tiff de una carpeta.
---------------------------------------------------------------
"""
import os
import re
from pathlib import Path

import numpy as np
import tifffile



# EDIT HERE: PATHS
# ---------------------------------------------------

INPUT_FOLDER = r"D:\Current_Segovia_lab\Deconvolution_Dilan\Dataset\Image_sets\CycleGAN_Simulated_images\Models\Sinusoids\Test_model_Sinusoids\Tested_images"
OUTPUT_FOLDER = INPUT_FOLDER

# =============================================================================
# EDIT HERE: PIXEL SIZE (micrometers)
# =============================================================================

PIXEL_SIZE_X_UM = 0.3
PIXEL_SIZE_Y_UM = 0.3
PIXEL_SIZE_Z_UM = 0.3

# =============================================================================
# EDIT HERE: MULTI-CHANNEL NAMES
# Order must match the channel order in the file after normalization to CZYX.
# =============================================================================

MULTI_CHANNEL_NAMES = [
    "Membranes",
    "BC",
    "Sinusoids",
    "Nuclei",
    #"Sinusoids_fill",
]

# =============================================================================
# EDIT HERE: OPTIONAL TEXT METADATA
# These values are stored in the OME Description field and MapAnnotation.
# Leave empty strings to skip them.
# =============================================================================

EXPERIMENTER_FIRST_NAME = ""
EXPERIMENTER_LAST_NAME = ""
INSTRUMENT_MODEL = ""

EXPERIMENT_DESCRIPTION_ENABLED = False

EXPERIMENT_DESCRIPTION = """
CycleGAN train intermediete result

"""

# Additional custom key/value pairs to embed in MapAnnotation.
# Edit this section freely.
CUSTOM_MAP_METADATA = {
    # "Project": "My project",
    # "Batch": "Batch_01",
    # "Author": "Dilan",
}


# =============================================================================
# INTERNAL CONSTANTS
# =============================================================================

ORIENTATION_MAP = {
    "Ch2": "CV-PV",
    "Ch3": "CV-PV",
    "G1":  "PV-CV",
    "G2":  "CV-PV",
}

SINGLE_CHANNEL_STRUCTURES = ["Membranes", "BC", "Sinusoids", "Nuclei"]

IMAGE_TYPE_KEYWORDS = {
    "CycleGAN":         "Simulated_CycleGAN",
    "Conventional":     "Simulated_conventional",
    "Microscopy":             "Microscopy",
    "Control":                "Microscopy",
    "control":                "Microscopy",
    "Idealized":                "Idealized_Mask",
    "IdT":                          "Idealized_Mask",
    "segmented":                "Microscopy_segmentation_mask",
    "PSF":                      "Experimental_PSF",
    "SNR":                      "Simulated_conventional",
  #  "crop":                 "Simulated_CycleGAN",
  # "crop_GT":                       "Microscopy",
}

OME_NS = "http://www.openmicroscopy.org/Schemas/OME/2016-06"


# =============================================================================
# HELPERS
# =============================================================================

def clean_text(text: str) -> str:
    """Return a compact string safe to place in XML text nodes."""
    return text.encode("ascii", errors="ignore").decode("ascii").strip()


def detect_sample(filename: str) -> str:
    """Return sample code (Ch2 / Ch3 / G1 / G2) from filename, or 'Unknown'."""
    
    for code in ORIENTATION_MAP:
        if re.search(r'(?<![A-Za-z])' + re.escape(code) + r'(?![A-Za-z0-9])',
                     filename, re.IGNORECASE):
            return code
    return "Unknown"


def detect_image_type(filename: str) -> str:
    """Return physical origin of the image (Microscopy / Simulated_*)."""
    for key in sorted(IMAGE_TYPE_KEYWORDS, key=len, reverse=True):
        if key.lower() in filename.lower():
            return IMAGE_TYPE_KEYWORDS[key]
    return "Unknown"


def detect_single_channel_structure(filename: str) -> str:
    """Return biological structure label for single-channel images."""
    for structure in SINGLE_CHANNEL_STRUCTURES:
        if structure.lower() in filename.lower():
            return structure
    return "Unknown"


def load_tiff_array(filepath: str):
    """
    Load a TIFF and return:
      - array
      - axes reported by tifffile.series[0].axes if available
    """
    with tifffile.TiffFile(filepath) as tif:
        arr = tif.asarray()
        axes = tif.series[0].axes if tif.series else ""

    if arr.ndim == 2:
        arr = arr[np.newaxis, ...]  # YX -> ZYX

    return arr, axes


def normalize_array(arr: np.ndarray, axes: str):
    """
    Normalize image data to:
      - single-channel: (Z, Y, X)
      - multi-channel:  (C, Z, Y, X)

    Returns:
      data, is_single_channel, n_channels, size_z, size_y, size_x
    """
    arr = np.asarray(arr)
    axes = (axes or "").upper()

    # Single-channel z-stack
    if arr.ndim == 3:
        size_z, size_y, size_x = arr.shape
        return arr, True, 1, size_z, size_y, size_x

    # Multi-channel z-stack
    if arr.ndim != 4:
        raise ValueError(f"Unexpected array shape: {arr.shape}")

    # Convert known axis orders to CZYX
    if axes == "ZCYX":
        data = np.moveaxis(arr, 1, 0)  # ZCYX -> CZYX
    elif axes == "CZYX":
        data = arr
    elif axes == "ZYXC":
        data = np.moveaxis(arr, -1, 0)  # ZYXC -> CZYX
    else:
        # Heuristic fallback
        if arr.shape[0] <= 16:
            data = arr  # assume CZYX
        elif arr.shape[1] <= 16:
            data = np.moveaxis(arr, 1, 0)  # assume ZCYX
        elif arr.shape[-1] <= 16:
            data = np.moveaxis(arr, -1, 0)  # assume ZYXC
        else:
            data = np.moveaxis(arr, 1, 0)

    if data.ndim != 4:
        raise ValueError(f"Could not normalize multichannel image: {arr.shape}")

    n_channels, size_z, size_y, size_x = data.shape
    return data, False, n_channels, size_z, size_y, size_x


def get_channel_names(is_single_channel: bool, n_channels: int, filename: str):
    if is_single_channel:
        structure = detect_single_channel_structure(filename)
        return [structure], structure

    names = list(MULTI_CHANNEL_NAMES[:n_channels])
    if len(names) < n_channels:
        names.extend([f"Channel_{i}" for i in range(len(names), n_channels)])
    return names, "N/A"


def build_description(
    sample: str,
    image_type: str,
    orientation: str,
    is_single_channel: bool,
    structure: str,
    channel_names,
    size_z: int,
    size_y: int,
    size_x: int,
    n_channels: int,
):
    lines = [
        f"Sample: {sample}",
        f"Orientation: {orientation}",
        f"Image_Type: {image_type}",
        f"Channel_Type: {'Single_Channel' if is_single_channel else 'Multi_Channel'}",
        f"N_Channels: {n_channels}",
        f"Size_X_px: {size_x}",
        f"Size_Y_px: {size_y}",
        f"Size_Z_px: {size_z}",
        f"Pixel_Size_X_um: {PIXEL_SIZE_X_UM}",
        f"Pixel_Size_Y_um: {PIXEL_SIZE_Y_UM}",
        f"Pixel_Size_Z_um: {PIXEL_SIZE_Z_UM}",
    ]

    if is_single_channel:
        lines.append(f"Structure: {structure}")
    else:
        for i, name in enumerate(channel_names):
            lines.append(f"Channel_{i}_Name: {name}")

    if EXPERIMENT_DESCRIPTION_ENABLED:
        extra = clean_text(EXPERIMENT_DESCRIPTION)
        if extra:
            lines.append("")
            lines.append("Experiment_Description:")
            lines.append(extra)

    return "\n".join(lines)


def build_ome_metadata(
    description_text: str,
    is_single_channel: bool,
    channel_names,
):
    """
    Metadata dictionary understood by tifffile when ome=True.

    Important parts:
      - axes: CZYX for multichannel, ZYX for single-channel
      - Channel names are written into OME-XML
      - Physical sizes are written into OME-XML
      - Description and MapAnnotation hold extra custom information
    """
    md = {
        "axes": "ZYX" if is_single_channel else "CZYX",
        "PhysicalSizeX": float(PIXEL_SIZE_X_UM),
        "PhysicalSizeY": float(PIXEL_SIZE_Y_UM),
        "PhysicalSizeZ": float(PIXEL_SIZE_Z_UM),
        "PhysicalSizeXUnit": "µm",
        "PhysicalSizeYUnit": "µm",
        "PhysicalSizeZUnit": "µm",
    }

    if description_text:
        md["Description"] = description_text

    if not is_single_channel:
        md["Channel"] = {"Name": list(channel_names)}

    # Keep extra metadata in a structured form.
    # This is optional but useful for the reviewer/requested metadata.
    map_meta = {
        "Namespace": "openmicroscopy.org/mapr/generic",
        "Sample": "",
        "Orientation": "",
        "Image_Type": "",
        "Channel_Type": "Single_Channel" if is_single_channel else "Multi_Channel",
        "Structure": "",
        "N_Channels": "",
        "Pixel_Size_X_um": str(PIXEL_SIZE_X_UM),
        "Pixel_Size_Y_um": str(PIXEL_SIZE_Y_UM),
        "Pixel_Size_Z_um": str(PIXEL_SIZE_Z_UM),
    }

    # Merge in user-editable custom keys
    for key, value in CUSTOM_MAP_METADATA.items():
        map_meta[key] = str(value)

    md["MapAnnotation"] = map_meta
    return md


# =============================================================================
# MAIN
# =============================================================================

def process_folder():
    os.makedirs(OUTPUT_FOLDER, exist_ok=True)

    tiff_files = [
        f for f in os.listdir(INPUT_FOLDER)
        if f.lower().endswith((".tif", ".tiff"))
    ]

    if not tiff_files:
        print("No TIFF files found in the input folder.")
        return

    print(f"\n{'='*60}")
    print("  OME-TIFF Metadata Writer")
    print(f"  Found {len(tiff_files)} TIFF file(s) to process")
    print(f"{'='*60}\n")

    for fname in sorted(tiff_files):
        fpath = os.path.join(INPUT_FOLDER, fname)
        print(f"Processing: {fname}")

        # 1) Load image
        try:
            arr, axes = load_tiff_array(fpath)
        except Exception as e:
            print(f"  [ERROR] Could not read file: {e}\n")
            continue

        # 2) Detect metadata from filename
        sample = detect_sample(fname)
        image_type = detect_image_type(fname)
        
        if "crop" in fname.lower():
            orientation = "Not present"
        else:
            orientation = ORIENTATION_MAP.get(sample, "Unknown")

        # 3) Normalize
        try:
            data, is_single_channel, n_channels, size_z, size_y, size_x = normalize_array(arr, axes)
        except Exception as e:
            print(f"  [ERROR] Could not normalize array: {e}\n")
            continue

        # 4) Channel names
        if is_single_channel:
            structure = detect_single_channel_structure(fname)
            channel_names = [structure]
            ch_type_label = "Single-channel"
        else:
            channel_names, _ = get_channel_names(False, n_channels, fname)
            structure = "N/A"
            ch_type_label = "Multi-channel"

        # 5) Description / extra metadata
        description_text = build_description(
            sample=sample,
            image_type=image_type,
            orientation=orientation,
            is_single_channel=is_single_channel,
            structure=structure,
            channel_names=channel_names,
            size_z=size_z,
            size_y=size_y,
            size_x=size_x,
            n_channels=n_channels,
        )

        ome_metadata = build_ome_metadata(
            description_text=description_text,
            is_single_channel=is_single_channel,
            channel_names=channel_names,
        )

        # Fill the annotation values that depend on the current image
        ome_metadata["MapAnnotation"]["Sample"] = sample
        ome_metadata["MapAnnotation"]["Orientation"] = orientation
        ome_metadata["MapAnnotation"]["Image_Type"] = image_type
        ome_metadata["MapAnnotation"]["N_Channels"] = str(n_channels)
        if is_single_channel:
            ome_metadata["MapAnnotation"]["Structure"] = structure

        # 6) Report
        print(f"  Sample         : {sample}")
        print(f"  Orientation    : {orientation}")
        print(f"  Image type     : {image_type}")
        print(f"  Channel type   : {ch_type_label}  ({n_channels} channel(s))")
        print(f"  Channel names  : {channel_names}")
        if is_single_channel:
            print(f"  Structure      : {structure}")
        print(f"  Input axes     : {axes}")
        print(f"  Output axes    : {ome_metadata['axes']}")
        print(f"  Data shape     : {data.shape}")
        print(f"  Dimensions (px): X={size_x}  Y={size_y}  Z={size_z}")
        print(f"  Dimensions (um): X={round(size_x * PIXEL_SIZE_X_UM, 2)}"
              f"  Y={round(size_y * PIXEL_SIZE_Y_UM, 2)}"
              f"  Z={round(size_z * PIXEL_SIZE_Z_UM, 2)}")

        # 7) Write OME-TIFF
        out_name = Path(fname).stem + ".tif"
        out_path = os.path.join(OUTPUT_FOLDER, out_name)

        try:
            tifffile.imwrite(
                out_path,
                data,
                ome=True,
                bigtiff=True,
                photometric="minisblack",
                metadata=ome_metadata,
            )
            print(f"  [OK] Saved → {out_path}\n")

        except Exception as e:
            print(f"  [ERROR] Could not write OME-TIFF: {e}\n")

    print(f"{'='*60}")
    print("  All files processed.")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    process_folder()

#!/usr/bin/env python3
"""
3D Confocal Restoration Metrics Evaluator (Flexible Methods, Dual-Scope)
------------------------------------------------------------------------
- Supports arbitrary methods via --methods or --auto_methods
- Computes metrics BOTH on the WHOLE VOLUME ("global") and, if a mask is provided, INSIDE THE MASK ("mask")
- Exports a tidy CSV with a 'scope' column and creates per-metric boxplots for each scope

Folder structure (each subfolder = one image):
    image_name_GT.tif
    image_name_mask.tif              [optional]
    image_name_raw.tif               [optional baseline if --include_raw]
    image_name_<METHOD>.tif          (RL, RedLionFish, SelfNet0, SelfNetRL, Other1, ...)

Metrics (vs GT):
  - MSE, MAE, PSNR
  - SSIM (3D) with explicit data_range
  - Pearson Correlation Coefficient (PCC)
  - LPIPS (optional; averaged over sampled slices) -> requires `pip install lpips torch`
  - FSC resolution estimate (cycles/voxel) at threshold 0.143 and its reciprocal (voxels per cycle)

Per-volume metric (not vs GT):
  - Spectral Isotropy Index (SII): angular CV of power per frequency shell (lower = more isotropic)

Outputs:
  - metrics_summary.csv
  - boxplot_<METRIC>_<SCOPE>.eps  where SCOPE ∈ {global, mask} (mask plots only if any masks exist)

Usage examples
--------------
Explicit methods:
python confocal_metrics_eval.py \
  --src_folder /path/to/src_folder \
  --out_dir /path/to/out \
  --methods RL,RedLionFish,SelfNet0,SelfNetRL,Other1 \
  --include_raw

Auto-discover methods per subfolder:
python confocal_metrics_eval.py \
  --src_folder /path/to/src_folder \
  --out_dir /path/to/out \
  --auto_methods \
  --include_raw


Notes
-----
- All volumes are assumed already aligned & on a common isotropic grid.
- Intensities are normalized to the GT intensity range within the mask (min-max -> [0,1]).
- Metrics are computed INSIDE the provided mask. If no mask exists, the full volume is used.
- SSIM is attempted volume-wise; if unavailable in your skimage version, it falls
  back to slice-wise averaging.
- FSC uses a Hann window * mask in the spatial domain to reduce edge artifacts.
- LPIPS is optional; the script will skip it gracefully if lpips/torch are not installed.
- Check lines 530 and 531 for 3D or 2D model evaluation
  
"""

import argparse
import os
import sys
import math
import warnings
from glob import glob

import numpy as np
import pandas as pd
import tifffile as tiff
from scipy import fft as spfft

from matplotlib import pyplot as plt

from skimage.metrics import structural_similarity as ssim_skimage
from skimage.metrics import peak_signal_noise_ratio as sk_psnr


# -----------------------------
# Helpers: I/O and normalization
# -----------------------------
def read_tiff(path):
    if not os.path.exists(path):
        raise FileNotFoundError(path)
    vol = tiff.imread(path)
    # Convert to float32 for safety
    if np.issubdtype(vol.dtype, np.floating):
        return vol.astype(np.float32, copy=False)
    else:
        return vol.astype(np.float32)


#def bounding_box_from_mask(mask):
#    coords = np.argwhere(mask)
#    if coords.size == 0:
#        return (slice(0, mask.shape[0]), slice(0, mask.shape[1]), slice(0, mask.shape[2]))
#    zmin, ymin, xmin = coords.min(axis=0)
#    zmax, ymax, xmax = coords.max(axis=0) + 1
#    return (slice(zmin, zmax), slice(ymin, ymax), slice(xmin, xmax))

def bounding_box_from_mask(mask):
    """Return slices spanning the full dimensions of the mask."""
    return tuple(slice(0, dim) for dim in mask.shape)


def normalize_to_gt_range(vol, gt, mask=None, eps=1e-8):
    """Min-max normalizes 'vol' to the intensity range of 'gt' (inside mask if provided), then maps both to [0,1]."""
    if mask is not None:
        gt_vals = gt[mask > 0]
        v_vals = vol[mask > 0]
        if gt_vals.size == 0:
            gt_min, gt_max = float(gt.min()), float(gt.max())
            v_min, v_max = float(vol.min()), float(vol.max())
        else:
            gt_min, gt_max = float(np.percentile(gt_vals, 0.0)), float(np.percentile(gt_vals, 100.0))
            v_min, v_max = float(np.percentile(v_vals, 0.0)), float(np.percentile(v_vals, 100.0))
    else:
        gt_min, gt_max = float(gt.min()), float(gt.max())
        v_min, v_max = float(vol.min()), float(vol.max())

    # Map vol to roughly GT range
    data_range = max(gt_max - gt_min, eps)
    vol_scaled = (vol - v_min) / max(v_max - v_min, eps)
    vol_scaled = vol_scaled * data_range + gt_min

    # Normalize both to [0,1] using GT range (so PSNR/SSIM data_range = 1.0)
    vol01 = (vol_scaled - gt_min) / data_range
    gt01 = (gt - gt_min) / data_range
    return vol01.astype(np.float32), gt01.astype(np.float32), 1.0  # data_range=1.0


# -----------------------------
# Metrics: core fidelity metrics
# -----------------------------
def mse(gt, x, mask=None):
    if mask is not None:
        m = mask > 0
        if m.sum() == 0:
            return float(np.mean((gt - x) ** 2))
        return float(np.mean((gt[m] - x[m]) ** 2))
    return float(np.mean((gt - x) ** 2))


def mae(gt, x, mask=None):
    if mask is not None:
        m = mask > 0
        if m.sum() == 0:
            return float(np.mean(np.abs(gt - x)))
        return float(np.mean(np.abs(gt[m] - x[m])))
    return float(np.mean(np.abs(gt - x)))


def psnr_from_mse(mse_value, data_range=1.0):
    if mse_value <= 0:
        return float("inf")
    return 10.0 * math.log10((data_range ** 2) / mse_value)


def psnr_metric(gt, x, mask=None, data_range=1.0):
    
    #PSNR using skimage for the global case (no mask), and
    #MSE->PSNR for the masked case (skimage's PSNR has no mask support).

    if mask is None:
        try:
            return float(sk_psnr(gt, x, data_range=data_range))
        except Exception:
            # Fallback in unlikely case sk_psnr fails
            return psnr_from_mse(mse(gt, x, None), data_range=data_range)
    else:
        # Compute PSNR only over masked voxels via masked MSE
        return psnr_from_mse(mse(gt, x, mask), data_range=data_range)


def pearson_corr(gt, x, mask=None, eps=1e-12):
    if mask is not None:
        m = mask > 0
        if m.sum() == 0:
            g = gt.ravel()
            y = x.ravel()
        else:
            g = gt[m].ravel()
            y = x[m].ravel()
    else:
        g = gt.ravel()
        y = x.ravel()
    g = g - g.mean()
    y = y - y.mean()
    num = float(np.dot(g, y))
    den = float(np.sqrt((g ** 2).sum() * (y ** 2).sum()) + eps)
    return num / den


def ssim3d(gt, x, mask=None, data_range=1.0):
    """
    Try proper 3D SSIM via skimage if supported; otherwise average 2D SSIM across slices.
    If a mask is provided, crop to the mask bounding box to reduce background bias.
    """
    G, X = gt, x
    if mask is not None:
        bb = bounding_box_from_mask(mask)
        G = gt[bb]
        X = x[bb]

    try:
        # skimage >=0.19 supports ND arrays with channel_axis=None
        return float(ssim_skimage(G, X, data_range=data_range, channel_axis=None))
    except TypeError:
        # Fallback: average axial slices
        vals = []
        for k in range(G.shape[0]):
            vals.append(ssim_skimage(G[k], X[k], data_range=data_range))
        return float(np.mean(vals))


# -----------------------------
# Optional: LPIPS (2D perceptual) averaged over slices
# -----------------------------
from tqdm import tqdm
def lpips_slicewise(gt, x, mask=None, slice_samples=16, device='cpu'):
    try:
        import torch
        import lpips
        from tqdm import tqdm
    except Exception as e:
        warnings.warn(f"LPIPS skipped (missing torch/lpips): {e}")
        return np.nan

    G, X, M = gt, x, mask
    Z = G.shape[0]
    step = max(1, Z // slice_samples)
    slcs = list(range(0, Z, step))
    if len(slcs) > slice_samples:  # trim to exact count
        slcs = slcs[:slice_samples]

    loss_fn = lpips.LPIPS(net='alex').to(device).eval()
    vals = []

    # add tqdm progress bar
    for k in tqdm(slcs, desc="Computing LPIPS", unit="slice"):
        g2d = G[k]
        x2d = X[k]
        if M is not None:
            m2d = (M[k] > 0).astype(np.float32)
            # Neutralize outside-mask areas by copying GT
            x2d = m2d * x2d + (1 - m2d) * g2d
            g2d = g2d  # unchanged

        # LPIPS expects 3-ch images in [-1, 1]
        g3 = np.stack([g2d, g2d, g2d], axis=0)  # 3xHxW
        x3 = np.stack([x2d, x2d, x2d], axis=0)
        try:
            g3 = torch.from_numpy(g3[None, ...]).to(device=device, dtype=torch.float32)  # 1x3xHxW
            x3 = torch.from_numpy(x3[None, ...]).to(device=device, dtype=torch.float32)
            g3 = g3 * 2.0 - 1.0
            x3 = x3 * 2.0 - 1.0
            with torch.no_grad():
                d = loss_fn.forward(g3, x3)
            vals.append(float(d.item()))
        except Exception:
            return np.nan

    return float(np.mean(vals)) if len(vals) > 0 else np.nan


# -----------------------------
# Frequency-domain metrics: FSC & SII
# -----------------------------
def hann3d(shape):
    """3D separable Hann window."""
    def hann_1d(n):
        if n <= 1:
            return np.ones((n,), dtype=np.float32)
        i = np.arange(n, dtype=np.float32)
        return 0.5 - 0.5 * np.cos(2.0 * np.pi * i / (n - 1))
    wz = hann_1d(shape[0])[:, None, None]
    wy = hann_1d(shape[1])[None, :, None]
    wx = hann_1d(shape[2])[None, None, :]
    return (wz * wy * wx).astype(np.float32)


def fsc_resolution(gt, x, mask=None, threshold=0.143, min_shell=1, max_shell=None, return_curve=False):
    """
    Fourier Shell Correlation between x and gt (both already normalized to [0,1]).
    Returns the resolution frequency (cycles/voxel) at which FSC first falls below `threshold`.
    If it never crosses, returns np.nan (and you can inspect the curve).
    """
    G = gt.copy()
    X = x.copy()

    # Apply combined mask * Hann window to reduce boundary effects
    win = hann3d(G.shape)
    if mask is not None and mask.shape == G.shape:
        win = win * (mask > 0).astype(np.float32)

    G = G * win
    X = X * win

    # FFT volumes
    Fg = spfft.fftn(G)
    Fx = spfft.fftn(X)

    # Shift to center
    Fg = spfft.fftshift(Fg)
    Fx = spfft.fftshift(Fx)

    # Build radius grid
    Z, Y, Xdim = G.shape
    cz, cy, cx = (Z // 2, Y // 2, Xdim // 2)
    zz, yy, xx = np.ogrid[:Z, :Y, :Xdim]
    rz = (zz - cz).astype(np.float32)
    ry = (yy - cy).astype(np.float32)
    rx = (xx - cx).astype(np.float32)
    r = np.sqrt(rz**2 + ry**2 + rx**2)

    if max_shell is None:
        max_shell = int(r.max())

    shells = np.arange(min_shell, max_shell + 1, dtype=np.int32)

    fsc_vals = []
    freqs = []  # cycles/voxel (radius normalized by size)
    max_dim = float(max(G.shape))

    for s in shells:
        shell = (r >= s - 0.5) & (r < s + 0.5)
        if not np.any(shell):
            fsc_vals.append(np.nan)
            freqs.append(np.nan)
            continue
        a = Fg[shell].ravel()
        b = Fx[shell].ravel()
        num = np.sum(a * np.conj(b))
        den = np.sqrt(np.sum(np.abs(a)**2) * np.sum(np.abs(b)**2)) + 1e-12
        val = np.real(num / den)
        fsc_vals.append(float(val))
        # Spatial frequency in cycles/voxel: normalized radius / max_dim
        freqs.append(float(s / max_dim))

    fsc_vals = np.array(fsc_vals, dtype=np.float32)
    freqs = np.array(freqs, dtype=np.float32)

    # Find first crossing where FSC < threshold
    idx = np.where(fsc_vals < threshold)[0]
    if idx.size == 0:
        res_freq = np.nan
    else:
        i = int(idx[0])
        # Optional linear interpolation with previous point if available
        if i > 0 and not np.isnan(fsc_vals[i-1]):
            x0, y0 = freqs[i-1], fsc_vals[i-1]
            x1, y1 = freqs[i], fsc_vals[i]
            if (y1 - y0) != 0:
                res_freq = float(x0 + (threshold - y0) * (x1 - x0) / (y1 - y0))
            else:
                res_freq = float(freqs[i])
        else:
            res_freq = float(freqs[i])

    if return_curve:
        return res_freq, (freqs, fsc_vals)
    return res_freq


def spectral_isotropy_index(vol, mask=None, min_shell=2, max_shell=None, n_theta_bins=12):
    """
    Angular isotropy score of the 3D power spectrum.
    - If mask is provided, crop to mask bounding box and zero out outside-mask voxels.
    - For each radial shell, bin power by polar angle relative to z and compute CV across bins.
    Returns SII (float). Lower SII => more isotropic.
    """
    try:
        from tqdm import tqdm
    except ImportError:
        raise ImportError("Please install tqdm: pip install tqdm")

    if mask is not None:
        bb = bounding_box_from_mask(mask)
        V = vol[bb].astype(np.float32, copy=False)
        M = (mask[bb] > 0).astype(np.float32)
        V = V * M  # apply mask inside cropped ROI to reduce leakage
    else:
        V = vol.astype(np.float32, copy=False)

    # Window to reduce boundary leakage
    Vw = V * hann3d(V.shape)

    F = spfft.fftn(Vw)
    F = spfft.fftshift(F)
    P = np.abs(F) ** 2  # power spectrum

    Z, Y, X = V.shape
    cz, cy, cx = (Z // 2, Y // 2, X // 2)
    zz, yy, xx = np.ogrid[:Z, :Y, :X]
    rz = (zz - cz).astype(np.float32)
    ry = (yy - cy).astype(np.float32)
    rx = (xx - cx).astype(np.float32)

    r = np.sqrt(rz**2 + ry**2 + rx**2) + 1e-6  # avoid div by zero
    # Polar angle theta relative to z: cos(theta) = |kz| / |k|
    costheta = np.abs(rz) / r
    theta = np.arccos(np.clip(costheta, 0.0, 1.0))  # [0, pi/2]

    if max_shell is None:
        max_shell = int(r.max())

    shells = np.arange(min_shell, max_shell + 1, dtype=np.int32)
    thetas = np.linspace(0.0, np.pi / 2, n_theta_bins + 1)

    cvs = []
    # Add tqdm progress bar here
    for s in tqdm(shells, desc="Computing SII", unit="shell"):
        shell = (r >= s - 0.5) & (r < s + 0.5)
        if not np.any(shell):
            continue
        # Bin powers by theta
        powers = []
        th = theta[shell]
        pw = P[shell]
        for i in range(n_theta_bins):
            sel = (th >= thetas[i]) & (th < thetas[i+1])
            if np.any(sel):
                powers.append(pw[sel].mean())
            else:
                powers.append(np.nan)
        powers = np.array(powers, dtype=np.float32)
        powers = powers[~np.isnan(powers)]
        if powers.size >= 2:
            cv = float(powers.std() / (powers.mean() + 1e-12))
            cvs.append(cv)

    if len(cvs) == 0:
        return np.nan
    return float(np.mean(cvs))


# -----------------------------
# Plotting: box + jittered points
# -----------------------------
def boxplot_with_points(df, metric, scope, out_path):
    """
    df columns expected: ['image', 'method', 'scope', <metric>]
    scope in {'global','mask'}
    """
    df_scope = df[df['scope'] == scope]
    if df_scope.empty:
        return False

    methods = sorted(df_scope['method'].unique())
    data = [df_scope.loc[df_scope['method'] == m, metric].dropna().values for m in methods]

    fig, ax = plt.subplots(figsize=(8, 5), dpi=150)
    bp = ax.boxplot(data, labels=methods, showfliers=False, patch_artist=True)
    for patch in bp['boxes']:
        patch.set_alpha(0.5)

    # Overlay jittered points (each image)
    rng = np.random.default_rng(42)
    for i, m in enumerate(methods):
        y = df_scope.loc[df_scope['method'] == m, metric].dropna().values
        x = np.full_like(y, i + 1, dtype=np.float32) + rng.normal(0, 0.05, size=y.shape[0])
        ax.scatter(x, y, s=20, alpha=0.75)

    ax.set_title(f"{metric} ({scope})")
    ax.grid(True, linestyle='--', alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, format='eps')
    plt.close(fig)
    return True


# -----------------------------
# Main evaluation pipeline
# -----------------------------
def discover_image_prefix(folder):
    """Find the base image_name by locating *_GT.tif (most reliable anchor)."""
    gt_files = glob(os.path.join(folder, '*_GT.tif'))
    if len(gt_files) == 0:
        gt_files = glob(os.path.join(folder, '*_gt.tif'))
    if len(gt_files) == 0:
        return None
    base = os.path.basename(gt_files[0])
    prefix = base.replace('_GT.tif', '').replace('_gt.tif', '')
    return prefix


def auto_discover_methods(subfolder, prefix, exclude={'GT','gt','mask'}):
    """
    Discover method names from files image_name_<METHOD>.tif.
    Excludes GT/mask and returns unique method strings.
    """
    methods = []
    for f in glob(os.path.join(subfolder, f'{prefix}_*.tif')):
        name = os.path.basename(f)
        suffix = name[len(prefix)+1:-4]  # between underscore and .tif
        if suffix in exclude:
            continue
        methods.append(suffix)
    # Unique, keep stable order
    seen = set()
    ordered = []
    for m in methods:
        if m not in seen:
            ordered.append(m)
            seen.add(m)
    return ordered


def eval_folder(subfolder, methods=None, include_raw=True, compute_lpips=True, slice_samples=16, device='cpu', auto_methods=False):
    prefix = discover_image_prefix(subfolder)
    if prefix is None:
        print(f"[WARN] No *_GT.tif found in {subfolder}. Skipping.")
        return []  # list of records (rows)

    paths = {
        'GT': os.path.join(subfolder, f"{prefix}_GT.tif"),
        'mask': os.path.join(subfolder, f"{prefix}_mask.tif"),
        'raw': os.path.join(subfolder, f"{prefix}_raw.tif"),
    }

    # Read GT and mask
    gt = read_tiff(paths['GT'])
    mask = None
    if os.path.exists(paths['mask']):
        mask = read_tiff(paths['mask']).astype(np.uint8)
        mask = (mask > 0).astype(np.uint8)

    # Determine methods
    if auto_methods:
        methods_list = auto_discover_methods(subfolder, prefix, exclude={'GT','gt','mask'} | ({'raw'} if include_raw else set()))
    else:
        methods_list = methods or [ "025000", "050000", "075000", "100000", "125000", "150000", "175000", "200000", "225000", "250000", "275000", "300000", "325000", "350000", "375000", "400000", "425000", "450000", "475000", "500000"]
#3D "025000", "050000", "075000", "100000", "125000", "150000", "175000", "200000", "225000", "250000"
#2D "025000", "050000", "075000", "100000", "125000", "150000", "175000", "200000", "225000", "250000", "275000", "300000", "325000", "350000", "375000", "400000", "425000", "450000", "475000", "500000"
    # Optionally prepend raw if present
    final_methods = []
    if include_raw and os.path.exists(paths['raw']):
        final_methods.append('raw')
    final_methods.extend(methods_list)

    records = []

    # Define scopes: always compute 'global'; compute 'mask' only if mask exists
    scopes = ['global']
    if mask is not None:
        scopes.append('mask')

    for m in final_methods:
        if m == 'raw':
            vol_path = paths['raw']
        else:
            vol_path = os.path.join(subfolder, f"{prefix}_{m}.tif")

        if not os.path.exists(vol_path):
            print(f"[WARN] Missing {m} in {subfolder} -> {vol_path}. Skipping this method.")
            continue

        vol = read_tiff(vol_path)
        print(f"Processing : {vol_path}")
        for scope in scopes:
            scope_mask = None if scope == 'global' else mask

            # Normalize both vol & GT to [0,1] using GT range (within scope if mask provided)
            vol01, gt01, dr = normalize_to_gt_range(vol, gt, scope_mask)

            # ---- Fidelity metrics
            mse_v = mse(gt01, vol01, scope_mask)
            print(f"metric : {mse_v}")
            mae_v = mae(gt01, vol01, scope_mask)
            print(f"metric : {mae_v}")
            psnr_v = psnr_metric(gt01, vol01, scope_mask, data_range=dr)
            print(f"metric : {psnr_v}")
            ssim_v = ssim3d(gt01, vol01, scope_mask, data_range=dr)
            print(f"metric : {ssim_v}")
            pcc_v = pearson_corr(gt01, vol01, scope_mask)
            print(f"metric pcc_v: {pcc_v}")

            # ---- LPIPS (optional)
            if compute_lpips:
                lpips_v = lpips_slicewise(gt01, vol01, scope_mask, slice_samples=slice_samples, device=device)
            else:
                lpips_v = np.nan

            # ---- FSC resolution (cycles/voxel) + voxel resolution (voxels per cycle)
            #fsc_freq = fsc_resolution(gt01, vol01, mask=scope_mask, threshold=0.143)
            #print(f"metric fsc_freq: {fsc_freq}")
            #fsc_vox = (1.0 / fsc_freq) if (isinstance(fsc_freq, float) and fsc_freq > 0) else np.nan
            #print(f"metric fsc_vox: {fsc_vox}")
            # ---- Spectral Isotropy Index (standalone, on the method volume)
            sii_v = spectral_isotropy_index(vol01, mask=scope_mask)
            print(f"metric sii_v : {sii_v}")
            rec = {
                'image': os.path.basename(subfolder),
                'method': m,
                'scope': scope,  # 'global' or 'mask'
                'MSE': mse_v,
                'MAE': mae_v,
                'PSNR': psnr_v,
                'SSIM3D': ssim_v,
                'PCC': pcc_v,
                'LPIPS': lpips_v,
                #'FSC_res_cycles_per_voxel': fsc_freq,
                #'FSC_res_voxels': fsc_vox,
                'SII': sii_v,
            }
            records.append(rec)

    return records


def main():
    ap = argparse.ArgumentParser(description="Evaluate 3D confocal restoration metrics vs GT (flexible methods, dual-scope).")
    ap.add_argument('--src_folder', required=True, help='Root folder containing one subfolder per image.')
    ap.add_argument('--out_dir', required=True, help='Output directory for CSV and plots.')
    ap.add_argument('--methods', type=str, default=None,
                    help='Comma-separated list of methods (e.g., "RL,RedLionFish,SelfNet0,SelfNetRL,Other1").')
    ap.add_argument('--auto_methods', action='store_true', help='Auto-discover methods per subfolder from *_<METHOD>.tif files.')
    ap.add_argument('--include_raw', action='store_true', help='Include *_raw.tif as a baseline method if present.')
    ap.add_argument('--no_lpips', action='store_true', help='Disable LPIPS computation.')
    ap.add_argument('--slice_samples', type=int, default=16, help='Number of slices to sample for LPIPS.')
    ap.add_argument('--device', type=str, default='cpu', help='Torch device for LPIPS (cpu or cuda).')
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)

    # Parse methods list
    methods_list = None
    if args.methods is not None:
        methods_list = [m.strip() for m in args.methods.split(',') if m.strip()]

    subfolders = [d for d in sorted(glob(os.path.join(args.src_folder, '*'))) if os.path.isdir(d)]
    if len(subfolders) == 0:
        print(f"[ERROR] No subfolders found in {args.src_folder}")
        sys.exit(1)

    all_records = []
    for sf in subfolders:
        recs = eval_folder(
            sf,
            methods=methods_list,
            include_raw=args.include_raw,
            compute_lpips=not args.no_lpips,
            slice_samples=args.slice_samples,
            device=args.device,
            auto_methods=args.auto_methods
        )
        all_records.extend(recs)

    if len(all_records) == 0:
        print("[ERROR] No records computed. Check your folder structure and filenames / methods list.")
        sys.exit(2)

    df = pd.DataFrame(all_records)
    csv_path = os.path.join(args.out_dir, 'metrics_summary.csv')
    df.to_csv(csv_path, index=False)
    print(f"[OK] Wrote CSV: {csv_path}")

    # Create box plots per metric and per scope
    metrics = ['MSE', 'MAE', 'PSNR', 'SSIM3D', 'PCC', 'LPIPS', 'FSC_res_cycles_per_voxel', 'FSC_res_voxels', 'SII']
    for metr in metrics:
        for scope in ['global', 'mask']:
            eps_path = os.path.join(args.out_dir, f'boxplot_{metr}_{scope}.eps')
            try:
                ok = boxplot_with_points(df, metr, scope, eps_path)
                if ok:
                    print(f"[OK] Wrote EPS: {eps_path}")
                else:
                    # No data for this scope; silently continue
                    pass
            except Exception as e:
                print(f"[WARN] Plot failed for {metr} ({scope}): {e}")

    print("[DONE] Evaluation complete.")


if __name__ == '__main__':
    # Silence some numerical warnings to keep logs clean
    warnings.simplefilter('ignore', category=RuntimeWarning)
    main()

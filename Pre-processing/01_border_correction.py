#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug 10 21:03:41 2024

@author: ws2
"""
import numpy as np
from skimage.transform import resize
from skimage.transform import warp
from skimage.registration import optical_flow_tvl1
from joblib import Parallel, delayed
from joblib_progress import joblib_progress

def optical_flow_task_middle(image0, image1, order=3):
    v, u = optical_flow_tvl1(image0, image1)
    nr, nc = image0.shape
    row_coords, col_coords = np.meshgrid(np.arange(nr), np.arange(nc), indexing='ij')
    image1_warp = warp(image1, np.array([row_coords + v/2, col_coords + u/2]), mode='edge', order=order)
    image0_warp = warp(image0, np.array([row_coords - v/2, col_coords - u/2]), mode='edge', order=order)
    return image0_warp, image1_warp

def parallel_optical_flow(args):
    img_par_rescale, img_impar_rescale, i, order = args
    return optical_flow_task_middle(img_par_rescale[i], img_impar_rescale[i], order)

def aligned_image_simple(img, order=3):
    if img.shape[1] % 2 != 0:
        img = img[:, :-1]
    
    img_par = np.stack([img[:, i, :] for i in range(len(img[0])) if i % 2 == 0], axis=1)
    img_impar = np.stack([img[:, i, :] for i in range(len(img[0])) if i % 2 != 0], axis=1)
    
    img_par_rescale = resize(img_par, (img_par.shape[0], img_par.shape[1] * 2, img_par.shape[2]), order=3)
    img_impar_rescale = resize(img_impar, (img_impar.shape[0], img_impar.shape[1] * 2, img_impar.shape[2]), order=3)
    
    # Paralelización usando Joblib
    with joblib_progress("Trabajo:", total=len(img_impar_rescale)):
        results = Parallel(n_jobs=-1)(delayed(optical_flow_task_middle)(img_par_rescale[i], img_impar_rescale[i], order) for i in range(len(img_impar_rescale)))
    
    # Separar los resultados en image0_warp e image1_warp
    image0_warp, image1_warp = zip(*results)
    image0_warp, image1_warp = np.array(image0_warp), np.array(image1_warp)
    
    final = np.zeros_like(img_impar_rescale)
    for i in range(len(final[0])):
        if i % 2 == 0:
            final[:, i] = image0_warp[:, i]
        else:
            final[:, i] = image1_warp[:, i]
    
    return final
#%%
from glob import glob
import numpy as np
from tifffile import imread, imwrite

def normalize_image(img):
    img_norm = (img-img.min())/(img.max()-img.min())
    return img_norm.astype(np.float32)

def load_data_prediction(path):
    
    images = sorted(glob(os.path.join(path, "*.[tT][iI][fF]*")))
    names = [i.split("/")[-1].split(".")[0] for i in images]
    images = [normalize_image(imread(image)) for image in images]
    return images, names

#%%  Inicio

import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
#%%
path = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Microscopy_images\Cropped\20240913_control_c1 (Ch2)\00_Shift correction\input" 
imgs, names = load_data_prediction(path)

#%%
imgs_alignes = [aligned_image_simple(i) for i in imgs]

#%%

def create_path(path):
    if not os.path.exists(path):
        # Create the directory
        os.makedirs(path)
        print("Directory created successfully!")
    else:
        print("Directory already exists!")

#%%
dir_output = r"D:\Current_Segovia_lab\Deconvolution_Dilan\data\Microscopy_images\Cropped\20240913_control_c1 (Ch2)\00_Shift correction\output"
create_path(dir_output)
#%%
from skimage import io
for i in range(len(imgs_alignes)):
    io.imsave(os.path.join(dir_output, names[i].split("\\")[-1] + "_optical_flow.tif"), imgs_alignes[i].astype('float16'))
    
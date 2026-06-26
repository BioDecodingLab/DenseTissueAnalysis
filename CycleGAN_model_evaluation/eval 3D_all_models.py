from models_v2 import *

# ACTIVATE GPU USAGE

gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(e)

#%%
import os
import glob
import re
from pathlib import Path

#%%

image_path = r'D:\Current_Segovia_Lab\Dilan_Martinez_temp\Synthetic_images_CycleGAN\Nuclei\Test_model_crop\Nuclei_GT_G2_crop.tif'

models_dir = r'D:\Current_Segovia_Lab\Dilan_Martinez_temp\Synthetic_images_CycleGAN\Nuclei\Result 3D\models'

output_dir = r'D:\Current_Segovia_Lab\Dilan_Martinez_temp\Synthetic_images_CycleGAN\Nuclei\Test_model_crop\predictions'

model_paths = sorted(
    glob.glob(os.path.join(models_dir, 'g_model_AtoB_3D_*.h5'))
)

print(f'Se encontraron {len(model_paths)} modelos')

#%%

input_image_path = image_path
percentiles = [0, 100]
patch_size = 64

#%%

pred = image_preprocessing(
    image=input_image_path,
    percentiles=percentiles,
    min_val=-1,
    max_val=1
)

#%%

z_step = x_step = y_step = 32
step = (z_step, x_step, y_step)
patch_size = 64

#%%

import sys

sys.path.insert(
    1,
    r'D:\Current_Segovia_Lab\Dilan_Martinez_temp\Synthetic_images_CycleGAN\Codes\3D\utils_for_eval\github'
)

from utils import pad_img

img_val = np.array([pred])

patch_size_pad = 64
step = 32

img_val_pad = np.array([
    pad_img(x, patch_size_pad, .5, 'reflect')
    for x in img_val
])

img_patchy_val = np.array([
    patchify(x, patch_size, step=((z_step, x_step, y_step)))
    for x in img_val_pad
])

img_patches_reshaped = img_patchy_val.reshape(
    len(img_val),
    -1,
    patch_size,
    patch_size,
    patch_size
)

#%%

from utils import linear_interp_vol
from utils import unpad_img

from tqdm import tqdm
from tensorflow.keras.backend import clear_session
from keras.saving import save

load_model = save.load_model
instance_norm = {'InstanceNormalization': InstanceNormalization}

input_name = Path(image_path).stem

#%%

for model_path in model_paths:

    model_number = re.search(
        r'_(\d+)\.h5$',
        os.path.basename(model_path)
    ).group(1)

    output_name = os.path.join(
        output_dir,
        f'{input_name}_{model_number}.tif'
    )

    print('\n' + '=' * 60)
    print(f'Procesando modelo: {model_number}')
    print(model_path)
    print('=' * 60)

    model = load_model(model_path, instance_norm)

    y_pred_total = []

    batch_size = 16
    tiles = 500

    for i in range(len(img_patches_reshaped)):

        y_pred = []

        for j in tqdm(
            range(0, len(img_patches_reshaped[0]), tiles),
            desc=f'Modelo {model_number}'
        ):

            y_pred_pred_batch = model.predict(
                img_patches_reshaped[i][j:j+tiles],
                batch_size=batch_size,
                verbose=0,
                use_multiprocessing=True
            )

            y_pred.extend(y_pred_pred_batch)

        y_pred_total.append(y_pred)

    # Reshape
    y_pred_total_reshaped = np.array(y_pred_total).reshape(
        np.shape(img_patchy_val)
    )
    
    print("shape predicción:", y_pred_total_reshaped.shape)
    print("shape primer elemento:", y_pred_total_reshaped[0].shape)

    # Linear interpolation
    img_total_interp = np.array([
        linear_interp_vol(
            x,
            img_val_pad[0].shape,
            64,
            32,
        )
        for x in y_pred_total_reshaped
    ])

    # Unpad
    y_pred_total_reconstruct_unpad = np.array([
        unpad_img(
            x,
            img_val[0].shape
        )
        for x in img_total_interp
    ])

    # Postprocess
    pred_out = np.array([
        image_postprocessing_norm(i, percentiles)
        for i in y_pred_total_reconstruct_unpad
    ])

    tiff.imwrite(output_name, pred_out[0])

    print(f'Guardado: {output_name}')

    del model
    clear_session()

print('\nTodos los modelos fueron procesados correctamente.')
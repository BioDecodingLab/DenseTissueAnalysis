## Conventional simulation
To perform conventional simulations, use the Data_Augmentation.ipynb notebook.
First, create a directory with the following structure:

      - dataset
            - images
                - img1.tif
                - img2.tif
            - masks
                - img1.tif
                - img2.tif

In the images folder must contain the fluorescence image.
In the masks folder must contain the idealized masks or segmentation masks (binary images)
The files in images and their corresponding masks must have the same name
Additionally, an experimental or simulated point spread function (PSF) is required.

The installation instructions are in the readme.md.

Once in jupyter notebook or jupyter lab open the Data_Augmentation.ipynb. Here indicate the following parameters:
-scr_dir: dataset folder path.
-psf_path: path to the PSF file.
-out_dir: output path.
-snr_targets: Determine the desired SNRs (e.g. snr_targets = [15] for only SNR 15 simulation, snr_targets = [1. 5. 10. 15] for SNR 1. 5. 10 and 15 simulation).
-conv_type: '2D' for isotropic images and '3D' for anisotropic images.

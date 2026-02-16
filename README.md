# 3D benchmarking dataset for bioimage analysis
This repository contains all the codes used to generate the 3D liver dataset for bencharmk different image analysis task such as image restoration, tubular segmentation and nuclei segmentation of different structures in real and simulated images.

# Repository structure
- Modified SelfNet Code
- Simulation Images
- Image pre-processing
- Evaluation: code statitics

# Usage
## Image preprocessing
Raw microscopy images were preprocessed as follows:

1- 01_border_correction.py: Image acquisition at maximum scanning speed without line-by-line averaging introduces shifts in alternating Y-columns which results in an irregular border or “serrated edge” in the image. To correct this artefact, a custom border correction step based on the TV-L1 optical flow algorithm implemented in scikit-image library, was applied. Because Y-columns were shifted in opposite directions, even and odd columns were separated, aligned via dense optical flow, symmetrically warped, and recombined to correct border misalignment, for details see REF (Paper Jorge). 

2- 02_align_channels_3D.ijm: During acquisition of multiple channels, small pixel displacement between channels can be observed. To correct this, a fifth channel which contains simultaneously the cell border and nuclei signal was acquired. This channel was used as reference to align all other channels using the function Correct 3D drift from Fiji. 
      Used parameters: Reference channel cell border + nuclei (refChannel = 5), no threshold used (MinIntensity = 0), maximum shift of 30 voxels (maxShift = 30), length of selection square 256 x 256 pix (L= 256).

3- Stitching: To cover the entire CV-PV axis, images were acquired as 2 x 1 tiles, which were stitched using the stitching plugin in Fiji with the row-by-row grid option, 10% overlap and subpixel accuracy. Images were subsequently cropped in X, Y and Z to remove black pixels.

4- 03_Intensity_correction.ijm: Finally, volumetric images exhibit a depth-dependent intensity attenuation along the Z axis, resulting in reduced intensity in deeper planes. To correct this effect, image intensities were normalized for each slice and channels using cumulative histograms computed in 16 bits (nBins = 65536), mapping the 10-99.99% intensity range (Ilow = 10, Ihigh = 100). Photobleaching was corrected with the Bleach correction plugin with the Histogram matching method.

## Idealized tissue generation (ver1 tengo que terminarlo)
For idealized tissue generation first a triangle mesh of the segmented structure is needed.

For this we used the software MotionTracking (http://motiontracking.mpi-cbg.de) as follows:

1- Generate MotionTracking project, need to conect MT to fiji (see instructions in readme), in MT go to 

      File > Import > Import Microscopy images > BioFormat ImageJ   and select the segmentation
      
      Bile canaliculi: Use the script bc.p3a, this generates 


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

## SelfNet isotropic restoration
Here we provide a modifed version of SelfNet network (see REF) 
All steps are performed using Jupyter Notebook.

1- Generate training data.

Create a source directory with the following structure:
      
                  - source data
                        - structure1
                        - structure2
      
To generate the training data use the Generate_training_data_Iso_Simple-Liver.ipynb and specify the following parameters:
srcpath: path to the source data folder

      dirSource = srcpath + 'structure1': replace 'structure1' with the name of the folder corresponding to the structure of interest
      dirTarget = srcpath + 'structure1': same as dirSource
      dirOut: output path
      psf_path: path to the PSF file
      Niter: Number of Richardson-Lucy deconvolution iterations, set 0 for SelfNet isotropic restoration only.

2- Training the network
      - For training use the Train_self_net.ipynb notebook. 
        Here only need to indicate the training data generated in step 1 (dirOut).
      
      Once training is complete, a Checkpoint folder will be created with the following structure:
                  - source data
                        - structure1
                              - Checkpoint
                                    - intermediate_results: Example images of each model
                                    - saved_models: Models stored in .plk format
                        - structure2
      Check intermediate_results folder for example images of each generated model. Select the models that achieve the best visual restoration and note the corresponding epoch and iteration numbers.
3- Prediction
      - For image prediction use the Predict_folder_tiffs-liver.ipynb notebook and indicate the following parameters:
      
            -modelName: Name of the structure folder (e.g. structure1)
            -epoch: epoch number of the model of interest
            -itter: iteration number of the model of interest
            -srcpath = r'Modify here'+modelName+'/': Path to the models folder (e.g. source data/structure1/)
            -img_src_path: Path to test image folder
            -outdir: Output path

      Alternatively you can use the Predict_folder_tiffs-liver_different_iteration.ipynb which allows prediction using multiple models at once. In this case, all parameters are the same as in the previous notebook, except for a single parameter:
      
      -iteration: combined epoch and iteration identifier that replaces the separate epoch and itter parameters (e.g. epoch 98, iterattion 10000 would be 98_10000)

## Quantification_codes
Used codes for FWHM measurements:

      -FWHM_macro folder: Contains the used intensity profiles to measure FWHM. These macro generates a folder that contains 2 subfolders (Axial and lateral) that contains .csv files with the intensity values. 
      
      -00_Delete first column_v2.py: macro generated .csv contains an extra first column, this script is used to delete that column.
      
      -01_fwhm_nuclei_corregido-Copy_modif_.ipynb: Script for FWHM measurements, at the end of the script scpecify the following parameters:
            - base_dir: Path to the directory that contains the result folder of FWHM macro
            - remove_mid_peaks: True for nuclei, False to other structures

# References
- SelfNet (Paper): Ning, K., Lu, B., Wang, X. et al. Deep self-learning enables fast, high-fidelity isotropic resolution restoration for volumetric fluorescence microscopy. Light Sci Appl 12, 204 (2023). https://doi.org/10.1038/s41377-023-01230-2
- SelfNet (Zenodo repository): Kefu Ning, Bolin Lu, Xiaojun Wang, Xiaoyu Zhang, Shuo Nie, Tao Jiang, Anan Li, Guoqing Fan, Xiaofeng Wang, Qingming Luo, Hui Gong, & Jing Yuan. (2023). Self_Net: Deep self-learning enables fast, high-fidelity isotropic resolution restoration for volumetric fluorescence microscopy. Zenodo. https://doi.org/10.5281/zenodo.7882519
- CycleGAN: Bettancourt N, Pérez-Gallardo C, Candia V, Guevara P, Kalaidzidis Y, Zerial M, et al. (2024) Virtual tissue microstructure reconstruction across species using generative deep learning. PLoS ONE 19(7): e0306073. https://doi.org/10.1371/journal.pone.0306073
- RedLionFish deconvolution: https://github.com/rosalindfranklininstitute/RedLionfish?tab=readme-ov-file
- CellposeSAM: Cellpose-SAM: superhuman generalization for cellular segmentation
Marius Pachitariu, Michael Rariden, Carsen Stringer
bioRxiv 2025.04.28.651001; doi: https://doi.org/10.1101/2025.04.28.651001
- AttentionUnet3D: Velasco, R., Pérez-Gallardo, C., Segovia-Miranda, F., Morales-Navarrete, H. An Open-source Protocol for Deep Learning-based Segmentation of Tubular Structures in 3D Fluorescence Microscopy Images. J. Vis. Exp. (225), e68004, doi:10.3791/68004 (2025).

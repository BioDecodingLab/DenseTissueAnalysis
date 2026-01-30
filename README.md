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
First, image acquisition at maximum scanning speed without line-by-line averaging introduces shifts in alternating Y-columns which results in an irregular border or “serrated edge” in the image. To correct this artefact, a custom border correction step based on the TV-L1 optical flow algorithm implemented in scikit-image library, was applied (01_border_correction.py). Because Y-columns were shifted in opposite directions, even and odd columns were separated, aligned via dense optical flow, symmetrically warped, and recombined to correct border misalignment, for details see REF (Paper Jorge). 
During acquisition of multiple channels, small pixel displacement between channels can be observed. To correct this, a fifth channel which contains simultaneously the cell border and nuclei signal was acquired. This channel was used as reference to align all other channels using the function Correct 3D drift from Fiji (02_align_channels_3D.ijm). Used parameters: Reference channel cell border + nuclei (refChannel = 5), no threshold used (MinIntensity = 0), maximum shift of 30 voxels (maxShift = 30), length of selection square 256 x 256 pix (L= 256).
To cover the entire CV-PV axis, images were acquired as 2 x 1 tiles, which were stitched using the stitching plugin in Fiji with the row-by-row grid option, 10% overlap and subpixel accuracy. Images were subsequently cropped in X, Y and Z to remove black pixels.
Finally, volumetric images exhibit a depth-dependent intensity attenuation along the Z axis, resulting in reduced intensity in deeper planes. To correct this effect, image intensities were normalized for each slice and channels using cumulative histograms computed in 16 bits (nBins = 65536), mapping the 10-99.99% intensity range (Ilow = 10, Ihigh = 100). Photobleaching was corrected with the Bleach correction plugin with the Histogram matching method (03_Intensity_correction.ijm).

## Conventional simulation
For conventional simulation use the script Data_Augmentation.ipynb.
First need a directory ordened as follows:
- dataset
      - images
          - img1.tif
          - img2.tif
      - masks
          - img1.tif
          - img2.tif

In the folder images are the fluorescence image.
In the folder masks are the idealized masks or segmentation masks (must be binary)
The files in images and their corresponding masks must have the same name
Also you will need a experimental or generated PSF.

The installation instructions are in the readme.md.

Once in jupyter notebook or jupyter lab open the Data_Augmentation.ipynb. Here you have to indicate: dataset folder path, psf path and output directory, use snr_targets to determine the desired SNRs (e.g. snr_targets = [15] for only SNR 15 simulation, snr_targets = [1. 5. 10. 15] for SNR 1. 5. 10 and 15 simulation), use conv_type = '2D' for isotropic images and conv_type = '3D' for anisotropic images.

## SelfNet isotropic restoration
Here we provide a modifed version of SelfNet network (see REF) 


# References
- SelfNet (Paper): Ning, K., Lu, B., Wang, X. et al. Deep self-learning enables fast, high-fidelity isotropic resolution restoration for volumetric fluorescence microscopy. Light Sci Appl 12, 204 (2023). https://doi.org/10.1038/s41377-023-01230-2
- SelfNet (Zenodo repository): Kefu Ning, Bolin Lu, Xiaojun Wang, Xiaoyu Zhang, Shuo Nie, Tao Jiang, Anan Li, Guoqing Fan, Xiaofeng Wang, Qingming Luo, Hui Gong, & Jing Yuan. (2023). Self_Net: Deep self-learning enables fast, high-fidelity isotropic resolution restoration for volumetric fluorescence microscopy. Zenodo. https://doi.org/10.5281/zenodo.7882519
- CycleGAN: Bettancourt N, Pérez-Gallardo C, Candia V, Guevara P, Kalaidzidis Y, Zerial M, et al. (2024) Virtual tissue microstructure reconstruction across species using generative deep learning. PLoS ONE 19(7): e0306073. https://doi.org/10.1371/journal.pone.0306073
- RedLionFish deconvolution: https://github.com/rosalindfranklininstitute/RedLionfish?tab=readme-ov-file
- CellposeSAM: Cellpose-SAM: superhuman generalization for cellular segmentation
Marius Pachitariu, Michael Rariden, Carsen Stringer
bioRxiv 2025.04.28.651001; doi: https://doi.org/10.1101/2025.04.28.651001
- AttentionUnet3D: Velasco, R., Pérez-Gallardo, C., Segovia-Miranda, F., Morales-Navarrete, H. An Open-source Protocol for Deep Learning-based Segmentation of Tubular Structures in 3D Fluorescence Microscopy Images. J. Vis. Exp. (225), e68004, doi:10.3791/68004 (2025).

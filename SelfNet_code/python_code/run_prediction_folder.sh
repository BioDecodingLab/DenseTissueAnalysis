#!/bin/bash

# Specify the path to the folder containing the .czi files
folder_path="/media/hmorales/Skynet/Isotropic/" #"/run/user/1000/gvfs/smb-share:server=134.34.176.179,share=pmtest_fast/Cornelius/pErk/20230913/sample/"
out_folder="/media/hmorales/Skynet/Isotropic/" #"/run/user/1000/gvfs/smb-share:server=134.34.176.179,share=pmtest_fast/Cornelius/pErk/20230913/IsotropicNew/" 

# Loop through all .czi files in the folder
for file in "$folder_path"/*.czi; do
    if [ -f "$file" ]; then
        # Run the Python script with the current .czi file as an argument
        #python Predict_czi_cluster.py --img_src_path "$file" --outdir $out_folder
        python Predict_czi_cluster_distorted_left.py --img_src_path "$file" --outdir $out_folder
    fi
done

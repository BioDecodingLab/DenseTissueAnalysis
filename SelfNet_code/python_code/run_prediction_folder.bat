
@echo off
setlocal enabledelayedexpansion

:: Specify the path to the folder containing the .czi files
set "folder_path=Y:/Cornelius/pErk/fusingtest/20230914/"

:: Specify the output folder path
set "out_folder=Y:/Cornelius/pErk/fusingtest/20230914/"

:: Loop through all .czi files in the folder
for %%F in ("%folder_path%\*.czi") do (
   
    if exist "%%F" (
        :: Run the Python script with the current .czi file as an argument
        echo Processing file: %%~nxF
        python Predict_czi_cluster.py --img_src_path "%%F" --outdir !out_folder!
    )
)

:: End of the script

Orden de preprocesamiento:

1- Crop a los pixeles negros de la imagen cruda
2- Border correction en python Jorge (01_border_correction) (fijarse en el resultado los bits de la imagen y que el hiperstack esté correcto en
términos de frames y slices)
3- Alineamiento (si es necesario) (macro 02_align_channels_3D)
4- crop de pixeles negros (si es necesario )
5- stitching 
6- crop de pixeles negros (si es necesario )
7- image normalization (macro 03_Intensity_correction)
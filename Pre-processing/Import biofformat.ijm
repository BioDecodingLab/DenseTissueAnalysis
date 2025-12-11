// Código del Macro para abrir imágenes desde una carpeta, utilizar Bio-Formats y guardarlas como TIFF
// Asegúrate de cambiar "C:/ruta/a/tu/carpeta" por la ruta de la carpeta donde están tus imágenes

// Ruta de la carpeta con las imágenes
dir = getDirectory("Choose Source Directory ");
outdir = getDirectory("Choose Source Directory ");

// Obtener la lista de archivos en la carpeta
list = getFileList(dir);

// Recorrer la lista de archivos
for (i = 0; i < list.length; i++) {
    // Obtener la ruta completa de cada archivo
    path = dir + "/" + list[i];
    
    // Abrir la imagen utilizando Bio-Formats
    run("Bio-Formats Importer", "open=[" + path + "]");
    
    // Extraer el nombre del archivo sin extensión
    filename = File.getNameWithoutExtension(path);
    
    // Guardar la imagen como TIFF
    saveAs("Tiff", outdir + "/" +"Img1_"+ filename + ".tif");
    
    // Cerrar la imagen actual
    close();
}

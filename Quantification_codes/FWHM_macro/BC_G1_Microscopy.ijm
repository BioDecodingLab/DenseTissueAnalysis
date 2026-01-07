// Macro para procesar todas las imágenes .tif de un directorio 
// y guardar los resultados en carpetas creadas automáticamente según el nombre de la imagen.

// Solicita el directorio de entrada (donde se encuentran las imágenes .tif)
inputDir = getDirectory("Selecciona la carpeta que contiene las imágenes (.tif)");

// Solicita el directorio base de salida
baseOutput = getDirectory("Selecciona la carpeta base para guardar los resultados");

// Obtiene la lista de archivos del directorio de entrada
list = getFileList(inputDir);

for (i = 0; i < list.length; i++) {
    file = list[i];
    // Procesa solo imágenes .tif
    if (endsWith(file, ".tif") || endsWith(file, ".TIF")) {
        // Abre la imagen
        open(inputDir + file);
        
        // Obtener nombre de la imagen y quitar extensión
        imageTitle = getTitle();
        dotIndex = indexOf(imageTitle, ".");
        if (dotIndex != -1) {
            baseName = substring(imageTitle, 0, dotIndex);
        } else {
            baseName = imageTitle;
        }
        
         // --- AQUI: aplicar blur solo si el nombre contiene ciertas palabras ---
        if (indexOf(baseName, "_raw") != -1 || indexOf(baseName, "_RL20") != -1 || indexOf(baseName, "_GT") != -1) {
            // Ajusta los valores x,y,z si lo deseas
            run("Gaussian Blur 3D...", "x=0.8 y=0.8 z=0.8");
        }
       // ---------------------------------------------------------------------
       
        // Crear carpeta para esta imagen y sus subcarpetas
        folderBase = baseOutput + baseName + "/";
        File.makeDirectory(folderBase);
        File.makeDirectory(folderBase + "Lateral");
        File.makeDirectory(folderBase + "Axial");
        
        outputxy = folderBase + "Lateral/";
        outputxz = folderBase + "Axial/";
        
        
        // --- Procesamiento de líneas XY ---
        // Definir las coordenadas de las líneas (slice, x1, y1, x2, y2)
        lines = newArray(
        	178, 540, 57, 540, 81,
        	171, 603, 46, 603, 68,
        	133, 354, 51, 354, 73,
        	57, 962, 54, 962, 79,
        	196, 459, 93, 459, 114,		//5
        	205, 160, 117, 160, 136,
        	75, 312, 130, 312, 155,
        	44, 364, 132, 364, 153,
        	121, 744, 139, 744, 166,
        	58, 1176, 129, 1196, 129,	//10
        	55, 1110, 158, 1120, 172,
        	230, 437, 158, 437, 181,
        	145, 1559, 169, 1559, 193,
        	235, 991, 208, 1006, 208,
        	133, 898, 198, 898, 211,	//15
        	50, 893, 192, 893, 209,
        	140, 1147, 262, 1173, 262,
        	143, 521, 235, 521, 253,
        	151, 647, 264, 647, 283,
        	192, 846, 304, 846, 322,	//20
        	42, 511, 309, 511, 325,
        	109, 1166, 233, 1166, 251,
        	43, 819, 363, 842, 363,
        	87, 797, 392, 797, 412,
        	130, 838, 758, 838, 787		//25
        	       	        	
 
                                 
        );
        
        // Procesa cada línea y guarda los resultados en la carpeta "Lateral"
        for (j = 0; j < lengthOf(lines); j += 5) {
            slice = lines[j];
            x1 = lines[j + 1]; y1 = lines[j + 2];
            x2 = lines[j + 3]; y2 = lines[j + 4];
        
            setSlice(slice);
            makeLine(x1, y1, x2, y2);
            run("Plot Profile");
            Plot.getValues(xpoints, ypoints);
            
            Table.create("Results");
            Table.setColumn("X", xpoints);
            Table.setColumn("Y", ypoints);
            Table.update;
        
            // Guardar archivo CSV en Lateral
            Table.save(outputxy + "Result_XY_" + (j/5 + 1) + ".csv");
            close(); // Cierra la tabla
        }
        
        // --- Procesamiento de líneas XZ ---
        // Vuelve a la imagen original y realiza un reslice
        selectImage(imageTitle);
        run("Select None");
        run("Reslice [/]...", "output=1.000 start=Top avoid");
        
        // Coordenadas de las líneas XZ (slice, x1, y1, x2, y2)
        lines_xz = newArray(   
        	67, 540, 149, 540, 206,
        	59, 605, 133, 605, 209,
        	64, 353, 96, 353, 160,
        	67, 962, 28, 962, 87,
        	105, 456, 158, 456, 227,	 //5
        	128, 159, 173, 159, 234,
        	144, 309, 43, 309, 110,
        	144, 366, 12, 366, 73,
        	154, 745, 87, 745, 152,
        	163, 1227, 23, 1227, 88,	//10
        	164, 1137, 21, 1137, 88,
        	171, 441, 202, 441, 252,
        	181, 1558, 118, 1558, 172,
        	196, 1001, 207, 1001, 256,
        	206, 899, 108, 899, 157,	//15
        	202, 897, 13, 897, 84,
        	225, 1133, 12, 1133, 73,
        	245, 522, 113, 522, 169,
        	275, 648, 129, 648, 172,
        	315, 840, 166, 840, 219,	//20
        	318, 513, 19, 513, 59,
        	375, 1160, 79, 1160, 140,
        	387, 939, 5, 939, 78,
        	403, 799, 53, 799, 120,
        	774, 837, 99, 837, 158	//25
        	
        	
		
        );
        
        // Procesa cada línea y guarda los resultados en la carpeta "Axial"
        for (j = 0; j < lengthOf(lines_xz); j += 5) {
            slice = lines_xz[j];
            x1 = lines_xz[j + 1]; y1 = lines_xz[j + 2];
            x2 = lines_xz[j + 3]; y2 = lines_xz[j + 4];
        
            setSlice(slice);
            makeLine(x1, y1, x2, y2);
            run("Plot Profile");
            Plot.getValues(xpoints, ypoints);
            
            Table.create("Results");
            Table.setColumn("X", xpoints);
            Table.setColumn("Y", ypoints);
            Table.update;
        
            // Guardar archivo CSV en Axial
            Table.save(outputxz + "Result_XZ_" + (j/5 + 1) + ".csv");
            close(); // Cierra la tabla
        }
        
        // Cierra la imagen procesada
        close();
        close();
    }
}

print("Procesamiento completado para todas las imágenes.");

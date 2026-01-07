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
        if (indexOf(baseName, "_raw") != -1 || indexOf(baseName, "_RL10") != -1 || indexOf(baseName, "_GT") != -1) {
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
        	81, 1062, 850, 1105, 850,		//1 este
      		57, 506, 0, 506, 43,
      		184, 877, 28, 950, 28,
      		144, 1225, 31, 1293, 31,
      		231, 1162, 1, 1162, 50,		//5 
      		89, 577, 12, 577, 64,
      		95, 1273, 25, 1273, 88,
      		134, 360, 820, 360, 861,		//8 este
      		118, 482, 372, 561, 372,	//9 este
      		147, 828, 117, 892, 117,	//10
      		52, 563, 104, 563, 153,
      		86, 887, 80, 887, 131,
      		106, 907, 82, 907, 127,
      		57, 584, 83, 584, 130,
      		58, 480, 739, 537, 739,		//15 este
      		137, 1120, 132, 1120, 195,
      		73, 513, 173, 513, 248,
      		109, 765, 213, 765, 275,
      		202, 812, 275, 812, 336,
      		185, 850, 274, 850, 329,	//20
      		86, 836, 356, 836, 417,
      		35, 860, 387, 923, 387,
      		77, 919, 427, 919, 480,
      		74, 600, 544, 659, 544,
      		147, 833, 588, 833, 640		//25

                                 
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
        	849, 1085, 39, 1085, 115,
        	21, 505, 20, 505, 93,
        	31, 914, 142, 914, 221,
        	33, 1261, 99, 1261, 186,
        	28, 1164, 192, 1164, 273,		//5
        	39, 577, 51, 577, 129,
        	58, 1274, 52, 1274, 133,
        	844, 359, 97, 359, 172,
        	374, 523, 70, 523, 163,
        	120, 859, 105, 859, 188,	//10
        	129, 564, 8, 564, 87,
        	108, 887, 47, 887, 124,
        	107, 909, 68, 909, 138,
        	108, 580, 17, 580, 94,
        	740, 509, 11, 509, 104,		//15
        	165, 1121, 98, 1121, 174,	//*
        	212, 514, 27, 514, 118,
        	246, 765, 67, 765, 151,
        	307, 814, 157, 814, 248,
        	300, 855, 150, 855, 223,	//20
        	387, 840, 36, 840, 133,
        	387, 890, 69, 890, 0,
        	452, 922, 37, 922, 118,
        	545, 630, 28, 630, 120,
        	614, 833, 108, 833, 183		//25

      		
      		

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

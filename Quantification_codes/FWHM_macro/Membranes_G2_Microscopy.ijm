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
			54, 1001, 427, 1001, 502,
			63, 1079, 646, 1079, 689,
			57, 522, 537, 533, 556,
			67, 1220, 317, 1220, 360,
			46, 1465, 308, 1477, 292,		//5
			59, 953, 355, 964, 374,
			87, 638, 637, 638, 672,
			99, 600, 639, 614, 631,
			122, 1113, 692, 1113, 730,
			121, 1404, 748, 1404, 782,		//10
			143, 881, 801, 881, 832,
			84, 866, 399, 885, 412,		
			150, 1067, 718, 1098, 718,
			61, 1089, 728, 1108, 750,
			68, 1249, 725, 1249, 758,		//15
			196, 1170, 714, 1170, 741,
			200, 1191, 467, 1226, 449,
			190, 1037, 588, 1054, 567,
			43, 1225, 86, 1225, 120,
			186, 436, 535, 471, 535,		//20			
			6, 435, 738, 484, 738,
			1, 361, 64, 361, 84,
			41, 619, 785, 619, 802,
			37, 1333, 345, 1333, 368,
			33, 630, 784, 630, 805			//25
			
                                 
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
				503, 989, 0, 989, 40,
				721, 887, 24, 887, 101,
				603, 449, 32, 449, 101,
				340, 1232, 29, 1232, 98,
				335, 1398, 27, 1398, 85,		//5
				464, 989, 28, 989, 84,
				655, 657, 58, 657, 108,
				573, 550, 66, 550, 138,
				710, 1111, 95, 1111, 149,
				765, 1392, 98, 1392, 143,		//10
				815, 882, 117, 882, 169,
				420, 712, 70, 712, 124,
				735, 1056, 141, 1056, 193,
				721, 898, 37, 898, 84,
				743, 1249, 44, 1249, 92,		//15
				742, 1331, 167, 1331, 224,
				479, 1252, 170, 1252, 229,
				674, 1040, 192, 1040, 238,
				598, 956, 4, 956, 51,
				569, 498, 155, 498, 219,		//20
				492, 383, 68, 383, 104,	
				357, 1329, 20, 1329, 52,
				735, 1311, 140, 1311, 172,
				752, 527, 83, 527, 140,
				491, 408, 32, 408, 73			//25

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

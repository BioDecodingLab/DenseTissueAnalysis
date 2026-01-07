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
        	116, 1166, 591, 1166, 632,
        	136, 923, 68, 987, 69,
			101, 1517, 78, 1517, 131, 
			182, 1410, 306, 1482, 306, 
			133, 1159, 177, 1159, 258,	//5
			181, 439, 172, 439, 222, 
			69, 231, 106, 232, 203, 
			138, 1495, 179, 1495, 242, 
			156, 798, 104, 799, 170,
			129, 1174, 91, 1175, 173,	//10
			128, 368, 78, 368, 131, 
			184, 437, 162, 438, 228,
			203, 1052, 263, 1052, 320,	
			183, 927, 626, 927, 678,	 
			138, 1256, 340, 1256, 409,	//15 
			171, 625, 165, 625, 223,	
			162, 697, 306, 697, 358, 
			65, 872, 621, 872, 682, 
			43, 1375, 616, 1375, 675,
			119, 1035, 443, 1035, 509, //20
			188, 1575, 372, 1575, 436,
			169, 1390, 732, 1390, 781, 
			53, 1542, 565, 1605, 565, 
			164, 1002, 549, 1002, 608, 
			90, 1092, 336, 1157, 336 	
                                 
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
			70, 955, 107, 955, 168,
			85, 431, 35, 431, 116, 
			107, 1517, 66, 1517, 139,  
			309, 1445, 140, 1445, 221, 
			219, 1159, 87, 1159, 179,		//5
			203, 439, 136, 439, 226, 
			158, 232, 30, 232, 94,   
			214, 1493, 89, 1493, 178, 
			137, 799, 113, 799, 197,
			133, 1175, 83, 1175, 168,		//10 
			110, 368, 92, 368, 163, 
			202, 439, 139, 439, 210,  
			293, 1052, 168, 1052, 234,	
			654, 929, 148, 929, 212,     
			372, 1257, 96, 1257, 176, 	//15
			198, 625, 128, 625, 201, 
			335, 696, 116, 696, 199, 
			653, 872, 23, 872, 105, 
			646, 1375, 8, 1375, 74, 
			477, 1035, 81, 1034, 150,	//20
			403, 1576, 150, 1576, 217,
			758, 1389, 131, 1389, 203, 
			566, 1573, 15, 1573, 85, 
			580, 1002, 124, 1002, 196,  
			338, 1124, 51, 1124, 122		//25 

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

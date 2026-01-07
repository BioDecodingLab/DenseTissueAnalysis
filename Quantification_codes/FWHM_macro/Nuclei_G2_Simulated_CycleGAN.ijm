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
			47, 688, 15, 688, 77,	
      		120, 1052, 32, 1052, 84, 
      		95, 1444, 30, 1443, 92, 
      		81, 274, 30, 344, 30,  
      		97, 215, 70, 215, 129,		//5 
      		100, 492, 49, 492, 100,    
      		177, 1319, 41, 1382, 41, 
      		134, 360, 816, 361, 862,		
      		89, 1037, 209, 1100, 209,		
      		181, 1081, 62, 1154, 62,	//10 
      		52, 564, 93, 564, 163,
      		86, 887, 72, 886, 138,
      		235, 1261, 466, 1261, 524,
      		58, 583, 72, 584, 140,
      		58, 1174, 487, 1173, 545,		//15 
      		153, 1403, 460, 1402, 528,
      		99, 539, 369, 539, 421,
      		186, 1268, 94, 1348, 94,
      		226, 938, 213, 939, 281,
      		151, 1395, 9, 1395, 57,	//20 
      		158, 1444, 126, 1445, 185,
      		57, 583, 77, 584, 137,
      		57, 615, 245, 616, 309,
      		67, 1084, 279, 1084, 334,
      		70, 830, 597, 830, 645		//25
                                 
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
            wait(100);
            close(); // Cierra la tabla
        }
        
        // --- Procesamiento de líneas XZ ---
        // Vuelve a la imagen original y realiza un reslice
        selectImage(imageTitle);
        run("Select None");
        run("Reslice [/]...", "output=1.000 start=Top avoid");
        
        // Coordenadas de las líneas XZ (slice, x1, y1, x2, y2)
        lines_xz = newArray(
        	46, 688, 6, 688, 88,
        	59, 1052, 73, 1052, 167,	//2
        	449, 1244, 140, 1244, 218,
            31, 306, 42, 306, 121,
        	102, 215, 57, 215, 134,		//5
        	77, 494, 65, 494, 135, 
        	40, 1349, 136, 1349, 217,
        	841, 361, 87, 361, 170,
        	211, 1068, 53, 1068, 122,
        	64, 1112, 137, 1112, 221,	//10
        	132, 564, 17, 564, 82,
        	241, 88, 111, 88, 177, 
        	497, 1259, 199, 1260, 270,
        	106, 584, 16, 585, 89,
        	515, 1175, 15, 1175, 94, 		//15
        	495, 1403, 113, 1403, 199,  
        	397, 540, 61, 540, 133, 
        	94, 1305, 149, 1305, 218,
        	244, 938, 185, 938, 267,
        	33, 1395, 118, 1395, 183,	//20
        	161, 1444, 127, 1444, 187,		//21
        	106, 584, 19, 584, 85,
        	282, 616, 7, 616, 99,			//23
        	307, 1084, 26, 1084, 102,
        	623, 829, 36, 829, 102  	//25
        	
        	
        	
      		
      		

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
            wait(100);
            close(); // Cierra la tabla
        }
        
        // Cierra la imagen procesada
        close();
        close();
    }
}

print("Procesamiento completado para todas las imágenes.");

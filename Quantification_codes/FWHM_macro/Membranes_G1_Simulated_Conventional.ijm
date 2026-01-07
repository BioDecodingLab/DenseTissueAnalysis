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
        	177, 612, 43, 612, 72,
      		57, 1500, 35, 1500, 69,
        	119, 354, 51, 354, 73,
        	41, 991, 88, 1002, 63,
        	185, 459, 93, 459, 114,		//5
        	205, 160, 117, 160, 136,
        	75, 312, 130, 312, 155,
        	34, 364, 132, 364, 153,
        	127, 744, 139, 744, 166,
        	58, 1177, 42, 1202, 66,	//10
        	55, 1101, 160, 1113, 181,
        	213, 437, 158, 437, 181,	
        	142, 1590, 163, 1613, 190,
        	232, 1078, 41, 1078, 86,
        	133, 753, 780, 753, 824, 	//15
        	50, 1479, 737, 1479, 772,
        	137, 403, 571, 403, 604,
        	125, 1275, 556, 1275, 615,	
        	158, 620, 246, 647, 246,
        	196, 1081, 167, 1081, 204,	//20
        	48, 450, 338, 497, 355,
        	112, 1171, 229, 1179, 245,
        	43, 819, 363, 842, 363,
        	88, 1200, 98, 1200, 135,
        	157, 472, 115, 521, 115 	//25
        	       	        	
 
                                 
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
         	67, 545, 151, 545, 208,
        	44, 618, 162, 618, 231,
        	35, 100, 81, 100, 140,
        	67, 962, 28, 962, 87,
        	111, 1525, 46, 1525, 111,		 //5	
        	109, 786, 98, 786, 165,
        	125, 1442, 39, 1442, 105,
        	142, 499, 151, 499, 201,
        	179, 1533, 121, 1533, 186,
        	178, 970, 116, 970, 187,	//10
        	175, 1414, 11, 1414, 56,
        	183, 425, 167, 425, 218,
        	205, 352, 11, 352, 64,
        	198, 1001, 216, 1001, 259,	
        	199, 781, 87, 781, 154,		//15	
        	199, 885, 17, 885, 88,
        	148, 844, 164, 844, 228,	
        	164, 1092, 61, 1092, 118,
        	153, 863, 104, 863, 150,
        	225, 290, 71, 290, 132,		//20
        	182, 426, 170, 426, 215,
        	249, 1249, 50, 1249, 113,
        	388, 942, 4, 942, 77,		
        	256, 515, 66, 515, 119,
        	371, 1387, 152, 1387, 209	//25
        	
        	
        	
		
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

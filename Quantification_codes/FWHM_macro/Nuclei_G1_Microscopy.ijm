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
        	123, 566, 3, 566, 52,
        	153, 596, 24, 651, 24,
        	111, 930, 605, 930, 652,
        	89, 1259, 804, 1259, 861,
        	183, 423, 82, 423, 125,		//5
        	72, 1034, 815, 1083, 815,	
        	120, 941, 642, 983, 642,
        	116, 922, 162, 977, 162,
        	75, 1174, 766, 1174, 823,
        	105, 1123, 213, 1174, 213,	//10
        	37, 954, 202, 954, 253,
        	143, 824, 312, 875, 312,
        	120, 1017, 297, 1082, 297,
        	130, 406, 804, 460, 804,       	        	
        	103, 1314, 311, 1314, 359,	//15
        	80, 1148, 335, 1148, 390,
			96, 936, 400, 994, 400,
			66, 958, 403, 958, 466,
			162, 974, 452, 1039, 452,
			90, 402, 739, 402, 784,		//20
			81, 678, 543, 678, 604,
			176, 930, 567, 930, 610,
			48, 1170, 607, 1170, 662,
			163, 1254, 671, 1254, 730,
			100, 861, 728, 922, 728		//25
			
			
        	

                                 
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
			30, 566, 86, 566, 157,
			25, 623, 111, 623, 187,
			629, 932, 75, 932, 145,
			831, 1262, 46, 1262, 129,
			105, 420, 151, 420, 208,	//5	
			815, 1060, 30, 1060, 112,	
			642, 962, 85, 962, 157,				
			164, 951, 73, 951, 150,
			796, 1174, 37, 1174, 111,
			214, 1146, 53, 1146, 154,	//10
			229, 951, 1, 951, 70,
			314, 849, 107, 852, 180,
			300, 1050, 81, 1050, 155,
			805, 431, 91, 431, 162,
			337, 1316, 64, 1316, 139,	//15
			362, 1149, 43, 1149, 110,
			402, 962, 49, 962, 142,
			436, 957, 27, 957, 108,
			456, 1008, 116, 1008, 201,
			763, 401, 44, 401, 136,		//20
			576, 680, 44, 680, 117,
			591, 932, 135, 932, 218,
			635, 1169, 7, 1169, 89,
			701, 1254, 120, 1254, 201,
			729, 892, 59, 892, 136		//25
		
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

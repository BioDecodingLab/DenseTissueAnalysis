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
        	
        	149, 1114, 0, 1114, 12,
        	70, 203, 38, 227, 38,
        	165, 1202, 20, 1202, 36,
        	129, 824, 22, 849, 22,
        	102, 154, 33, 154, 62,	//5
        	34, 1159, 48, 1159, 68,
        	112, 1178, 53, 1178, 72,
        	45, 1149, 100, 1162, 83,
        	155, 1084, 29, 1104, 29,
        	42, 1196, 92, 1196, 118,	//10
        	61, 711, 65, 711, 92,
        	215, 303, 170, 318, 185,
        	110, 1036, 238, 1051, 211,
        	120, 967, 148, 967, 167,	
        	63, 142, 161, 142, 179,		//15
        	120, 1063, 171, 1063, 192,
        	221, 518, 183, 518, 201,
			35, 861, 190, 861, 213,
			43, 1304, 208, 1304, 226,
			110, 1441, 251, 1441, 268,	//20
			66, 251, 255, 251, 272,
			32, 978, 271, 978, 292,
			163, 1019, 386, 1019, 401,
			130, 1202, 393, 1202, 409,
			176, 967, 413, 967, 428		//25


 
                                 
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
        	5, 1112, 116, 1112, 182,
        	14, 229, 43, 229, 97,
        	15, 1070, 163, 1070, 221,
        	10, 1067, 31, 1067, 111,
        	48, 154, 70, 154, 129,	//5
        	59, 1160, 9, 1160, 56,
        	63, 1178, 85, 1178, 136,
        	55, 1072, 183, 1072, 239,
        	78, 1066, 127, 1066, 182,
        	104, 1195, 11, 1195, 69,	//10
        	78, 711, 33, 711, 90,
        	113, 207, 185, 207, 239,
        	142, 927, 96, 927, 141,
        	158, 966, 92, 966, 145,
        	171, 142, 36, 142, 93,	//15
        	182, 1062, 91, 1062, 146,
        	193, 517, 191, 517, 250,
        	201, 862, 8, 862, 58,
        	216, 1304, 18, 1304, 67,
        	261, 1440, 88, 1440, 133,	//20
        	264, 253, 46, 253, 85,	
        	281, 1227, 94, 1227, 163,
        	394, 1019, 134, 1019, 191,
        	402, 1202, 97, 1202, 160,
        	420, 967, 156, 967, 198		//25
        	

		
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

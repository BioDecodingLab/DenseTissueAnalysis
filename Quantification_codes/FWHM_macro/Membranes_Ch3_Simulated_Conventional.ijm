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
			94, 1190, 132, 1231, 132,
        	167, 878, 57, 878, 88,
        	139, 1107, 68, 1107, 106,
        	42, 1600, 230, 1600, 255,
        	18, 1208, 285, 1267, 285, 	//5
        	199, 466, 143, 496, 143,
        	186, 465, 359, 465, 397,
        	176, 1184, 298, 1184, 338,
        	138, 562, 359, 612, 359,
        	115, 965, 463, 1018, 463,	//10	
        	48, 607, 358, 654, 358,
        	233, 878, 411, 913, 411,
        	83, 1298, 395, 1341, 395,
        	186, 483, 563, 483, 624,
        	151, 1136, 413, 1136, 454,	//15
        	203, 576, 521, 576, 557,
        	35, 996, 558, 1043, 558,
        	173, 711, 517, 770, 517,
        	173, 1510, 687, 1510, 724,
        	57, 1028, 710, 1028, 757,	//20
        	152, 843, 849, 905, 849,
        	57, 300, 541, 300, 590,
        	26, 450, 724, 450, 775,
        	206, 1353, 823, 1353, 874,
        	89, 961, 266, 961, 333	 	//25

                                 
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
        	103, 1161, 66, 1161, 121,
       		112, 896, 124, 896, 185,
        	155, 1117, 105, 1117, 146,
        	160, 1625, 16, 1625, 65,
			228, 1234, 89, 1234, 138,		//5
			100, 442, 171, 442, 227,
			264, 456, 151, 456, 218,
			264, 1243, 139, 1243, 210,
			360, 567, 146, 567, 219,
			396, 1039, 84, 1039, 143,	//10
			375, 667, 12, 667, 79,
			393, 944, 193, 944, 260,	
			405, 1269, 41, 1269, 88,
			399, 549, 149, 549, 221,	
			483, 1043, 115, 1043, 188,		//15
			489, 615, 153, 615, 227,
			540, 984, 122, 984, 167,
			583, 1404, 69, 1404, 140,
			655, 1479, 143, 1479, 210,
			735, 1025, 22, 1025, 84, 	//20
			873, 606, 118, 606, 176,	
			527, 491, 183, 491, 256,
			849, 434, 76, 434, 123,
			851, 1594, 176, 1594, 235,	
			490, 1421, 16, 1421, 79		//25
	

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

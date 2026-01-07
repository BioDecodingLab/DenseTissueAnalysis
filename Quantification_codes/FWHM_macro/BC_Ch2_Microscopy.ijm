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
        	31, 620, 493, 620, 549,
		    27, 850, 171, 850, 221,
		    36, 704, 676, 764, 676,
		    28, 487, 483, 487, 514,
		    48, 716, 308, 763, 308,
		    65, 1065, 671, 1065, 703,
		    78, 516, 567, 560, 567,
		    94, 1219, 360, 1219, 400,
		    88, 944, 687, 944, 721,
		    109, 1184, 488, 1184, 537,
		    108, 531, 638, 577, 638,
		    130, 556, 130, 597, 130,
		    154, 555, 438, 555, 488,
		    150, 1034, 545, 1034, 581,
		    156, 620, 403, 620, 378,
		    168, 437, 702, 437, 751,    //16
		    194, 510, 685, 510, 719,
		    204, 1381, 263, 1381, 303,
		    205, 693, 715, 693, 754,
		    205, 443, 338, 443, 386,    //20
		    220, 927, 659, 956, 659,
		    243, 1257, 620, 1257, 647,
		    119, 670, 136, 670, 177,
		    138, 1320, 660, 1320, 700,
		    114, 373, 770, 373, 810     //25
                                 
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
        	521, 616, 0, 616, 61,
			197, 841, 1, 841, 65,
			674, 818, 2, 818, 59,			
			500, 489, 0, 489, 53,
			312, 607, 56, 607, 121,  	//5
			688, 1070, 30, 1070, 99,		
			570, 626, 82, 626, 177,    
			382, 1216, 63, 1216, 125,			
			706, 952, 49, 952, 120,
			514, 1178, 64, 1178, 152,	//10	
			640, 773, 14, 773, 84,		
			134, 312, 0, 312, 41,
			463, 561, 130, 561, 176,
			564, 1036, 110, 1036, 187,
			392, 583, 124, 583, 188,	//15
			724, 369, 185, 369, 254,
			703, 502, 163, 502, 231,
			295, 1538, 63, 1538, 13,
			735, 690, 170, 690, 240,
			363, 441, 174, 441, 240,	//20
			659, 943, 4, 943, 65,
			638, 1391, 20, 1391, 76,
			157, 669, 93, 669, 141,
			680, 1329, 110, 1329, 167,
			790, 359, 83, 359, 149
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

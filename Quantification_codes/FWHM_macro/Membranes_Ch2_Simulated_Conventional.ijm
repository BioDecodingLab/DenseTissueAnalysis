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
				8, 619, 322, 619, 365,
				27, 727, 560, 727, 585,
				27, 970, 213, 970, 238,
				36, 716, 638, 716, 670,
				36, 705, 684, 765, 684,  //5
				100, 529, 634, 575, 634,
				168, 437, 702, 437, 751, // el 16xz
				204, 430, 327, 477, 327,
				39, 511, 416, 511, 452,
				71, 1063, 673, 1063, 700, //10
				78, 519, 564, 551, 564,
				43, 1150, 589, 1198, 609,
				120, 631, 318, 631, 361,
				137, 461, 343, 483, 391,
				144, 681, 168, 681, 208, //15
				181, 568, 388, 613, 369,
				181, 498, 181, 507, 226,
				191, 987, 130, 1054, 130,
				211, 768, 412, 812, 438,
				237, 440, 555, 482, 555,   //20
				253, 584, 384, 609, 406,	
				264, 1025, 399, 1025, 452,
				152, 796, 737, 796, 791,
				181, 865, 626, 888, 606,
				135, 451, 350, 471, 390  //25
			

                                 
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
		 	515, 635, 180, 635, 225,
			194, 843, 1, 844, 57,
			457, 1239, 79, 1239, 138,
			711, 292, 97, 292, 150,
			439, 653, 154, 653, 206, //5
			136, 1050, 87, 1050, 144,	
			651, 1106, 135, 1106, 183,
			681, 378, 30, 378, 73,
			137, 607, 44, 607, 109,
			296, 983, 162, 983, 217, //10
			337, 853, 183, 853, 222,
			571, 806, 58, 806, 109,
			653, 1251, 121, 1251, 169,
			391, 1138, 136, 1138, 201,
			520, 420, 185, 420, 235,	//15
			549, 1077, 63, 1077, 108,
			552, 1034, 22, 1034, 57,
			580, 1018, 75, 1018, 144,
			622, 598, 83, 598, 126,
			590, 1081, 0, 1081, 52,		//20
			799, 1279, 207, 1279, 265,
			774, 490, 86, 490, 134,
			795, 668, 132, 668, 189,
			687, 667, 141, 667, 202,
			614, 634, 127, 634, 163		 //25
			
						

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

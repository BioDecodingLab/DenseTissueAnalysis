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
			25, 727, 560, 727, 585,
			29, 850, 181, 850, 210,
			29, 716, 638, 716, 670,
			36, 705, 684, 765, 684,  //5
			100, 529, 634, 575, 634,
			168, 437, 702, 437, 751, // el 16xz
			205, 443, 338, 443, 386, // el 20xz
			32, 511, 416, 511, 452,
			66, 1063, 673, 1063, 700, //10
			74, 519, 564, 551, 564,
			37, 1150, 589, 1198, 609,
			120, 631, 318, 631, 361,
			132, 461, 343, 483, 391,
			144, 671, 168, 671, 208, //15
			181, 568, 388, 613, 369,
			181, 498, 181, 507, 226,
			191, 987, 130, 1054, 130,
			211, 768, 412, 812, 438,
			237, 440, 555, 482, 555,   //20
			249, 584, 384, 609, 406,
			264, 1013, 398, 1013, 451,
			152, 796, 737, 796, 791,
			181, 845, 613, 868, 593,
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
		 	521, 626, 0, 626, 61,
			197, 843, 1, 844, 57,
			455, 1229, 87, 1229, 135,
			710, 286, 105, 286, 146,
			459, 1078, 78, 1078, 130, //5
			134, 312, 0, 312, 41,
			659, 936, 21, 936, 50,
			680, 378, 30, 378, 73,
			527, 791, 75, 791, 138,
			310, 599, 69, 599, 118, //10
			301, 347, 20, 347, 71,
			555, 652, 95, 652, 150,
			348, 922, 30, 922, 88,
			372, 628, 118, 628, 179,
			419, 999, 44, 999, 3, 	//15
			518, 1057, 9, 1057, 60,
			575, 269, 45, 269, 100,  
			573, 706, 5, 706, 45,
			619, 597, 37, 597, 80,
			593, 495, 8, 495, 65,	//20
			815, 686, 156, 686, 202,
			775, 484, 94, 484, 132,
			773, 289, 10, 289, 56,
			640, 780, 22, 780, 69,
			639, 392, 76, 392, 139 //25
				

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

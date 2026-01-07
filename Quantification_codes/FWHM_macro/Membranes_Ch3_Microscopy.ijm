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
        	90, 722, 0, 722, 19,
        	154, 1208, 16, 1208, 0,
        	58, 1098, 22, 1098, 46,        	
			26, 1556, 49, 1556, 76,			
			140, 1102, 72, 1102, 103,	//5
			106, 1030, 105, 1030, 134,
			104, 884, 115, 884, 144,
			80, 761, 236, 761, 260,
			166, 998, 716, 1011, 739,
			46, 656, 359, 656, 395,		//10
			227, 1222, 327, 1222, 372,
			119, 666, 555, 679, 534,
			202, 1162, 415, 1162, 440,
			242, 1077, 104, 1077, 149,
			33, 786, 665, 815, 675,		//15
			79, 770, 270, 770, 230,
			190, 722, 608, 747, 595,
			29, 390, 768, 431, 768,
			247, 1145, 452, 1202, 452,
			181, 749, 570, 774, 521,	//20
			126, 633, 550, 662, 516,
			105, 1205, 312, 1275, 312,
			70, 600, 596, 600, 633,
			61, 890, 594, 915, 543,
			169, 641, 356, 706, 356		//25			
                                 
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
        		6, 1219, 24, 1219, 74,
				13, 699, 50, 699, 108,
				11, 1216, 121, 1216, 190,
				35, 1100, 34, 1100, 80,
				64, 1556, 1, 1556, 50,		//5
				121, 1039, 82, 1039, 135,
				131, 887, 73, 887, 134,
				251, 763, 45, 763, 114,
				377, 667, 12, 667, 79,			
				396, 919, 12, 919, 53,	//10
				397, 1043, 77, 1043, 145,
				473, 1053, 41, 1053, 96,
				546, 557, 61, 557, 118,
				738, 1030, 19, 1030, 81,
				871, 723, 55, 723, 106,	//15
				20, 674, 25, 674, 62,
				356, 866, 10, 866, 43,
				429, 427, 92, 427, 39,
				562, 307, 8, 307, 35,
				643, 324, 80, 324, 47,	//20
				72, 535, 63, 535, 116,
				423, 1484, 24, 1484, 62,
				320, 287, 19, 287, 56,
				257, 903, 22, 903, 70,
				527, 294, 30, 294, 74	 //25
				

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

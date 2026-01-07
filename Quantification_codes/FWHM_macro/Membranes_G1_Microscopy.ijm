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
        	171, 603, 46, 603, 68,
        	133, 354, 51, 354, 73,
        	57, 962, 54, 962, 79,    
        	75, 312, 130, 312, 155,
        	44, 364, 132, 364, 153,		//5
        	121, 744, 139, 744, 166,
        	58, 1176, 129, 1196, 129,	
        	55, 1110, 158, 1120, 172,
        	230, 437, 158, 437, 181,        
        	143, 521, 235, 521, 253,	//10
        	151, 647, 264, 647, 283,
        	42, 511, 309, 511, 325,
        	109, 1166, 233, 1166, 251,
        	43, 819, 363, 842, 363,
        	17, 284, 318, 298, 324,		//15
        	35, 914, 14, 933, 14,
        	35, 1042, 396, 1042, 373,	
        	69, 582, 651, 582, 669,
        	70, 1032, 779, 1032, 763,
        	88, 233, 98, 244, 104,		//20
        	95, 1319, 165, 1334, 165,
        	103, 1016, 223, 1016, 238,	
        	105, 990, 437, 1002, 437,
        	114, 933, 689, 933, 674,
        	185, 837, 826, 837, 848		//25                          
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

	        	67, 962, 28, 962, 87,	    
	        	128, 159, 173, 159, 234,	 
	        	145, 359, 11, 359, 78,
	        	164, 1137, 21, 1137, 88,
	       		165, 1215, 21, 1215, 86,		//5
	       		200, 877, 28, 877, 77,	     	       		
	       		317, 655, 48, 655, 97,
	       		318, 513, 19, 513, 59,
				379, 1144, 81, 1144, 142,
	        	387, 939, 5, 939, 78,		//10
				491, 426, 105, 426, 149,
				635, 1243, 133, 1243, 176,
	        	774, 837, 99, 837, 158,	
	        	830, 617, 46, 617, 89,
	        	831, 199, 6, 199, 47,	//15
	        	833, 527, 25, 527, 60,	
	        	766, 1338, 1, 1338, 60,
	        	638, 1115, 95, 1115, 162,
	        	637, 493, 75, 493, 132,
	        	590, 1090, 71, 1090, 104,	//20
	        	767, 458, 61, 458, 104,
	        	709, 894, 170, 894, 223,
	        	706, 467, 30, 467, 77,
	        	665, 927, 104, 927, 159,
	        	805, 269, 11, 269, 68		//25

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

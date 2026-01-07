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
        	35, 592, 9, 592, 50,
        	177, 844, 90, 844, 137, 
        	110, 929, 605, 929, 652,
        	90, 1260, 806, 1260, 854,
        	182, 424, 82, 424, 125,		//5 
        	113, 9, 806, 56, 806,	
        	121, 939, 643, 985, 643,
        	80, 1302, 50, 1302, 116,
        	75, 1174, 766, 1174, 823,
        	49, 461, 29, 461, 84,	//10 
        	37, 928, 225, 981, 225,
        	140, 850, 281, 850, 341,
        	119, 1050, 273, 1050, 322,
        	128, 406, 804, 465, 804,       	        	
        	102, 1289, 334, 1341, 334,	//15
        	79, 1147, 334, 1147, 389,
			95, 964, 374, 964, 427,
			66, 928, 433, 992, 433,
			96, 1113, 156, 1113, 223,    
			89, 402, 738, 402, 783,		//20
			80, 678, 548, 678, 598,
			173, 904, 588, 963, 588,
			48, 1143, 633, 1200, 633,
			162, 1256, 672, 1256, 725,
			100, 861, 728, 922, 728	//25
			
			
        	

                                 
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
			30, 591, 5, 591, 62,
        	115, 843, 151, 843, 206, 
        	627, 930, 74, 930, 144,
        	831, 1259, 45, 1259, 132,
        	105, 424, 156, 424, 205,		//5 
        	808, 33, 81, 33, 143,	 
        	644, 961, 93, 961, 147, 
        	85, 1302, 44, 1302, 116,
        	796, 1174, 37, 1174, 111,
			58, 461, 13, 461, 83,    //10
			228, 956, 0, 956, 70,
			314, 850, 104, 850, 177,
			300, 1050, 81, 1050, 155,
			804, 434, 91, 434, 162,
			337, 1315, 68, 1315, 135,	//15
			364, 1148, 43, 1148, 110,
			402, 964, 66, 964, 128,
			433, 959, 33, 959, 95,
			191, 1114, 57, 1114, 134, 
			760, 402, 54, 402, 116,		//20
			576, 680, 44, 680, 117,
			589, 932, 151, 932, 204,
			635, 1172, 7, 1172, 89,
			700, 1257, 132, 1257, 189,
			729, 893, 59, 893, 136		//25
		
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

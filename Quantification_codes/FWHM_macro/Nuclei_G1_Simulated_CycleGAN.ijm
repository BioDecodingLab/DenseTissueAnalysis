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
        	153, 623, 0, 623, 51,
        	161, 525, 95, 580, 95,
        	120, 328, 688, 404, 688,
        	104, 290, 850, 251, 851,
        	71, 1078, 311, 1078, 382,		//5 
        	72, 1029, 815, 1087, 815,	
        	120, 937, 643, 986, 643,
        	96, 600, 77, 672, 77,
        	92, 620, 784, 620, 839,
        	141, 119, 177, 119, 225,	//10 
        	61, 164, 106, 164, 151,
        	221, 451, 274, 452, 342,
        	143, 582, 299, 642, 299,
        	108, 614, 51, 683, 51,     	        	
        	105, 205, 6, 205, 57,	//15 
        	37, 884, 315, 884, 367,
			103, 782, 265, 782, 315,
			108, 692, 418, 692, 477,
			161, 553, 115, 553, 71, 
			89, 401, 728, 402, 792,		//20
			107, 1518, 584, 1518, 644,
			175, 903, 589, 970, 589,
			86, 594, 593, 594, 650,
			100, 549, 735, 549, 788,
			70, 351, 748, 351, 800	//25
			
			
        	

                                 
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
			26, 625, 111, 625, 189,
        	96, 552, 122, 552, 197, 
        	687, 365, 81, 365, 159,
        	851, 273, 71, 273, 134, 
        	350, 1077, 38, 1077, 103,	//5 
        	815, 1059, 29, 1059, 111,	 
        	643, 961, 85, 961, 154, 
        	78, 635, 62, 635, 131,
        	813, 620, 62, 620, 121, 
			203, 119, 104, 119, 177,   //10
			130, 163, 27, 163, 92, 
			311, 451, 178, 451, 256,
			301, 612, 110, 612, 180,
			51, 649, 70, 649, 148,
			33, 204, 73, 204, 138,   //15
			342, 883, 3, 884, 71, 
			289, 782, 68, 782, 136,
			449, 692, 67, 692, 142,
			97, 553, 131, 553, 195, 
			763, 402, 41, 402, 133,		//20
			619, 1519, 63, 1519, 146,
			588, 932, 134, 932, 217,
			622, 593, 48, 593, 119,
			763, 550, 66, 550, 132,
			775, 350, 34, 350, 100		//25
		
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

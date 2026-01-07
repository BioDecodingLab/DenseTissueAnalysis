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
				
			54, 1001, 427, 1001, 502,
			63, 1079, 646, 1079, 689,
			57, 522, 537, 533, 556,
			67, 1220, 317, 1220, 360,								
			59, 953, 355, 964, 374,	//5
			87, 638, 637, 638, 672,
			80, 866, 399, 885, 412,		
			150, 1067, 718, 1098, 718,
			58, 1089, 728, 1108, 750,
			121, 1404, 748, 1404, 782,		//10
			44, 1333, 345, 1333, 368,
			215, 1191, 467, 1226, 449,
			43, 1225, 86, 1225, 120,
			6, 435, 738, 484, 738,
			169, 893, 134, 893, 187,	//15
	     	148, 1529, 89, 1543, 110,
 			210, 738, 300, 798, 300,
 			147, 431, 287, 476, 287,
 			216, 924, 128, 924, 160,
			186, 436, 535, 471, 535,		//20			
		    98, 781, 132, 781, 165,		
 			240, 1590, 23, 1590, 74,
 			112, 201, 204, 201, 275,
			72, 642, 463, 642, 518,
			79, 637, 373, 637, 426		//25
                            
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
        	47, 1515, 116, 1515, 175, 
        	280, 669, 159, 669, 255,
        	341, 481, 107, 481, 180,
			106, 1009, 186, 1009, 250,
        	104, 839, 65, 839, 126,   //5
        	124, 1523, 212, 1523, 257,
        	124, 61, 72, 61, 153,
        	65, 638, 135, 638, 201,
        	55, 971, 93, 971, 157,
        	78, 1598, 159, 1598, 240,	//10
        	95, 563, 2, 563, 61,
        	96, 84, 100, 84, 153,
        	79, 713, 35, 713, 92,
        	142, 1458, 185, 1458, 236,
        	140, 674, 1, 674, 46,		//15	
        	169, 1144, 136, 1144, 203,
        	193, 517, 191, 517, 250,	
        	160, 1100, 58, 1100, 135,		
        	216, 1304, 18, 1304, 67,	
        	167, 717, 205, 717, 262,	//20
        	184, 1119, 49, 1119, 115,		
        	264, 985, 6, 985, 61,
        	445, 370, 118, 370, 197,
        	476, 849, 152, 849, 203,
        	568, 1134, 39, 1134, 98		//25
        	

		
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

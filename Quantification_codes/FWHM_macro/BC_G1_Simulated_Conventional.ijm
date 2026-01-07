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
        	178, 540, 57, 540, 81,
        	179, 543, 49, 543, 82,
        	133, 354, 51, 354, 73,
        	57, 962, 54, 962, 79,
        	196, 459, 93, 459, 114,		//5
        	205, 160, 117, 160, 136,
        	75, 312, 130, 312, 155,
        	44, 364, 132, 364, 153,
        	121, 744, 139, 744, 166,
        	58, 1176, 129, 1196, 129,	//10
        	55, 1110, 158, 1120, 172,
        	230, 437, 158, 437, 181,
        	145, 1559, 169, 1559, 193,
        	230, 1064, 46, 1064, 91,
        	133, 898, 198, 898, 211,	//15
        	50, 893, 192, 893, 209,
        	142, 1118, 217, 1118, 240,	
        	134, 566, 163, 597, 163,
        	149, 625, 248, 652, 248,
        	194, 793, 274, 793, 292,	//20
        	44, 511, 309, 511, 325,
        	112, 1171, 229, 1179, 245,
        	43, 819, 363, 842, 363,
        	89, 797, 392, 797, 412,
        	130, 838, 758, 838, 787		//25
        	       	        	
 
                                 
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
        	67, 540, 149, 540, 206,
        	57, 609, 134, 609, 210,
        	64, 353, 96, 353, 160,
        	67, 962, 28, 962, 87,
        	103, 456, 158, 456, 227,	 //5
        	128, 159, 173, 159, 234,	
        	144, 309, 43, 309, 110,
        	144, 362, 12, 362, 73,
        	153, 743, 87, 743, 152,
        	163, 1212, 20, 1212, 85,	//10
        	164, 1137, 21, 1137, 88,
        	171, 441, 202, 441, 252,
        	177, 1186, 173, 1186, 224,
        	198, 997, 209, 997, 258,
        	205, 896, 107, 896, 156,	//15	
        	199, 885, 17, 885, 88,
        	224, 1138, 106, 1138, 171,
        	244, 522, 113, 522, 169,
        	259, 615, 124, 615, 167,
        	313, 842, 166, 842, 219,	//20
        	315, 520, 25, 520, 65,
        	369, 1161, 85, 1161, 140,	
        	387, 942, 4, 942, 77,
        	401, 798, 53, 798, 120,
        	773, 843, 96, 843, 156	//25
        	
        	
		
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

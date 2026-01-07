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
        	125, 717, 46, 717, 103,	
      		57, 506, 0, 506, 37,
      		183, 913, 4, 913, 56, 
      		221, 1180, 104, 1233, 104,
      		132, 963, 353, 1007, 353,		//5 
      		90,	578, 12, 578, 64,
      		103, 712, 75, 712, 138, 
      		132, 361, 819, 361, 860,		
      		43, 431, 812, 431, 860,		
      		144, 66, 238, 111, 238,	//10 
      		66, 114, 126, 205, 126,
      		85, 887, 80, 887, 131,
      		235, 1260, 475, 1260, 517,
      		56, 583, 83, 583, 130,
      		243, 1148, 212, 1148, 256,		//15 
      		135, 1073, 464, 1073, 514,
      		146, 1026, 123, 1026, 165,
      		185, 1305, 71, 1305, 116,
      		225, 940, 220, 940, 271,
      		76, 1417, 23, 1417, 70,	//20 
      		227, 1007, 124, 1006, 189,
      		55, 584, 85, 584, 129,
      		70, 326, 273, 371, 273,
      		48, 364, 195, 364, 240,
      		66, 1360, 610, 1423, 610		//25
                                 
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
        	75, 717, 93, 717, 157,
        	21, 505, 23, 505, 89,
        	30, 913, 151, 913, 213,
            107, 1207, 189, 1207, 254,
        	356, 984, 100, 984, 154,		//5
        	38, 577, 51, 577, 129,
        	108, 712, 59, 712, 137,
        	843, 360, 100, 360, 160,
        	836, 432, 5, 432, 76,
        	239, 87, 114, 87, 176,	//10
        	128, 160, 28, 160, 99, 
        	106, 886, 53, 886, 111,
        	496, 1260, 208, 1260, 262,
        	107, 584, 27, 584, 83,
        	236, 1148, 211, 1148, 270, 		//15
        	493, 1074, 104, 1074, 164, 
        	145, 1025, 118, 1025, 170,
        	94, 1304, 155, 1304, 212,
        	244, 939, 198, 939, 251,
        	46, 1417, 45, 1417, 104,	//20
        	157, 1007, 187, 1007, 266, 
        	107, 584, 25, 584, 85,
        	276, 349, 40, 349, 101,
        	219, 362, 18, 362, 77,
        	611, 1390, 29, 1390, 101		//25  

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

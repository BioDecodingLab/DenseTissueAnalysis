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
        	116, 1167, 590, 1167, 631,
        	139, 929, 69, 979, 69,
			103, 1516, 82, 1516, 130,
			74, 1330, 49, 1330, 93,
			111, 259, 84, 259, 135,	//5
			148, 1235, 146, 1235, 197,
			66, 233, 129, 233, 181,
			177, 905, 112, 905, 167,
			157, 799, 108, 799, 165,
			127, 1176, 110, 1176, 155,	//10
			105, 1044, 70, 1044, 113,
			181, 429, 38, 429, 103,
			145, 974, 253, 974, 313,			
			129, 725, 410, 725, 453,	 
			136, 1257, 351, 1257, 397,	//15 
			82, 796, 166, 796, 225,	
			55, 191, 342, 240, 342, 
			108, 464, 407, 464, 468,
			135, 1257, 352, 1257, 397,
			118, 1036, 448, 1036, 503, //20
			106, 1164, 397, 1227, 397, 
			150, 589, 468, 651, 468,
			171, 975, 542, 975, 593,
			214, 1161, 590, 1213, 590,
			74, 584, 271, 645, 271 	//25
                                 
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
			72, 954, 107, 954, 168,
			81, 433, 42, 433, 103,
			105, 1516, 70, 1516, 131,
			70, 1329, 44, 1329, 103,
			111, 260, 80, 260, 140,		//5 
			173, 1235, 117, 1235, 179, 
			155, 233, 30, 233, 93,
			143, 904, 149, 904, 204,
			136, 799, 128, 799, 182,
			132, 1176, 100, 1176, 155,		//10
			93, 1044, 77, 1044, 135,
			202, 439, 149, 439, 207,
			284, 975, 113, 975, 181,	
			433, 725, 102, 725, 155,
			376, 1257, 102, 1257, 167, 	//15
			198, 797, 44, 797, 117, 
			344, 216, 21, 216, 87, 
			438, 464, 76, 464, 140, 
			375, 1258, 101, 1258, 170,
			478, 1035, 86, 1035, 147,	//20
			398, 1196, 69, 1196, 142, 
			469, 622, 112, 622, 183,
			568, 974, 132, 974, 209,
			592, 1184, 178, 1184, 248,
			271, 615, 39, 615, 105		//25 

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

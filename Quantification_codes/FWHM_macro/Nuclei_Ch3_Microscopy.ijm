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
	    	183, 864, 406, 864, 466,
			171, 325, 397, 392, 397,
			88, 453, 78, 453, 3,
			149, 542, 340, 542, 418,
			54, 95, 85, 95, 159,	//5
			65, 66, 122, 66, 179,
			67, 231, 124, 231, 187,
			181, 901, 115, 901, 170,
			157, 796, 110, 796, 167,
			129, 1146, 132, 1201, 132,	//10
			100, 384, 184, 461, 184,
			184, 438, 167, 438, 225,
			78, 670, 389, 736, 389,			
			51, 643, 810, 643, 870,	 
			215, 583, 387, 583, 448,	//15
			192, 1081, 393, 1081, 456,	
			113, 902, 405, 902, 458,
			111, 464, 409, 464, 470,
			136, 1227, 375, 1288, 375,
			119, 1035, 449, 1035, 504, //20
			219, 979, 480, 979, 529,
			41, 1027, 449, 1027, 496,
			170, 973, 544, 973, 595,
			229, 967, 526, 1046, 526,
			109, 742, 772, 742, 835 	//25
                                 
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
			438, 867, 131, 867, 227,
			399, 359, 124, 359, 204,
			44, 450, 33, 450, 144,
			385, 545, 102, 545, 185,
			123, 95, 96, 95, 11,		//5
			152, 64, 21, 64, 104,
			157, 232, 28, 232, 105,
			141, 905, 135, 905, 224,
			140, 798, 116, 798, 197,
			132, 1175, 92, 1175, 163,		//10
			186, 421, 55, 421, 146,
			196, 438, 140, 438, 227,
			392, 702, 115, 702, 32,	
			841, 643, 10, 643, 83,
			421, 583, 176, 583, 245, 	//15
			423, 1079, 151, 1079, 231,
			435, 903, 80, 903, 143,
			434, 464, 67, 464, 155,
			380, 1255, 96, 1255, 173,
			472, 1034, 88, 1034, 149,	//20
			506, 981, 174, 981, 253,
			480, 1029, 6, 1029, 76,
			571, 974, 132, 974, 209,
			524, 1007, 185, 1007, 258,
			803, 743, 72, 743, 143		//25

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

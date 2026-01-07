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
			98, 611, 33, 670, 33,
			172, 540, 37, 602, 37,
			139, 1365, 81, 1365, 30,
			65, 1263, 77, 1263, 33,
			226, 1121, 147, 1121, 97,	//5
			98, 420, 162, 420, 86,
			176, 374, 151, 374, 211,
			43, 307, 132, 307, 182,
			227, 1123, 90, 1123, 155,
			99, 420, 90, 420, 158,		//10
			112, 1035, 160, 1035, 228,
			88, 1175, 234, 1175, 275,
			64, 964, 318, 964, 372,
			84, 743, 323, 743, 380,
			181, 531, 355, 531, 423,  //15
			122, 1068, 412, 1068, 469,
			115, 455, 459, 455, 522,
			96, 890, 456, 890, 518,
			140, 1204, 468, 1204, 523,
			165, 641, 489, 641, 562,	//20
			120, 834, 560, 834, 617,
			93, 1286, 570, 1286, 621,
			151, 1233, 655, 1233, 715,
			75, 855, 613, 855, 672,
			242, 742, 730, 742, 785		//25
                                 
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
			30, 639, 154, 639, 46,		
			38, 571, 205, 571, 133,
			60, 1365, 176, 1365, 86,
			56, 1265, 107, 1263, 23,
			129, 1122, 265, 1122, 189,	//5
			133, 420, 148, 420, 47,
			186, 373, 218, 373, 136,
			160, 308, 5, 308, 80,
			130, 1122, 267, 1122, 179,
			127, 420, 46, 420, 144,		//10
			196, 1036, 61, 1036, 160,
			257, 1175, 38, 1175, 131,
			347, 966, 111, 966, 15,
			353, 742, 38, 742, 134,
			391, 529, 231, 529, 131,	//15
			444, 1069, 82, 1069, 164,
			492, 456, 64, 456, 162,
			489, 890, 45, 890, 146,
			499, 1204, 90, 1204, 188,
			528, 640, 218, 640, 109,	//20
			591, 835, 64, 835, 177,
			598, 1285, 55, 1285, 132,
			685, 1231, 110, 1231, 191,
			644, 855, 29, 855, 115,
			762, 743, 271, 743, 197		//25
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

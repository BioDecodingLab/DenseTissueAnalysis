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
			221, 1161, 86, 1161, 158,
			130, 419, 338, 475, 338,
			139, 1365, 81, 1365, 30,
			65, 1263, 77, 1263, 33,
			226, 1121, 147, 1121, 97,	//5
			98, 420, 162, 420, 86,
			176, 374, 151, 374, 211,
			43, 307, 132, 307, 182,
			227, 1123, 90, 1123, 155,
			84, 467, 86, 467, 163,		//10
			112, 1035, 160, 1035, 228,
			85, 1176, 228, 1176, 283,
			151, 971, 829, 1014, 829,
			84, 743, 323, 743, 380,
			181, 531, 355, 531, 423,  //15
			122, 1068, 412, 1068, 469,
			115, 455, 459, 455, 522,
			96, 890, 456, 890, 518,
			140, 1204, 468, 1204, 523,
			165, 641, 489, 641, 562,	//20
			120, 834, 560, 834, 617,
			43, 1134, 564, 1134, 621,
			49, 586, 790, 649, 790,
			75, 855, 613, 855, 672,
			238, 742, 730, 742, 785		//25
                                 
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
			125, 1162, 266, 1162, 175,		
			340, 449, 78, 449, 179,
			56, 1365, 177, 1365, 87,
			55, 1262, 107, 1260, 23,
			124, 1125, 177, 1125, 268,	//5
			134, 418, 147, 418, 46,
			184, 373, 218, 373, 136,
			160, 308, 5, 308, 80,
			126, 1124, 266, 1124, 178,
			127, 465, 41, 465, 126,		//10
			197, 1035, 154, 1035, 62,
			830, 990, 112, 990, 189,
			346, 966, 111, 966, 15,
			350, 744, 32, 744, 128,
			391, 534, 230, 534, 130,	//15
			444, 1069, 82, 1069, 164,
			492, 456, 64, 456, 162,
			489, 890, 45, 890, 146,
			499, 1204, 90, 1204, 188,
			529, 642, 217, 642, 108,	//20
			591, 835, 64, 835, 177,
			592, 1133, 82, 1133, 6,
			791, 618, 7, 618, 86,
			644, 856, 29, 856, 115,
			760, 743, 271, 743, 197		//25
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

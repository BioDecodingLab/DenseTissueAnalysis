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
			96, 482, 31, 557, 31,
			171, 522, 36, 620, 36,		
			137, 1330, 54, 1400, 54,
			194, 820, 664, 820, 743,
			226, 1119, 86, 1119, 159,	//5
			98, 419, 92, 419, 155,		
			140, 584, 145, 584, 206,
			41, 307, 129, 307, 186,		
			224, 1121, 81, 1121, 166,
			98, 419, 92, 419, 161,		//10
			112, 1036, 160, 1036, 225,
			86, 1174, 227, 1174, 283,
			62, 966, 316, 966, 373,
			83, 742, 321, 742, 380,
			179, 530, 352, 530, 422,  //15
			114, 455, 454, 455, 527,
			36, 467, 469, 556, 469,
			96, 890, 456, 890, 518,
			217, 783, 637, 783, 718,
			162, 640, 492, 640, 563,	//20
			119, 834, 561, 834, 617,
			93, 1285, 566, 1285, 629,
			147, 1232, 653, 1232, 713,
			72, 856, 611, 856, 675,
			239, 743, 720, 743, 799		//25
                                 
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
			32, 518, 56, 518, 131,		
			37, 572, 135, 572, 205,
			31, 640, 53, 640, 142,
			706, 820, 142, 820, 242,		
			129, 1122, 265, 1122, 189,	//5
			133, 420, 148, 420, 47,
			178, 587, 110, 587, 173,
			160, 308, 5, 308, 80,
			130, 1122, 267, 1122, 179,
			127, 420, 46, 420, 144,		//10
			196, 1036, 61, 1036, 160,
			257, 1175, 38, 1175, 131,
			347, 966, 111, 966, 15,
			353, 744, 36, 744, 132,
			391, 529, 231, 529, 131,	//15
			405, 500, 85, 500, 163,
			472, 508, 1, 508, 73,
			489, 890, 45, 890, 146,
			680, 782, 170, 782, 263,
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

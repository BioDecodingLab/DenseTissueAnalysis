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
			90, 723, 0, 723, 17,
			154, 1208, 16, 1208, 0,
			66, 1098, 22, 1098, 46,
			26, 1556, 49, 1556, 76,
			140, 1100, 71, 1100, 102,	//5
			106, 1030, 105, 1030, 134,
			104, 884, 115, 884, 144,
			80, 761, 236, 761, 260,
			174, 893, 275, 893, 306,
			46, 666, 358, 666, 394,		//10
			229, 944, 373, 944, 413,
			119, 793, 374, 793, 417,
			202, 1167, 415, 1167, 440,
			243, 993, 449, 993, 480,
			33, 786, 665, 815, 675,		//15
			79, 770, 270, 770, 230,
			194, 768, 609, 768, 653,
			248, 707, 442, 707, 494,
			247, 1145, 452, 1202, 452,		//mala
			181, 749, 570, 774, 521,	//20
			126, 633, 550, 662, 516,
			105, 1205, 312, 1275, 312,
			61, 546, 375, 546, 331,
			61, 890, 594, 915, 543,
			169, 641, 356, 706, 356		//25
                                 
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
			 	4, 1226, 30, 1226, 80,
				10, 724, 61, 724, 119,
				8, 1209, 119, 1209, 188,
				33, 1098, 41, 1098, 87,
				64, 1560, 3, 1560, 52,		//5
				88, 1102, 109, 1102, 171,
				120, 1031, 80, 1031, 134,
				130, 887, 73, 887, 134,
				250, 761, 45, 761, 114,
				291, 892, 143, 892, 204,	//10
				375, 667, 12, 667, 79,
				393, 944, 193, 944, 260,
				395, 794, 84, 794, 152,
				429, 1169, 170, 1169, 231,
				467, 982, 215, 982, 272,	//15
				464, 1143, 37, 1143, 101,
				544, 557, 61, 557, 118,
				631, 776, 165, 776, 224,
				657, 867, 163, 867, 216,
				701, 761, 18, 761, 77,	//20
				704, 824, 56, 824, 112,
				715, 748, 170, 748, 233,
				735, 1025, 22, 1025, 84,
				741, 822, 91, 822, 151,
				869, 721, 55, 721, 106  //25
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

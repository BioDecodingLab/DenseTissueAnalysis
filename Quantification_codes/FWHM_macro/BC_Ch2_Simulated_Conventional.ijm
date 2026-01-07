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
			   31, 620, 493, 620, 549,	
			    27, 850, 171, 850, 221,	
			    36, 704, 676, 764, 676,
			    28, 487, 483, 487, 514,
			    48, 716, 308, 763, 308,
			    65, 1065, 671, 1065, 703,
			    78, 516, 567, 560, 567,
			    94, 1219, 360, 1219, 400,
			    88, 944, 687, 944, 721,
			    109, 1184, 488, 1184, 537,
			    105, 531, 638, 577, 638,
			    130, 556, 130, 597, 130,
			    154, 555, 438, 555, 488,
			    150, 1034, 545, 1034, 581,
			    156, 620, 403, 620, 378,
			    168, 437, 702, 437, 751,    //16
			    194, 510, 685, 510, 719,
			    212, 1255, 328, 1255, 368,
			    205, 693, 715, 693, 754,
			    205, 443, 338, 443, 386,    //20		
			    218, 1023, 725, 1023, 759,
			    243, 1257, 620, 1257, 647,
			    119, 670, 136, 670, 177,
			    138, 1320, 660, 1320, 700,
			    117, 373, 770, 373, 810     //25
                                 
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
        	521, 621, 1, 621, 63,
			195, 841, 1, 841, 65,
			674, 814, 6, 814, 63,
			500, 481, 0, 481, 53,
			310, 588, 69, 588, 134,  	//5
			688, 1075, 32, 1075, 101,
			570, 628, 82, 628, 177,    
			381, 1218, 63, 1218, 125,
			706, 952, 49, 952, 120,
			513, 1182, 65, 1182, 153,	//10
			640, 773, 14, 773, 84,		
			132, 322, 0, 322, 40,
			463, 551, 131, 551, 177,
			562, 1036, 110, 1036, 187,
			393, 613, 129, 613, 193,	//15
			722, 423, 130, 423, 212,
			701, 502, 163, 502, 231,
			288, 1312, 164, 1312, 254,
			733, 690, 170, 690, 240,
			363, 441, 174, 441, 240,	//20
			657, 943, 15, 943, 58,
			631, 1239, 213, 1239, 272,
			156, 662, 93, 662, 141,
			680, 1328, 109, 1328, 166,
			790, 370, 83, 370, 149	//25
	
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

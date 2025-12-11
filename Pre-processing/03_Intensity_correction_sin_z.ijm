//run over allimages in folders and subfolders

// Input Data

	extensionIn = ".tif";
  	dir1 = getDirectory("Choose Source Directory ");
  	dir2 = getDirectory("Choose Destination Directory ");
 
  	cropImage = "false";
  	Lxy = 1200;
  	Lz = 200;
	
	Ilow = 0;		//original 10
	Ihigh = 100;	//original 99.99
	nBins = 65536;
  	


// Procesing
  	
  	print("Processing started");
  	//setBatchMode(true);
  	n = 0;
  	processFolder(dir1, dir2, extensionIn, cropImage);
 	print("Processing done");

 
// Functions

	 function processFolder(dir1, dir2, extensionIn, cropImage) {
	 	list = getFileList(dir1);
	    for (i=0; i<list.length; i++) {
	         if (endsWith(list[i], extensionIn))
	            processImage(dir1, dir2, list[i], cropImage);
	     }
	 }

	function processImage(dir1, dir2, name, cropImage) {

   		open(dir1+name);
   		print(i, name);
   		nme = split( name, "." );

   		// Crop image 

  		if(cropImage == "true"){
			selectWindow(name);	
			rename("img");
			Stack.getDimensions(width,height,channels,slices,frames);
			print("Image "+ name + " cropped from : ", width+", "+height+", "+slices);
			x0 = floor((width - Lxy) / 2);
			y0 = floor((height - Lxy) / 2);

			makeRectangle(x0, y0, Lxy, Lxy);
			run("Crop");
			txtcrop =  "channels=1-"+channels+" slices=1-"+Lz;
			run("Make Substack...", txtcrop);

			selectWindow("img");
			close();
			selectWindow("img-1");
			rename(name);
			selectWindow(name);
			Stack.getDimensions(width,height,channels,slices,frames);
  			print("to: ", width+", "+height+", "+slices);
  		}
 
 
		// Code to correct image intensity using Bleach Correction

		// Get max dimension for calculations : 	

		selectWindow(name);			
		Stack.setDisplayMode("grayscale");
		Stack.getDimensions(width,height,channels,slices,frames);
		
		// Narrow down the instnesities (crop the intnesity outliers)

		for (index = 1; index <= channels; index++) {
			Stack.setChannel(index);

			for (z = 1; z < slices; z++) {
				Stack.setSlice(z);
				getHistogram(values, h, nBins+1, 0, nBins);

  				for (i=1; i< h.length; i++)
    				 h[i] = h[i-1]+h[i];
    				 
  				for (i=1; i< h.length; i++)
    				 h[i] = 100 * h[i] / h[h.length -1];

				d = 1e30;
				minI =0;
				h1 = Array.copy(h);
				for (i=1; i< h.length; i++)
					 h1[i] = abs(h[i] - Ilow);
					 
				for (i=1; i< h.length; i++){
					if(h1[i] < d)
					{
						d = h1[i];
						minI = i;
					}
				}
				
				d = 1e30;
				maxI =0;
				h2 = Array.copy(h);
				for (i=1; i< h.length; i++)
					 h2[i] = abs(h[i] - Ihigh);

 				for (i=1; i< h.length; i++){
					if(h2[i] < d)
					{
						d = h2[i];
						maxI = i;
					}
				}
  //				Plot.create("Cumulative Histogram of "+getTitle, "Value", "Sum of pixel count", h);

  				if(z%20 == 0){
					print(z+" -> Min I : "+minI+" , max I :"+maxI);}
					
				factor = (nBins-1) / (maxI - minI);
				run("Max...", "value="+maxI);
				run("Min...", "value="+minI);
				run("Subtract...", "value="+minI);
				run("Multiply...", "value="+factor);			

//				getStatistics(area, mean, min, max, std, histogram);
//				print("New stats : ["+ min+","+max+"]");			
//				updateResults();
			}		
		}
	
		// Calculate Bleach Correction for each channel

		selectWindow(name);		
		Stack.getDimensions(width,height,channels,slices,frames);
		
		/*Bloque original para corrección en Z
		txtConcatenate = "";
		for (index = 1; index <= channels; index++) {
			selectWindow(name);	
			Stack.getDimensions(w0,h0,ch0,d0,nf0);
			txtImg = "channels="+index+" slices=1-"+slices;
			run("Make Substack...", txtImg);
			selectWindow(nme[0]+"-1."+nme[1]);
			rename("temp");
			run("Bleach Correction", "correction=[Histogram Matching]");					
			selectWindow("temp");
			close();
			selectWindow("DUP_temp");	
			rename("Channel"+index);			
			txtConcatenate = txtConcatenate + "c"+index+"=Channel"+index+" ";
		}*/
		//Nievo bloque para no hacer nada en z, pero que no se rompa el macro
		txtConcatenate = "";
		for (index = 1; index <= channels; index++) {
		    selectWindow(name);
		    // Crear substack del canal 'index' (todas las slices)
		    txtImg = "channels="+index+" slices=1-"+slices;
		    run("Make Substack...", txtImg);
		
		    // La subpila creada se nombra automáticamente como: nme[0]+"-1."+nme[1]
		    selectWindow(nme[0]+"-1."+nme[1]);
		    // Renombrar directamente a ChannelX (sin pasar por 'temp' ni 'DUP_temp')
		    rename("Channel"+index);
		
		    // Construir string para Merge Channels
		    txtConcatenate = txtConcatenate + "c"+index+"=Channel"+index+" ";
		}
		
		selectWindow(name);
		close();			
		txtConcatenate = txtConcatenate + "create";
		run("Merge Channels...", txtConcatenate);
		rename("combined");
		selectWindow("combined");
		// to 16 bit
		// setMinAndMax(0, 4095);
		// call("ij.ImagePlus.setDefault16bitRange", 12);
		// run("16-bit");		
		print(name+" corrected");
		selectWindow("combined");
	    saveAs("tif", dir2+nme[0]+"_corrected");
	   	close();
	 }



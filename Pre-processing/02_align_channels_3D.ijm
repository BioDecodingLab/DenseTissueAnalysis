//run over allimages in folders and subfolders

// Input Data

	MinI = 0; // Min Intensity for calculation
	refCh = 5; // Reference Channel number
	max_shift = 30.0; // max shift in x,y and z
	extensionIn = ".tif";
  	path = File.openDialog("Choose a File");
  	dir2 = getDirectory("Choose Destination Directory ");
  	L=256;//Length of the selection square 
  	enhance = false;
  	

// Procesing
  	
  	print("Processing started");
  	processImage(File.getParent(path), dir2, File.getName(path), MinI, refCh, max_shift);
 	print("Processing done");

 
// Functions

	function processImage(dir1, dir2, name, MinI, refCh, max_shift) {

   		open(dir1+"/"+name);
   		print(name);
   		nme = split( name, "." );

		// Code to  align channels to a reference ones (3D)

		// Get max dimension for calculations : ROI (L,L,L) with L = 2^x	
			selectWindow(name);	
			Stack.getDimensions(width,height,channels,slices,frames);
			if(L<3){
			L = GetMaxLen(name);}
			z0 = maxOf(floor((slices-L)/2),0);
			zf = z0+L-1;
			if(z0 < 1) z0 = 1;
			if(zf > slices) zf = slices;
			print(L, " , ",z0, " , ",zf);
		// Calculate drifts in 3D, Resize and Concatenate corrected images
		txtConcatenate = "";
		for (index = 1; index <= channels; index++) {

			selectWindow(name);	
			Stack.getDimensions(w,h,ch,d,nf);
			if(index == refCh){		
				selectWindow(name);		
				txtImg = "channels="+index+" slices=1-"+slices;
				run("Make Substack...", txtImg);
				selectWindow(nme[0]+"-1."+nme[1]);
				rename("Channel"+index);		
			}
			else
				Correct3DdriftChannel(name, index, refCh, z0, zf, L, slices);
				
			selectWindow("Channel"+index);
			Stack.getDimensions(w1,h1,ch1,d1,nf1);
			print("Channel"+index+" from : "+w+","+h+","+ch+","+d+" to :"+w1+","+h1+","+ch1+","+d1);
			txtConcatenate = txtConcatenate + "c"+index+"=Channel"+index+" ";	
		}
			
		txtConcatenate = txtConcatenate + "create";
		run("Merge Channels...", txtConcatenate);
		rename("combined");
		selectWindow(name);
		close();			
		print(name+" aligned");		
	    saveAs("tif", dir2+nme[0]+"_aligned");
	    close();
	 }


	
	function Correct3DdriftChannel(name, index, refCh, z0, zf, L, slices) {

		// Get 3D shift
		selectWindow(name);
		nme = split( name, "." );
		txtImg = "channels="+refCh+","+index+" slices=1-"+slices;
		run("Make Substack...", txtImg);
		selectWindow(nme[0]+"-1."+nme[1]);	
		rename("temp");
		selectWindow("temp");
		Stack.getDimensions(w,h,ch,d,nf);
		run("Re-order Hyperstack ...", "channels=[Frames (t)] slices=[Slices (z)] frames=[Channels (c)]");
		selectWindow("temp");	
		setTool("rectangle");
		makeRectangle(floor((width-L)/2),floor((height-L)/2), L, L);
		if(enhance == true){
		txtCorrect = "channel=1 multi_time_scale sub_pixel edge_enhance only="+MinI+" lowest="+z0+" highest="+zf+" max_shift_x="+max_shift+" max_shift_y="+max_shift+" max_shift_z="+max_shift;	
		}
		else{
		txtCorrect = "channel=1 only="+MinI+" lowest="+z0+" highest="+zf+" max_shift_x="+max_shift+" max_shift_y="+max_shift+" max_shift_z="+max_shift;	
		}		
		selectWindow("temp");
		Stack.getDimensions(w1,h1,ch1,d1,nf1);
		print("Channel"+index+" from : "+w+","+h+","+ch+","+d+" to :"+w1+","+h1+","+ch1+","+d1);
		run("Correct 3D drift", txtCorrect);
		selectWindow("temp");
		close();
		selectWindow("registered time points");
		Stack.getDimensions(w,h,ch,d,nf);
		run("Re-order Hyperstack ...", "channels=[Frames (t)] slices=[Slices (z)] frames=[Channels (c)]");
		Stack.getDimensions(w1,h1,ch1,d1,nf1);
		print("Channel"+index+" from : "+w+","+h+","+ch+","+d+" to :"+w1+","+h1+","+ch1+","+d1);
		rename("Channel_shift"+index);

		// Resize 
		Nx = w-width;
		Ny = h-height;
		Nz = d-slices;
		shift_pos_x = GetShiftX("Channel_shift"+index, width);
		shift_pos_y = GetShiftY("Channel_shift"+index, height);
		shift_pos_z = GetShiftZ("Channel_shift"+index, slices);
		
		
		if(shift_pos_x == "left")  x0 = Nx;
		if(shift_pos_x == "right") x0 = 0;
		if(shift_pos_y == "down")  y0 = Ny;
		if(shift_pos_y == "up")    y0 = 0;	
		selectWindow("Channel_shift"+index);	
		Stack.getDimensions(w,h,ch,d,nf);				
		makeRectangle(x0,y0,width,height);
		run("Crop");				
		
		if(shift_pos_z == "up") txtCrop = "channels=2 slices="+(1+Nz)+"-"+d;
		if(shift_pos_z == "down") txtCrop = "channels=2 slices="+1+"-"+slices;		
		selectWindow("Channel_shift"+index);
		run("Make Substack...", txtCrop);
		Stack.getDimensions(w,h,ch,d,nf);
		selectWindow("Channel_shift"+index+"-1");
		rename("Channel"+index);
		selectWindow("Channel_shift"+index);
		close();				
	}
 


	// Support functions


	function GetMaxLen(name){
	// Get max dimension for calculations : ROI (L,L,L) with L = 2^x
		selectWindow(name);
		Stack.getDimensions(width,height,channels,slices,frames);
		L = minOf(width,height);
//		if(slices < L) L = slices;
		L = nextPowerOfTwo(round(0.5*L));

		return L;
	}

	function GetShiftX(nameCh, width){		
		shift_pos_x = "right";
		selectWindow(nameCh);
		Stack.getDimensions(w,h,ch,d,nf);
		pos_mid = floor(d/2);	
		Nx = w-width;
		if(w>width){
			Stack.setSlice(pos_mid);
			Stack.setChannel(1);			
			setTool("rectangle");
			makeRectangle(0,0,1,height);
			getStatistics(area, meanX, min, max, std, histogram);
			if(meanX == 0)shift_pos_x = "left";							
		}
		return shift_pos_x;
	}

	function GetShiftY(nameCh, height){		
		shift_pos_y = "up";
		selectWindow(nameCh);
		Stack.getDimensions(w,h,ch,d,nf);
		pos_mid = floor(d/2);	
		Ny = h-height;
		if(h>height){
			Stack.setSlice(pos_mid);
			Stack.setChannel(1);
			setTool("rectangle");
			makeRectangle(0,0,width,1);
			getStatistics(area, meanY, min, max, std, histogram);
			if(meanY == 0)shift_pos_y = "down";								
		}
		return shift_pos_y;
	}

	function GetShiftZ(nameCh, slices){		
		shift_pos_z = "up";
		selectWindow(nameCh);
		Stack.getDimensions(w,h,ch,d,nf);
		Nz = d-slices;	
		if(d>slices){
			Stack.setSlice(d);
			Stack.setChannel(1);
			getStatistics(area, meanZ, min, max, std, histogram);
			if(meanZ == 0)shift_pos_z = "down";		
		}
		return shift_pos_z;
	}

	function nextPowerOfTwo(size) {
		size--;
		for ( i = 1; i <= 32; i *= 2 ) { size = size | (size >> i); }
		size++;
		return size;
	}


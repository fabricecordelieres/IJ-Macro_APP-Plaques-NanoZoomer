//Names of the anatomical regions of interest
names=newArray("Molecular_layer", "CA4", "CA3_CA2", "CA1_subiculum", "Enterohinal_cortex");

//Colors to be used for display
colors=newArray("red", "green", "blue", "cyan", "magenta", "yellow", "darkGray", "orange", "gray", "pink", "lightGray");

//Thresholds to be used for HSB segmentation
thr=newArray(0, 32, 96, 255, 0, 160);

//Radius of outliers removal to be used on masks
radOutliers=5;

//Expected sizes in microns
minSize=5;
maxSize=5000;

//Expected minimum morphometric values
minFeret=4;
maxAR=4;
minRound=0.25;
minSolidity=0.45;


//Prepare measurements and data container + reset
run("Set Measurements...", "area centroid perimeter bounding shape feret's display redirect=None decimal=3");
roiManager("Reset");

//Processing
GUI();

askForRois(names, colors);

HSBSeg(thr, radOutliers, minSize, maxSize);

filterRois(names.length, minFeret, maxAR, minRound, minSolidity);

//Edit Rois
roiManager("Show All with labels");
removeMultipleRois();
waitForUser("You may now complement/correct Rois detection. \nEnd by pressing Ok");

tagRois(names, colors);

outputData(names, minSize, maxSize);


//------------------------------------------------------------------------------------
function GUI(){
	//No need for now
	run("Preview NDPI...");
	preview=getTitle();
	setTool("rectangle");
	
	while(selectionType==-1) waitForUser("Draw the region to analyze,\nthen press Ok");
	run("Extract to TIFF");

	//Handles cases where the unit is not um
	getPixelSize(unit, pixelWidth, pixelHeight);
	if(unit=="cm") run("Properties...", "unit=um pixel_width="+pixelWidth*10000+" pixel_height="+pixelHeight*10000);

	close(preview);
}

//------------------------------------------------------------------------------------
function askForRois(names, colors){
	setTool("freehand");
	roiManager("Show All without labels");
	
	for(i=0; i<names.length; i++){
		run("Select None");
		while(selectionType==-1) waitForUser("ROI "+(i+1)+"/"+names.length+":\nDraw the ROI \""+names[i]+"\",\nthen press Ok");
		Roi.setName(names[i]);
		Roi.setStrokeColor(colors[i%colors.length]);
		roiManager("Add");
	}	
}

//------------------------------------------------------------------------------------
function HSBSeg(thr, radOutliers, minSize, maxSize){
	titles=newArray("Hue", "Saturation", "Brightness");
	
	ori=getTitle();

	run("Select None");
	run("Duplicate...", "title=HSBSeg");
	run("HSB Stack");
	run("Stack to Images");

	for(i=0; i<titles.length; i++){
		selectWindow(titles[i]);
		setThreshold(thr[i*2], thr[i*2+1]);
		run("Convert to Mask", "method=Default background=Dark black");
		run("Remove Outliers...", "radius="+radOutliers+" threshold=128 which=Bright");
	}

	imageCalculator("AND create", "Hue","Saturation");
	rename("Interm_Result");

	imageCalculator("AND create", "Interm_Result","Brightness");
	rename("HSBSeg");
	run("Fill Holes");

	for(i=0; i<titles.length; i++) close(titles[i]);
	close("Interm_Result");

	run("Analyze Particles...", "size="+minSize+"-"+maxSize+" add");
	close("HSBSeg");

	selectWindow(ori);
	
	roiManager("Deselect");
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");

	roiManager("Show All without labels");
}

//---------------------------------------------------------------
function removeMultipleRois(){
	getOut=false;
	while(!getOut){
		setTool("rectangle");
		waitForUser("Draw a rectangular Roi over the detections to delete, then press Ok\n-OR-\nDon't draw anything then press Ok to end");
		if(selectionType!=-1){
			roisRemover();
		}else{
			getOut=true;
		}
	}
}

//---------------------------------------------------------------
function roisRemover(){
	if(selectionType!=-1){
		getBoundingRect(x, y, width, height);

		for(i=names.length; i<roiManager("Count"); i++){
			roiManager("Select", i);
			getBoundingRect(xRoi, yRoi, wRoi, hRoi);
			makeRectangle(x, y, width, height);
			if(selectionContains(xRoi+wRoi/2, yRoi+hRoi/2)){
				roiManager("Delete");
				i--;
			}
		}
		run("Select None");
	}
}

//---------------------------------------------------------------
function filterRois(startRoi, minFeret, maxAR, minRound, minSolidity){
	for(i=startRoi; i<roiManager("Count"); i++){
		roiManager("Select", i);

		List.setMeasurements;
		feret=List.getValue("MinFeret");
		AR=List.getValue("AR");
		roundness=List.getValue("Round");
		solidity=List.getValue("Solidity");
		
		keep=minFeret<feret && maxAR>AR && minRound<roundness && minSolidity<solidity;

		if(!keep && i>startRoi){
			roiManager("Select", i);
			roiManager("Delete");
			i--;
		}
	}

	roiManager("Deselect");
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");
	roiManager("Show All without labels");
}


//---------------------------------------------------------------
function tagRois(names, colors){
	roiManager("Show All without labels");

	//Keeps counts for all tags
	tagsCount=newArray(names.length);

	nTags=names.length;
	nRois=roiManager("Count");
	
	//All tags
	for(j=0; j<nTags; j++){
		//All non tags Rois
		for(i=nTags; i<nRois; i++){
			roiManager("Select", newArray(i, j));
			roiManager("AND");

			if(selectionType!=-1){
				roiManager("Deselect");
				roiManager("Select", i);
				tagsCount[j]++;
				Roi.setName(names[j]+"_Roi"+tagsCount[j]);
				Roi.setStrokeColor(colors[j]);

				roiManager("Add"); //Adding allows reordering Rois per tag
			}
		}
	}

	//Clean up: erase non tagged Rois
	for(i=nTags; i<nRois; i++){
		roiManager("Select", nTags); //Always select the Rois after the last tag
		roiManager("Delete");
	}
}

//---------------------------------------------------------------
function outputData(names, minSize, maxSize){
	run("Clear Results");
	roiManager("Deselect");
	roiManager("Measure");
	for(i=0; i<roiManager("Count"); i++){
		roiManager("Select", i);
		
		name=Roi.getName;
		roiNb=0;
		region=name;
		
		if(indexOf(name, "_Roi")!=-1){
			roiNb=substring(name, indexOf(name, "_Roi")+4);
			region=substring(name, 0, indexOf(name, "_Roi"));
		}

		regionNb=getPosition(names, region);
		
		setResult("Roi_Name", i, name);
		setResult("Roi_Nb", i, roiNb);
		setResult("Region_Name", i, region);
		setResult("Region_Nb", i, regionNb);
	}

	//Plot area per region
	Plot.create("Area per Region", "Region_Nb", "Area");
	Plot.add("Circle", Table.getColumn("Region_Nb", "Results"), Table.getColumn("Area", "Results"));
	Plot.setStyle(0, "blue,#a0a0ff,1.0,Circle");
	Plot.setLogScaleX(false);
	Plot.setLogScaleY(false);
	Plot.setLimits(0, names.length+1, minSize, maxSize);
	Plot.show();

	//Plot area per region
	Plot.create("Perimeter per Region", "Region_Nb", "Perimeter");
	Plot.add("Circle", Table.getColumn("Region_Nb", "Results"), Table.getColumn("Perim.", "Results"));
	Plot.setStyle(0, "blue,#a0a0ff,1.0,Circle");
	Plot.setLogScaleX(false);
	Plot.setLogScaleY(false);
	Plot.setLimits(0, names.length+1, minSize, maxSize);
	Plot.show();
}

//---------------------------------------------------------------
function getPosition(array, value){
	pos=-1;
	i=0;
	
	while(array[i]!=value && i<array.length){
		i++;
	}

	if(i!=array.length) pos=i+1;

	return pos;
}

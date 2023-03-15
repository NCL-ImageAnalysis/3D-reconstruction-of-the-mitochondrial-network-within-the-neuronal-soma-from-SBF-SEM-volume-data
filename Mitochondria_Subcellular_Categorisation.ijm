//Define the Folders Containing Your Labelled Images
homeFolder = getDirectory("Select the Home Directory for This Project");
rawFolder = getDirectory("Select the Directory with your Image Labels");
roiFolder = getDirectory("Select the Directory with your Regions of Interest");

//Defines arrays as expandable, important for later steps
setOption("ExpandableArrays", true);

//Creates (if necessary) all the folders you'll need to be able to run the code and output images/data
nuclearFolder = homeFolder + "Nuclear/";
if (File.isDirectory(nuclearFolder) < 1) {
	File.makeDirectory(nuclearFolder); 
}
cellFolder = homeFolder + "Cell/";
if (File.isDirectory(cellFolder) < 1) {
	File.makeDirectory(cellFolder); 
}
nuclearRegionFolder = homeFolder + "Nuclear_Region/";
if (File.isDirectory(nuclearRegionFolder) < 1) {
	File.makeDirectory(nuclearRegionFolder); 
}
cellRegionFolder = homeFolder + "Cell_Region/";
if (File.isDirectory(cellRegionFolder) < 1) {
	File.makeDirectory(cellRegionFolder); 
}
rgbFolder = homeFolder + "RGB/";
if (File.isDirectory(rgbFolder) < 1) {
	File.makeDirectory(rgbFolder); 
}
resultsFolder = homeFolder + "Results/";
if (File.isDirectory(resultsFolder) < 1) {
	File.makeDirectory(resultsFolder); 
}

//Count the number of images in your raw image folder
list = getFileList(rawFolder);
l = list.length;
//Loops through the images performing the functions outlined below
for (i=0; i<1; i++) {
	//Open the Image From the Folder
	filename = rawFolder + list[i];
	open(filename);
	//Thresholds to Get Just Nuclear Region
	setThreshold(2, 2);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Dark");	
	//Saves the Nuclear Image for Audit Purposes
	saveName = nuclearFolder + list[i];
	saveAs("Tiff", saveName);
	//Scales the image down by a factor of 10 to make subsequent processing steps faster
	//And to prevent crashing of FIJI on computers with lower RAM capabilities
	run("Scale...", "x=.1 y=.1 z=1.0 interpolation=None process create");
	//Duplicate the Image and get the title of each as variables
	orig = getTitle();
	run("Duplicate...", "duplicate");
	//expand nuclear image in 3D for the dulpicate stack
	run("Morphological Filters (3D)", "operation=Dilation element=Cube x-radius=20 y-radius=20 z-radius=8"); //THIS NEEDS TO BE OPTIMISED FOR WHAT THE USERS ACTUALLY DESIRE
	expand = getTitle();
	//Subtracts the original segmented nucleus from the dilated nucleus, leaving just a ring around the nucleus (peri-nuclear region)
	imageCalculator("Subtract create stack", expand, orig);
	//Save the peri-nuclear region imageas an image in a relevant folder
	saveName = nuclearRegionFolder + list[i];
	saveAs("Tiff", saveName);
	//Close all the open images
	close("*");
	//Re-open the original raw image
	open(filename);
	//Threshold for Cell Volume this time (including nucleus)
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Dark");	
	//Save the cytoplasm Image
	saveName = cellFolder + list[i];
	saveAs("Tiff", saveName);
	//Duplicate the Image and get the title of each as variables
	run("Scale...", "x=.1 y=.1 z=1.0 interpolation=None process create");
	orig = getTitle();
	run("Duplicate...", "duplicate");
	//Reduce cell volume in 3D for one of the stacks, subtract from original threshold
	run("Morphological Filters (3D)", "operation=Erosion element=Cube x-radius=20 y-radius=20 z-radius=8"); //THIS NEEDS TO BE OPTIMISED FOR WHAT THE USERS ACTUALLY DESIRE
	reduced = getTitle();
	imageCalculator("Subtract create stack", orig, reduced);
	//run("Scale...", "x=10 y=10 z=1.0 interpolation=None process create");
	//Save as an image in a relevant folder
	saveName = cellRegionFolder + list[i];
	saveAs("Tiff", saveName);
	//Closes all open images
	close("*");
	//Loads up the peri-cell image and the peri-nuclear image
	filename = cellRegionFolder + list[i];
	open(filename);
	pericell = getTitle();
	filename = nuclearRegionFolder + list[i];
	open(filename);
	perinuclear = getTitle();
	//Merges the channels so peri-nuclear and peri-membrane are different colours, with yellow indicating overlap, and no colour indicating neither category
	run("Merge Channels...", "c1=[" + pericell + "] c2=[" + perinuclear + "] create keep ignore");
	close(pericell);
	close(perinuclear);
	//Converts the image into RGB then into stack so three channels for subsequent analysis
	run("Stack to RGB", "slices keep");
	run("Make Composite");
	//Saves the colour image to appropriate folder
	saveName = rgbFolder + list[i];
	saveAs("Tiff", saveName);
	//Close the other open images
	close("*");
	
}

//Now look at the folder full of the regions of interest and see which regions overlap with the different categories
//Gets a list of the roi csv files in the roi folder
roilist = getFileList(roiFolder);
l = roilist.length;
//Cycles through the roi csv files
for (i=0; i<l; i++) {
	//Defines two new empty arrays, to be filled later
	xArray = newArray(0);
	yArray = newArray(0);
	//Defines row as 0, important for later results
	row = 0;
	//Opens the roi file to read the coordinate data
	fileName = roiFolder + roilist[i];
	open(fileName);
	for (j=0; j<20; j++) {
		//cycles through the roi coordinates, adding them to the empty arrays
		x = getResult("X", j);
		y = getResult("Y", j);
		xArray = Array.concat(xArray, x);
		yArray = Array.concat(yArray, y);
	}
	//opens the colour peri-nuclear/cell image
	filename = rgbFolder + list[i];
	open(filename);
	//Performs a Z projection to get average colour intensities over the full z stack for determining if regions are in just one category or multipl
	run("Z Project...", "projection=[Average Intensity]");
	//Runs through each of the regions, converts it to the right scale for the scaled down images, and plots it on the Z-projection
	for (j=0; j<20; j++) {
		cell = 0;
		nuclear = 0;
		x = xArray[j]/10;
		y = yArray[j]/10;
		makeRectangle(x, y, 1, 1);
		roiManager("add");
		//Measures the region on each of the channels, storing the info and pasting it under the channel colour
		Stack.setChannel(1);
		run("Measure");
		red = getResult("Mean", row);
		IJ.deleteRows( nResults-1, nResults-1 );
		Stack.setChannel(2);
		run("Measure");
		green = getResult("Mean", row);
		IJ.deleteRows( nResults-1, nResults-1 );
		Stack.setChannel(3);
		run("Measure");
		blue = getResult("Mean", row);
		IJ.deleteRows( nResults-1, nResults-1 );
		Stack.setChannel(1);
		run("Measure");
		setResult("Red", row, red);
		setResult("Green", row, green);
		setResult("Blue", row, blue);
		if (red > 0){
			cell = 1;
		}
		if (green > 0){
			nuclear = 1;
		}
		sum = nuclear + cell;
		if (sum == 0){
			localisation = "Intermediate";
		}
		if (sum == 1){
			if (nuclear > 0){
				localisation = "Perinuclear";
			}
			if (cell > 0){
				localisation = "Perimembrane";
			}
		}
		if (sum == 2){
			localisation = "Overlap";
		}
		setResult("Localisation", row, localisation);
		row = row + 1;
	}
	//Saves the results to the folder using the region of interest file name
	resultsName = resultsFolder + roilist[i];
	saveAs("Results", resultsName);
	//Closes the open images, clears the results window, and resets the ROI manager to get everything ready for the next ROI file
	close("*");
	//run("Clear Results");
	roiManager("reset");
}


	
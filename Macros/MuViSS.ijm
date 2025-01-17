/*
 * This program is free software; you can redistribute it and/or modify it under the terms of the creative commons Attribution-NonCommercial-ShareAlike 4.0 International
 *  https://creativecommons.org/licenses/by-nc-sa/4.0/
 */

#@ File (label = "Input directory for scans", style = "directory") input
#@ File (label = "Input deep learning model for segmentation", style = "open") model
#@ File (label = "Output directory", style = "directory") output
#@ Integer (label = "Lower-bound value for muscle thresholding", value = -29, style = "spinner") LowThresholdMuscle
#@ Integer (label = "Upper-bound value for muscle thresholding", value = 150, style = "spinner") HighThresholdMuscle
#@ Integer (label = "Lower-bound value for visceral fat thresholding", value = -190, style = "spinner") LowThresholdVisceralFat
#@ Integer (label = "Upper-bound value for visceral fat thresholding", value = -30, style = "spinner") HighThresholdVisceralFat
#@ Integer (label = "Lower-bound value for subcutaneous fat thresholding", value = -190, style = "spinner") LowThresholdSubcutaneousFat
#@ Integer (label = "Upper-bound value for subcutaneous fat thresholding", value = -30, style = "spinner") HighThresholdSubcutaneousFat

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	// remove results in result table if there are any
	run("Clear Results");
	
	setBatchMode(false);
	
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], "tif"))
			processFile(input, output, list[i]);
		if(endsWith(list[i], "tiff"))
			processFile(input, output, list[i]);
		if(endsWith(list[i], "DCM"))
			processFile(input, output, list[i]);
	}

	// save results
	saveAs("Results", output + File.separator + "results.csv");	
	// close results table
	selectWindow("Results"); 
	run("Close");
		
}

function processFile(input, output, file) {
	
	///////////// initial cleaning /////////////////
	// close all images
	run("Close All");
	// clear the roi manager
	roiManager("Reset");

	// input parameters
	minimum_size_region = 1000;
	
	// open segmentationse
	open(input + File.separator + file);
	getDimensions(width, height, channels, slices, frames);
	
	if ( (width==512) && (height==512) && (channels==1) && (slices==1) && (frames==1) ){
		// rename input image
		rename("input");
		// use U-Net model to segment the scan
		run("Command From Macro", "command=[de.csbdresden.csbdeep.commands.GenericNetwork], args=['input':'input','normalizeinput':'true','percentilebottom':'1.0','percentiletop':'99.8','clip':'false','ntiles':'1','blockmultiple':'512','overlap':'512','batchsize':'1','modelFile':'" + replace(model, "\\", "/") + "','showprogressdialog':'false'], process=[false]");
		rename("segmentedScan");
		// compute z max projection
		run("Z Project...", "projection=[Max Intensity]");
		// get scores for each class as an image
		selectImage("segmentedScan");
		run("Stack to Images");
		// extract each binary class
		// class 1
		imageCalculator("Subtract create 32-bit", "MAX_segmentedScan","1");
		setThreshold(0.000000000, 0.000000000);
		run("Convert to Mask");
		// connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// test if at least one component
		getStatistics(class1_area, class1_mean, class1_min, class1_max, class1_std, class1_histogram);
		// if there is at least one component
		if ( class1_max>0 ) {
			// keep largest component
			run("Keep Largest Label");
		}
		// binarize image
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		// fill holes
		run("Fill Holes");
		//run("Invert");
		rename("Backbone");
		run("Grays");

		// class 2
		imageCalculator("Subtract create 32-bit", "MAX_segmentedScan","2");
		setThreshold(0.000000000, 0.000000000);
		run("Convert to Mask");
		// connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// test if at least one component
		getStatistics(class2_area, class2_mean, class2_min, class2_max, class2_std, class2_histogram);
		// if there is at least one component
		if ( class2_max>0 ) {
			// keep largest component
			run("Keep Largest Label");
		}
		// binarize image
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		// fill holes
		run("Fill Holes");
		//run("Invert");
		rename("VisceralFat");
		run("Grays");

		// class 3
		imageCalculator("Subtract create 32-bit", "MAX_segmentedScan","3");
		setThreshold(0.000000000, 0.000000000);
		run("Convert to Mask");
		// connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// filter out small regions
		run("Label Size Filtering", "operation=Greater_Than size=" + minimum_size_region + "");
		rename("prepreprocessed_input-0002");
		// duplicate
		run("Duplicate...", " ");
		// fill holes
		run("Fill Holes (Binary/Gray)");
		rename("filledprepreprocessed_input-0002");
		// get filled holes
		imageCalculator("Subtract create 32-bit", "filledprepreprocessed_input-0002","prepreprocessed_input-0002");
		// filter out too large holes
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		run("Label Size Filtering", "operation=Lower_Than size=" + minimum_size_region + "");
		// binarize image
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("HolesToBeFilled-0002");
		// actually compute component with not too large filled holes
		imageCalculator("Add create 32-bit", "prepreprocessed_input-0002","HolesToBeFilled-0002");
		rename("Muscle");
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Grays");

		// class 4
		imageCalculator("Subtract create 32-bit", "MAX_segmentedScan","4");
		setThreshold(0.000000000, 0.000000000);
		run("Convert to Mask");
		// process connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// test if at least one component
		getStatistics(class4_area, class4_mean, class4_min, class4_max, class4_std, class4_histogram);
		// if there is at least one component
		if ( class4_max>0 ) {
			// keep largest component
			run("Keep Largest Label");
		}
		rename("prepreprocessed_input-0003");
		// duplicate
		run("Duplicate...", " ");
		// fill holes
		run("Fill Holes (Binary/Gray)");
		rename("filledprepreprocessed_input-0003");
		// get filled holes
		imageCalculator("Subtract create 32-bit", "filledprepreprocessed_input-0003","prepreprocessed_input-0003");
		// filter out too large holes
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		run("Label Size Filtering", "operation=Lower_Than size=" + minimum_size_region + "");
		// binarize image
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("HolesToBeFilled");
		// actually compute component with not too large filled holes
		imageCalculator("Add create 32-bit", "prepreprocessed_input-0003","HolesToBeFilled");
		rename("preprocessed_input-0003");
		// connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// filter out small regions
		run("Label Size Filtering", "operation=Greater_Than size=" + minimum_size_region + "");
		// binarize image
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("SubcutaneousFat");
		run("Grays");
	
	
		// extract pixels not assigned
		imageCalculator("Add create 32-bit", "Backbone","VisceralFat");
		imageCalculator("Add create 32-bit", "Result of Backbone","Muscle");
		imageCalculator("Add create 32-bit", "Result of Result of Backbone","SubcutaneousFat");
		// duplicate
		run("Duplicate...", " ");
		// fill holes
		run("Fill Holes (Binary/Gray)");
		rename("WholeComponent");
		imageCalculator("Subtract create 32-bit", "WholeComponent","Result of Result of Result of Backbone");
		rename("PixelsToBeAssigned");
	
		// add pixels to muscle
		imageCalculator("Add create 32-bit", "PixelsToBeAssigned","VisceralFat");
		// process connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// filter out small regions
		run("Label Size Filtering", "operation=Greater_Than size=" + minimum_size_region + "");
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("PostProcessedVisceralFat");
		run("Grays");
		// add regions not assigned to muscle to visceral fat
		selectWindow("Result of PixelsToBeAssigned");
		run("8-bit");
		imageCalculator("Subtract create 32-bit", "Result of PixelsToBeAssigned","PostProcessedVisceralFat");
		imageCalculator("Add create 32-bit", "Result of Result of PixelsToBeAssigned","Muscle");
		// process connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// filter out small regions
		run("Label Size Filtering", "operation=Greater_Than size=" + minimum_size_region + "");
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("PostProcessedMuscle");
		run("Grays");
		// add regions not assigned to muscle to subcutaneous fat
		selectWindow("Result of Result of Result of PixelsToBeAssigned");
		run("8-bit");
		imageCalculator("Subtract create 32-bit", "Result of Result of Result of PixelsToBeAssigned","PostProcessedMuscle");
		imageCalculator("Add create 32-bit", "Result of Result of Result of Result of PixelsToBeAssigned","SubcutaneousFat");
		// process connected components
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		// filter out small regions
		run("Label Size Filtering", "operation=Greater_Than size=" + minimum_size_region + "");
		setThreshold(1, 65535, "raw");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("PostProcessedSubcutaneousFat");
		run("Grays");
	
		selectImage("input");
		// duplicate image
		run("Duplicate...", "CurrentInputImage");
		// segment muscle area
		setThreshold(LowThresholdMuscle, HighThresholdMuscle);
		run("Convert to Mask");
		rename("MusclePixels");
		// select input image
		selectImage("input");
		// duplicate image
		run("Duplicate...", "CurrentInputImage");
		// segment visceral fat area
		setThreshold(LowThresholdVisceralFat, HighThresholdVisceralFat);
		run("Convert to Mask");
		rename("VisceralFatPixels");
		// select input image
		selectImage("input");
		// duplicate image
		run("Duplicate...", "CurrentInputImage");
		// segment fat area
		setThreshold(LowThresholdSubcutaneousFat, HighThresholdSubcutaneousFat);
		run("Convert to Mask");
		rename("SubcutaneousFatPixels");

		// analyze muscle area
		imageCalculator("Multiply create 32-bit", "Muscle","MusclePixels");
		// create ROI
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		muscleROI_index = -1;
		if (selectionType()>(-1)){
			roiManager("Add");
			muscleROI_index = 0;
		}
		// analyze visceral fat
		imageCalculator("Multiply create 32-bit", "VisceralFat","VisceralFatPixels");
		// create ROI
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		visceralFatROI_index = -1;
		if (selectionType()>(-1)){
			roiManager("Add");
			visceralFatROI_index = muscleROI_index + 1;
		}
		// analyze subcutaneous fat
		imageCalculator("Multiply create 32-bit", "SubcutaneousFat","SubcutaneousFatPixels");
		// create ROI
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		subcutaneousFatROI_index = -1;
		if (selectionType()>(-1)){
			roiManager("Add");
			if ( (muscleROI_index < 0) && (visceralFatROI_index < 0) ) {
				subcutaneousFatROI_index = 0;
			}
			else {
				if ( (muscleROI_index > (-1)) && (visceralFatROI_index > (-1)) ) {
					subcutaneousFatROI_index = 2;
				}
				else{
					subcutaneousFatROI_index = 1;
				}
			}
		}
		
		// select input image
		selectImage("input");
		setResult("Input name", nResults, file);
		// measure area for all ROIs
		if (muscleROI_index > (-1)){
			roiManager("select", muscleROI_index);
			getStatistics(muscle_area, mean, min, max, std, histogram);
		}
		else{
			muscle_area = 0;
		}
    	setResult("Muscle area", nResults-1, muscle_area);
		if (visceralFatROI_index > (-1)){
			roiManager("select", visceralFatROI_index);
			getStatistics(visceral_fat_area, mean, min, max, std, histogram);
		}
		else{
			visceral_fat_area = 0;
		}
	    setResult("Visceral fat area", nResults-1, visceral_fat_area);
	    if (subcutaneousFatROI_index > (-1)){
			roiManager("select", subcutaneousFatROI_index);
			getStatistics(subcutaneous_fat_area, mean, min, max, std, histogram);
	    }
	    else{
	    	subcutaneous_fat_area = 0;
	    }
    	setResult("Subcutaneous fat area", nResults-1, subcutaneous_fat_area);
	
		// clear ROI manager
		roiManager("Reset");

		// create output image for visual inspection
		// muscle
		selectImage("Muscle");
		// add to ROI manager
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		if (selectionType()>(-1)){
			roiManager("Add");
		}
		// visceral fat
		selectImage("VisceralFat");
		// add to ROI manager
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		if (selectionType()>(-1)){
			roiManager("Add");
		}
		// subcutaneous fat
		selectImage("SubcutaneousFat");
		// add to ROI manager
		run("8-bit");
		setThreshold(127, 255);
		run("Create Selection");
		if (selectionType()>(-1)){
			roiManager("Add");
		}
		// select input image
		selectImage("input");
		// overlay rois to the image
		roiManager("Show All without labels");
		// add ROIs to the image
		run("Flatten");
		// save for visual inspection
		saveAs("png", output + File.separator + file + "_output_visual_inspection.png");
	}
	else{
		// the input image is not in the right format
		setResult("Input name", nResults, file);
		setResult("Muscle area", nResults-1, "The input image is not a single channel 512x512 image");
	}
	
	///////////// clear everything /////////////////
	// close all images
	run("Close All");
	// clear the roi manager
	roiManager("Reset");

}

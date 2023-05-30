/*
 * This program is free software; you can redistribute it and/or modify it under the terms of the creative commons Attribution-NonCommercial-ShareAlike 4.0 International
 *  https://creativecommons.org/licenses/by-nc-sa/4.0/
 */

#@ File (label = "Input directory for scans", style = "directory") input_images
#@ File (label = "Input directory for segmentations", style = "directory") input_segmentations
#@ File (label = "Output directory", style = "directory") output
#@ Integer (label = "Lower-bound value for muscle thresholding", value = -29, style = "spinner") LowThresholdMuscle
#@ Integer (label = "Upper-bound value for muscle thresholding", value = 150, style = "spinner") HighThresholdMuscle
#@ Integer (label = "Lower-bound value for visceral fat thresholding", value = -190, style = "spinner") LowThresholdVisceralFat
#@ Integer (label = "Upper-bound value for visceral fat thresholding", value = -30, style = "spinner") HighThresholdVisceralFat
#@ Integer (label = "Lower-bound value for subcutaneous fat thresholding", value = -190, style = "spinner") LowThresholdSubcutaneousFat
#@ Integer (label = "Upper-bound value for subcutaneous fat thresholding", value = -30, style = "spinner") HighThresholdSubcutaneousFat

processFolder(input_images);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_images) {
	// remove results in result table if there are any
	run("Clear Results");
	
	setBatchMode(false);
	
	list = getFileList(input_images);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], "tif"))
			processFile(input_images, input_segmentations, output, list[i]);
		if(endsWith(list[i], "tiff"))
			processFile(input_images, input_segmentations, output, list[i]);
		if(endsWith(list[i], "DCM"))
			processFile(input_images, input_segmentations, output, list[i]);
	}

	// save results
	saveAs("Results", output + File.separator + "results.csv");	
	// close results table
	selectWindow("Results"); 
	run("Close");
		
}

function processFile(input_images, input_segmentations, output, file) {
	///////////// initial cleaning /////////////////
	// close all images
	run("Close All");
	// clear the roi manager
	roiManager("Reset");

	// input parameters
	minimum_size_region = 1000;
	
	// open segmentationse
	open(input_images + File.separator + file);
	// rename input image
	rename("input");
	// open segmentationse
	open(input_segmentations + File.separator + file);
	rename("segmentedScan");
	run("Stack to Images");
	
	// backbone
	selectImage("segmentedScan-0001");
	rename("Backbone");
	
	// visceral fat
	selectImage("segmentedScan-0002");
	rename("VisceralFat");
	
	// Muscle
	selectImage("segmentedScan-0003");
	rename("Muscle");

	// sub-cutaneous fat
	selectImage("segmentedScan-0004");
	rename("SubcutaneousFat");
	
	
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
	roiManager("Add");
	// analyze visceral fat
	imageCalculator("Multiply create 32-bit", "VisceralFat","VisceralFatPixels");
	// create ROI
	run("8-bit");
	setThreshold(127, 255);
	run("Create Selection");
	roiManager("Add");
	// analyze subcutaneous fat
	imageCalculator("Multiply create 32-bit", "SubcutaneousFat","SubcutaneousFatPixels");
	// create ROI
	run("8-bit");
	setThreshold(127, 255);
	run("Create Selection");
	roiManager("Add");

	// select input image
	selectImage("input");
	setResult("Input name", nResults, file);
	// measure area for all ROIs
	roiManager("select", 0);
	getStatistics(muscle_area, mean, min, max, std, histogram);
    setResult("Muscle area", nResults-1, muscle_area);
	roiManager("select", 1);
	getStatistics(visceral_fat_area, mean, min, max, std, histogram);
    setResult("Visceral fat area", nResults-1, visceral_fat_area);
	roiManager("select", 2);
	getStatistics(subcutaneous_fat_area, mean, min, max, std, histogram);
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
	roiManager("Add");
	// muscle
	selectImage("VisceralFat");
	// add to ROI manager
	run("8-bit");
	setThreshold(127, 255);
	run("Create Selection");
	roiManager("Add");
	// muscle
	selectImage("SubcutaneousFat");
	// add to ROI manager
	run("8-bit");
	setThreshold(127, 255);
	run("Create Selection");
	roiManager("Add");
	// select input image
	selectImage("input");
	// overlay rois to the image
	roiManager("Show All without labels");
	// add ROIs to the image
	run("Flatten");
	// save for visual inspection
	saveAs("png", output + File.separator + file + "_output_visual_inspection.png");
	
	///////////// clear everything /////////////////
	// close all images
	run("Close All");
	// clear the roi manager
	roiManager("Reset");

}

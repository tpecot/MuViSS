# MuViSS
ImageJ macro for segmenting Muscle, Visceral and Subcutaneous fat from L3-CT scans.

<br>
A deep learning (U-Net) model was trained to automatically identify the backbone, muscle area, visceral and subcutaneous fat from L3-CT scans. This model was converted to be directly processed with ImageJ. The model is available at https://zenodo.org/record/7990044.<br>
<br>

The first macro allows to extract the ratio of segmented areas within a predefined intensity range corresponding to the different tissues (muscle, visceral and subcutaneous fat) segmented with the U-Net model. If the segmentation fails, the second macro allows the user to give a manual segmentation as an input.<br>

# Video tutorials
[Download Fiji/ImageJ and install required plugins to run MuViSS]()<br>
[Run MuViSS]()<br>
[Run MuViSS with manual segmentation]()<br>

# Citations
If you use MuViSS, please cite: <br> 
Schindelin et al. (2012): [Fiji: an open-source platform for biological-image analysis](https://doi.org/10.1038/nmeth.2019) <br>
Ronneberger et al. (2015): [U-Net: Convolutional Networks for Biomedical Image Segmentation](https://doi.org/10.1007/978-3-319-24574-4_28) <br>
Schmidt et al. (2018): [Cell detection with Star-convex polygons]([https://arxiv.org/abs/1806.03535](https://doi.org/10.1007/978-3-030-00934-2_30) <br><br> 
A publication about MuViSS will be submitted soon.

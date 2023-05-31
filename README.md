# MuViSS
ImageJ macro for segmenting Muscle, Visceral and Subcutaneous fat from L3-CT scans.

<br />
A deep learning (U-Net) model was trained to automatically identify the backbone, muscle area, visceral and subcutaneous fat from L3-CT scans. This model was converted to be directly processed with ImageJ. The model is available [here](https://zenodo.org/record/7990044).<br />
<br />

The first macro allows to extract the ratio of segmented areas within a predefined intensity range corresponding to the different tissues (muscle, visceral and subcutaneous fat) segmented with the U-Net model. If the segmentation fails, the second macro allows the user to give a manual segmentation as an input.<br />

# Video tutorials
[Download Fiji/ImageJ and install required plugins to run MuViSS]()<br />
[Run MuViSS]()<br />
[Run MuViSS with manual segmentation]()<br />

# Citation
A paper about this tool will be submitted soon.

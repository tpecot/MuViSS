# MuViSS
ImageJ macro for segmenting Muscle, Visceral and Subcutaneous fat from L3-CT scans.

<br />
A deep learning (U-Net) model was trained to automatically identify the backbone, muscle area, visceral and subcutaneous fat from L3-CT scans. This model was converted to be directly processed with ImageJ. The macro allows to extract the ratio of segmented areas within a predefined intensity range corresponding to the different tissues (muscle, visceral and subcutaneous fat). If the segmentation fails, the user can also give a manual segmentation as an input.<br />

# Video tutorials
[Download Fiji/ImageJ and install required plugins to run MuViSS](https://youtu.be/dwRcHlkcHlI)<br />
//[Run MuViSS](https://youtu.be/8r9kXktrU18)<br />
#[Run MuViSS with manual segmentation](https://youtu.be/JGPAz1Lrh3k)<br />

# Citation
Please cite our paper if you use this plugin: <br>
Thierry Pécot, Maria C. Cuitiño, Roger H. Johnson, Cynthia Timmers, Gustavo Leone (2022): [Deep learning tools and modeling to estimate the temporal expression of cell cycle proteins from 2D still images](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009949)

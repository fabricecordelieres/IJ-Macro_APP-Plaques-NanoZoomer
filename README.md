# IJ-Macro_APP-Plaques-NanoZoomer
The purpose of the ImageJ macro is to segment, count and caracterize the APP aggregates in relevent regions over brain slices acquired using the NanoZoomer Imager.

## User's request
The user is dealing with human sample from Alzheimer patients. He has two antibodies targetted to APP wich are then revealed using DAB and imaged using the NanoZoomer. The purpose of the macro is to segment, count and caracterize the aggregates in relevent regions overthe brain slice. The diffuculty comes from non specific labelling of some somas and fibers. Proper definition of what is an aggregate also needs to be addressed.

## What does it do ?
### Step 1: Locating the area of interest
1. The user is invited to point at the NDPI file to analyze.
2. A preview of the slide is displayed on which the user is asked to draw the area of interest: it should delineate the part of the image that will later be analyzed.
3. The preview image is closed and the full resolution portion of the image within the ROI is displayed.

### Step 2: Locating the ROIs to analyse
1. The user is requested to draw the 5 anatomical regions to analyze: molecular layer, CA4, CA3-CA2, CA1-subiculum and enterohinal cortex.
2. Each ROI is added in turn to the ROI Manager for later use.

### Step 3: Segmentation
1. The input color image is duplicated and splitted into hue, saturation and brightness images.
2. Each component is subjected to thresholding using predefined settings (H: 0-32; S: 96-255; B: 0-160) and converted to mask. This step allows isolateing only the darkest-brown portions of the input image. 
3. Each mask is subjected to the "Remove Outlier" function (radius: 5, threshold: 128) to remove single dots.
4. The three masks are combined using a logical AND operator (keeps only what is common to all the masks).
5. The individual masks are closed and the combined image is subjected to particle analysis: the outlines of ROIs containing only object from 5 to 5000µm2 are retained and pushed to the ROI Manager.

### Step 4: Filtering out non relevent objects
1. Each ROI in the ROI Manager, starting after the last anatomical ROI are inspected in turn.
2. ROIs outside of the following criteria are deleted from the Roi Manager:
    1. Feret diameter (largest segment that can be inscribed within the ROI): >4µm.
    2. Aspect ratio (after fitting the Roi to an ellipse, computes the ratio between its major and minor axis): <4.
    3. Roudness (after fitting the Roi to an ellipse, computes the ratio 4*area/(PI*[Major axis]^2): >0.25.
    4. Solidity (ratio area/Convex area): >0.45.

### Step 5: Tagging the objects
1. Before tagging individual ROIs, the user is invited to add any missing ROI/delete any mis-detection.
2. Each ROI in the ROI Manager, starting after the last anatomical ROI are inspected in turn.
3. In case the inspected ROI intercepts (ie has at least 1 pixel in common) with one of the anatomical ROI, it is attributed to it:
    1. The ROI is rename in the form [Name of the anatomical region]_Roi[Count of ROIs for the current anatomical region].
    2. A anatomical region specific color is attributed to it.
    3. In case a ROI is inbetween two anatomical region, it is attributed to both.
    4. Finally, the ROI is added back to the ROI Manager.
4. All region the original ROIs are then deleted from the ROI Manager.

### Step 6: Extracting and outputing data
1. A data table is generated containing for each ROI the following parameters:
    1. Area.
    2. X & Y coordinates of its centre.
    3. Bounding box parameters (width, height, start X & Y).
    4. Circularity.
    5. Feret distances & angle.
    6. Aspect ratio.
    7. Roundness.
    8. Solidity.
    9. Roi name, region name and region number (will help data sorting if performed outside of ImageJ).
2. Two quick graphs:
    1. Distribution of the area per ROI, grouped by anatomical region.
    2. Distribution of the perimeters per ROI, grouped by anatomical region.
    
![Example output](/Images/Illust_APP_Macro.jpg)
    
## How to use it ?
___Versions of the software used___

Fiji, ImageJ 2.0.0-rc-69/1.52i

___Additional required software___

Install the following plugin
NDPI Tools: [http://www.imnc.in2p3.fr/pagesperso/deroulers/software/ndpitools/](http://www.imnc.in2p3.fr/pagesperso/deroulers/software/ndpitools/). Precisely follow the step-by-step installation instructions given on the author's website.

## How to install and use the macro?
1. Update ImageJ : Help/update puis Ok.
2. Drag and drop the macro file onto ImageJ's toolbar.
3. Under the macro window, select Run macro from the Run menu.
4. Follow the onscren instructions.

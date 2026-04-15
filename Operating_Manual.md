Operating Manual: Automated Color Calibration and Tobacco Leaf ROI Extraction
Version: 1.0.0

Release Date: April 2026

1. System Requirements
To ensure the proper functioning of the automated pipeline, the following environment is recommended:

Hardware
CPU: Intel Core i5 (or equivalent AMD processor) or higher.

RAM: 8 GB minimum (16 GB recommended for processing high-resolution raw images).

Software
Platform: Windows 10/11, macOS, or Linux.

Environment: MATLAB R2024a or later is recommended.

Required Toolboxes:

Image Processing Toolbox™

Statistics and Machine Learning Toolbox™

2. Installation
This tool is provided as a standalone MATLAB script.

Download: Clone this repository or download the ZIP archive.

Setup: Extract the files to a local directory and ensure the folder structure (especially the samples/ folder) remains intact.

Main Script: Ensure the core script is named main.m.

3. Usage Instructions
Step 1: Prepare Data
Place your test images in the samples/ folder or any directory of your choice. Supported formats include .jpg, .png, and .bmp.

Step 2: Configure Path
Open main.m in the MATLAB Editor. Locate Line 18:

Matlab
imgPath = 'samples/sample_01.jpg'; % Update this path
Change the string to point to your target image file.

Step 3: Execution
Click the Run button in the MATLAB toolbar or press F5. The script will automatically perform the following operations:

Color Checker Localization: Automatically extract the spatial information of the 24 color patches.

Color Calibration: Simultaneously apply three calibration strategies: C1 (WB), C2 (CCM), and C3 (Root-Polynomial).

ROI Extraction: Segment the tobacco leaf area, executing background removal and defect elimination.

Step 4: Interpret Results
After execution, the program will generate two visualization windows:

Window 1 (Color Checker Verification): Displays whether the 24 cyan bounding boxes perfectly align with the center of the color patches, used to verify localization accuracy.

Window 2 (Mask Generation Debug): Displays the 4-step processing pipeline (Background Removal, Stalk Cutting, Defect Detection, and Final Mask) across the three calibration methods.

4. Troubleshooting
Failure to Detect Color Checker:

Cause: The current lighting environment does not match the default V-channel threshold.

Solution: Adjust CONF.ChartThreshold (around Line 18). This value determines the initial segmentation of the color checker board.

Inaccurate ROI Segmentation:

Cause: Interference from background colors, or severe shadows/wrinkles within the leaf.

Solution: 1. Adjust Background Parameters: Modify CONF.Bg_RGB_Diff and CONF.Bg_B_Thresh (Lines 27-28).
2. Adjust Defect Parameters: Modify CONF.DefectParams (Line 36) to fine-tune the removal intensity for stems, gaps, and wrinkles.

5. License
This software is open-source under the MIT License.

Copyright (c) 2026 [Your Name/Institution]

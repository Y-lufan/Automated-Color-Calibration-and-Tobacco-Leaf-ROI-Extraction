# Automated Color Calibration and Tobacco Leaf ROI Extraction

![License](https://img.shields.io/badge/License-MIT-yellow.svg) ![MATLAB](https://img.shields.io/badge/MATLAB-R2024a-blue.svg)

## Overview

This repository contains the source code for the **Automated Color Calibration and Tobacco Leaf ROI Extraction Pipeline**.

This project addresses the efficiency bottleneck of traditional manual or semi-automatic color checker extraction in high-throughput practical applications. By leveraging a fully automated spatial localization and precise segmentation pipeline, the method effectively extracts and aligns all 24 standard color patches, integrating three color calibration methods and precise Region of Interest (ROI) extraction. This fully automated workflow significantly enhances batch-processing efficiency, serving as a critical prerequisite for robust tobacco leaf color recognition.

---

## Key Features

* **Automated Patch Extraction**: Eliminates the need for manual cropping or semi-automatic point selection.
* **Multiple Calibration Strategies**: Integrates three different color calibration methods.
* **Precise ROI Extraction**: Effectively removes backgrounds, stalks, shadows, and wrinkles.
* **High Efficiency**: Processes a single image in ~0.26s, suitable for high-throughput batch processing.

---

## Repository Structure

* `main.m` : The core MATLAB script integrating all processing functions.
* `Operating_Manual.md` : Detailed system requirements and usage guide.
* `samples/` : A folder containing representative test images.
* `results/` : Examples of calibration and extraction outputs.

---

## Data Availability Statement

Due to commercial confidentiality and data privacy regulations regarding the industrial source of the samples, the full dataset used in the associated manuscript cannot be made publicly available.

However, to ensure reproducibility and allow users to validate the algorithm, we have provided a **Representative Sample Dataset** in the folder `samples/`. These images cover typical scenarios found in the study and allow for full execution of the provided code.

---

## Getting Started

1. Clone this repository.
2. Open MATLAB.
3. Navigate to the repository folder.
4. Run (Ensure a sample image path is specified) `main.m`.

For detailed instructions, please refer to the [Operating Manual](Operating_Manual.md).

---

## Citation

If you use this code or dataset in your research, please cite our paper:

> [Authors]. (202X). Robust Color Recognition of Post-Cured Tobacco Leaves under Dynamic Lighting via Adaptive Color Calibration and Random Forest. *[Journal Name]*.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

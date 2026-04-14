# Automated Color Calibration and Tobacco Leaf ROI Extraction

![License](https://img.shields.io/badge/License-MIT-yellow.svg) ![MATLAB](https://img.shields.io/badge/MATLAB-R2024a-blue.svg)

## Overview / 概述

**[EN]** This repository contains the source code for the **Automated Color Calibration and Tobacco Leaf ROI Extraction Pipeline**.

This project addresses the efficiency bottleneck of traditional manual or semi-automatic color checker extraction in high-throughput practical applications. By leveraging a fully automated spatial localization and precise segmentation pipeline, the method effectively extracts and aligns all 24 standard color patches, integrating three color calibration methods and precise Region of Interest (ROI) extraction. This fully automated workflow significantly enhances batch-processing efficiency, serving as a critical prerequisite for robust tobacco leaf color recognition.

**[ZH]** 该仓库包含**自动化颜色校准与烟叶感兴趣区域（ROI）提取流程**的源代码。

本项目解决了传统手动或半自动色卡提取方式效率低下、难以满足高通量实际应用需求的瓶颈。通过采用全自动的色卡空间定位与精准分割流水线，该方法有效提取并对齐了 24 个标准色块，同时集成了三种颜色校准方法与精准的感兴趣区域（ROI）提取。这一全自动化处理流程大幅提升了批处理效率，是后续实现烟叶色彩鲁棒识别的关键前提。

---

## Key Features / 主要特征

**[EN]**
* **Automated Patch Extraction**: Eliminates the need for manual cropping or semi-automatic point selection.
* **Multiple Calibration Strategies**: Integrates three different color calibration methods.
* **Precise ROI Extraction**: Effectively removes backgrounds, stalks, shadows, and wrinkles.
* **High Efficiency**: Processes a single image in ~0.26s, suitable for high-throughput batch processing.

**[ZH]**
* **全自动色块提取**：无需人工裁剪或半自动选点。
* **多种颜色校准策略**：集成了三种不同的颜色校准方法。
* **精准的 ROI 提取**：有效剔除背景、叶柄、阴影与褶皱。
* **高效率**：单图处理仅需约 0.26 秒，适合高通量批处理。

---

## Repository Structure / 仓库结构

**[EN]**
* `main.m` : The core MATLAB script integrating all processing functions.
* `Operating_Manual.md` : Detailed system requirements and usage guide.
* `samples/` : A folder containing representative test images.
* `results/` : Examples of calibration and extraction outputs.

**[ZH]**
* `main.m` : 集成了所有处理功能的核心 MATLAB 脚本。
* `Operating_Manual.md` : 详细的系统需求与使用指南。
* `samples/` : 包含代表性测试图像的文件夹。
* `results/` : 校准与提取结果的输出示例。

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

> [Authors]. (202X). 动态光环境下基于自适应颜色校准与随机森林的烤后烟叶色彩鲁棒识别. *[Journal Name]*.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# MSD-FCCM23
MSD: Mixing Signed Digit Representations for Hardware-efficient DNN Acceleration on FPGA with Heterogeneous Resources

*Paper citation: to be updated when published.*

## Introduction
This repository contains the software and hardware open-source for MSD, an FPGA acceleration framework for DNN inference with mixed signed digit representations. 
By fully utilizing the heterogenous recourses on FPGA with different computation methods, this work achieves higher speedup performance compared with the traditional 
DSP-only acceleration. The MSD approach ensures the number representation capability and maintains quantization accuracy of DNN models, with an efficient bit-serial 
computation scheme based on restricted signed digit (RSD).

## Artifacts DOI
The artifacts of this design can be found in HKU Datahub. URL: [https://doi.org/10.25442/hku.22182073](https://doi.org/10.25442/hku.22182073).

## Structure
* `./hardware`: MSD hardware projects based on Xilinx Vivado 2021.2 with the RTL source codes, bitstream, handoff file and host CPU codes.
* `./software`: MSD quantization and hardware scheduler with the Python source codes, running scripts, QAT checkpoints and scheduling results for different DNN models & hardware platforms.

## Environment
The the hardware and software running enviroments are specified in `./hardware/README.md` and `./software/README.md`, respectively.

## Example Run (Artifact Evaluation)
- Software:
    - To run the software evaluation, follow the evaluation steps in `./software/README.md`.
    - Please ensure the software enviroment is ready before running.

- Hardware: 
    - To run the hardware evaluation, follow the evaluation steps in `./hardware/README.md`.
    - Please ensure the hardware enviroment is ready before running.

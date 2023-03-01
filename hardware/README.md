# MSD Hardware
MSD hardware part is based on an general FPGA accelerator that utilizes the heterogeneous resources (LUTs and DSPs) to maximize the theoretical performance. It is based on the Xilinx Vivado Design Suite and the RTL codes are reproducible for different FPGA devices. The System Verilog head file can be configured for different architecture. We also provide the PYNQ-based host CPU codes to drive the accelerator and test results.

## Environment
* **OS**: Ubuntu 18.04
* **Hardware Design Tool**: Xilinx Vivado 2021.2
* **FPGA Platform**: Platforms with PYNQ-based ARM CPU

## Hardware Presets
In MSD experiments, we set up three FPGA platforms for the evaluations: Pynq-Z2, Ultra96-V2 and ZCU102. The host driver of the accelerator is powered by [PYNQ 2.6](https://pynq.readthedocs.io/en/v2.6.1/index.html). You might need to build a image by yourself. You can refer to the instructions in these websites:

- [pynq.io](http://www.pynq.io/board.html)
- [PYNQ SD Card Image](https://pynq.readthedocs.io/en/latest/pynq_sd_card.html)

## Structure
* `./host`: Host codes to drive and test the accelerator.
* `./vivado`: Vivado projects, including Pynq-Z2 project and ultrascale (for the Ultra96 and ZCU102) project, with a makefile to automatically run the hardware synthesis & implementation & generate bitstream. We also provide the bitstream and handoff files that can be directly used.

## Hardware Evaluation Steps
To be updated

## Expected Results
To be updated
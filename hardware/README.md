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

**NOTE: If the hardware enviroment is not available, you can also run the hardware evaluation on our platforms. Please contact the authors for the access to the platform (jjwu@eee.hku.hk). We have prepared the host codes in the FPGA platforms.**

## Structure
* `./host`: Host codes to drive and test the accelerator.
* `./vivado`: Vivado projects, including Pynq-Z2 project and ultrascale (for the Ultra96 and ZCU102) project, with a makefile to automatically run the hardware synthesis & implementation & generate bitstream. We also provide the bitstream and handoff files that can be directly used.

## Hardware Evaluation Steps
- Preparation: you should already run the *Scheduler for hardware evaluation* step in the software evaluation to get the dataflow and schedule *.csv* files, please refer to `../software/README.md`. The dataflow should be copied to the `./host/schd_csv`.

- *(Optional) Vivado project with synthesis & Implementation*. There are three Vivado projects in the `./vivado`. We provide a *.tcl* file and a makefile for each project, by which you can automatically run the synthesis and implementation. The makefile will generate the project, bitstream and handoff files.

- *Directly use*. You can also directly use the bitstream and handoff files in the `./vivado/handoff` folder to test the results in the host.

- *Host setup*. The host code which is responsible of driving the accelerator (including compilation based on the dataflow) is in the `./host` folder. If you have already set up the environment successfully, you can directly run the jupyter notebooks to get the latency results. **Otherwise, we strongly recommend the evaluators using our platforms remotely, and we will prepare everything done for you.**

## Expected Results
To be updated
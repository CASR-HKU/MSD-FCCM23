# MSD Hardware
MSD hardware part is based on an general FPGA accelerator that utilizes the heterogeneous resources (LUTs and DSPs) to maximize the theoretical performance. It is based on the Xilinx Vivado Design Suite and the RTL codes are reproducible for different FPGA devices. The System Verilog head file can be configured for different architecture. We also provide the PYNQ-based host CPU codes to drive the accelerator and test results.

## Environment
* **OS**: Ubuntu 18.04
* **Hardware Design Tool**: Xilinx Vivado 2021.2
* **FPGA Platform**: Platforms with PYNQ-based ARM CPU.

## Hardware Platform Presets
In MSD experiments, we set up three FPGA platforms for the evaluations: Pynq-Z2, Ultra96-V2 and ZCU102. The host driver of the accelerator is powered by [PYNQ 2.6](https://pynq.readthedocs.io/en/v2.6.1/index.html). You might need to build a image by yourself. You can refer to the instructions in these websites:

- [pynq.io](http://www.pynq.io/board.html)
- [PYNQ SD Card Image](https://pynq.readthedocs.io/en/latest/pynq_sd_card.html)

**NOTE: If the hardware enviroment is not available, you can also run the hardware evaluation on our platforms. Please contact the authors for the access to the platform (jjwu@eee.hku.hk). We have prepared the host codes in the FPGA platforms.**

## Structure
* `./host`: Host codes to drive and test the accelerator.
* `./vivado`: Vivado projects, including Pynq-Z2 project, Ultra96 and ZCU102 project, with a makefile to automatically run the hardware synthesis & implementation & generate bitstream. We also provide the bitstream and handoff files that can be directly used.

## Hardware Evaluation Steps
**Before running, make sure you are in the `MSD-FCCM23/hardware` path (``cd hardware/`` in the root path of this project)**

- *(Optional) Schedule and Dataflow Preparation*: you should already run the *Scheduler* step in the software evaluation to get the dataflow and schedule *.csv* files, please refer to `../software/README.md`. **We have provided the final schedule csv files so you can directly use the schedule in our host and you may want to skip this step.**

- *(Optional) Download and setup board files:* If you do not have PYNQ-Z2, Ultra96 and ZCU102 board files, you can download them from the following links:

    - [PYNQ-Z2](https://dpoauwgwqsy2x.cloudfront.net/Download/pynq-z2.zip). Unzip the downloaded file and move it to your board files path.
    - [Ultra96 and ZCU102](https://github.com/Xilinx/XilinxBoardStore/tree/2021.2/). You can directly download the repository and find the board files in the `./boards` folder.

    If you have the board files, or after you download them, you need to export the environment variable for the board files path, as follows:

    ```bash
    export BOARD_PART_REPO=$your_board_files_path$
    # e.g., my board files are all in the `/home/jiajun/.Xilinx/Vivado/2021.2/xhub/board_store/xilinx_board_store` folder, so the command is:
    # export BOARD_PART_REPO=/home/jiajun/.Xilinx/Vivado/2021.2/xhub/board_store/xilinx_board_store
    ```

    Then you can continue to the next step. **Remember you should keep in the same terminal.**

- *Vivado Project & Bitstream Generation*. There are three Vivado projects in the `./vivado`. We provide a *Makefile* for each project, by which you can automatically run the synthesis and implementation.

    *If you want to generate the projects and bitstream individually for different FPGA platforms, you can run the following commands:*

    ``` bash
    # First, you need to source the Vivado environment (2021.2)
    # Make sure you have the license for the Vivado tools and it is also activated when running the following commands
    source $your_vivado_path$/settings64.sh
    # pynqz2 (xc7z020)
    cd ./vivado/pynqz2/prj
    make all
    # For ultra96 (zu3eg) and zcu102 (zu9eg), the steps are similar, just make in the corresponding folder (`./vivado/ultra96/prj` or `./vivado/zcu102/prj`)
    ```

    *Also, you can directly run the shell to generate all, which may take a long time:*

    ``` bash
    # First, you need to source the Vivado environment (2021.2)
    # Make sure you have the license for the Vivado tools and it is also activated when running the following commands
    source make_all.sh
    ```

    You can then open the utilization report file (`./msd_hw_xxx_utilization.txt`) or open the project with GUI and check the utilization (LUTs, DSPs, BRAMs, etc.) for the hardware evaluation. 

- *Board-level Test*. The host codes which are responsible of driving the accelerator are in the `./host` folder. **We strongly recommend the evaluators using our platforms remotely, and we will prepare everything done including bitstream files for you:**

    ```bash
    # In our remote host, you can directly run the following commands in the terminal:
    source start_eval.sh
    ```

    Every platforms has the same commands, and everything related to the results will be printed in the terminal.

    *If you want to run the hardware evaluation on your own platform, you can follow the steps below:*

    - In `./host`, copy everything in the corresponding folder into **ONE** destination in your platform. E.g., if you want to run the evaluation on the Ultra96, you can copy the `./host/ultra96` folder into the `$your_host_path$` folder in your Ultra96 platform. **Make sure you have the same folder structure as the remote host.**

    - Copy the bitstream and handoff files (`./msd_hw_xxx.bit` and `./msd_hw_xxx.hwh`) into your folder, which have been generated in each `/prj` path (e.g., `./vivado/pynqz2/prj` for Pynq-Z2). Modify the `run_eval.py` file, and change the bitstream path:

        ``` python
        # original & default in the file
        overlay = pynq.Overlay('/home/xilinx/jupyter_notebooks/MSD_FCCM_2023/msd_hw_pynq.bit')
        # change to your path
        overlay = pynq.Overlay('$your_host_path$')
        ```

    - Copy the schedule csv files into your folder according to your board, which have been generated in the `../software/msd_scheduler/results`. E.g., if you want to run the evaluation on the Ultra96, you can copy the `./results/ultra96_xxxx` csv files into the `$your_host_path$` folder in your Ultra96 platform.

      **NOTE: the mobilenetv2 on xc7z020 contains two csv files, you need to copy both of them.**

    - Run the following commands in the terminal:

        ```bash
        cd $your_host_path$
        source start_eval.sh
        ```

- Time Consumption of each step (approximation):

    Configuration:
    + AMD EPYC 7413 24-Core Processor @ 2.65GHz
    + CPU jobs for scheduler and Vivado 2021.2: 8 jobs

    | Step | Time |
    |:---:|:---:|
    | Schedule and Dataflow Preparation | 5 hours |
    | Vivado Project & Bitstream Generation | 4 hours |
    | Board-level Test | Very fast |

## Expected Results
**NOTE: our latest results are slightly different from the submission draft since we have optimized the codes. The camera ready results will be cosistent with the artifact evaluation results, as listed here:**

<table>
<thead>
  <tr>
    <th>Devices</th>
    <th>Frequency (MHz)</th>
    <th>kLUT</th>
    <th>DSP</th>
    <th>BRAM</th>
    <th>DNN Model</th>
    <th>Latency (ms)</th>
    <th>Throughput (GOPS)</th>
    <th>GOPS/kLUT</th>
    <th>GOPS/DSP</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="3">XC7Z020</td>
    <td rowspan="3">100</td>
    <td rowspan="3">38.09</td>
    <td rowspan="3">214</td>
    <td rowspan="3">139</td>
    <td>VGG-16</td>
    <td>287.18</td>
    <td>107.9</td>
    <td>2.83</td>
    <td>0.50</td>
  </tr>
  <tr>
    <td>ResNet-18</td>
    <td>26.31</td>
    <td>138.3</td>
    <td>3.63</td>
    <td>0.65</td>
  </tr>
  <tr>
    <td>MobileNet-V2</td>
    <td>16.40</td>
    <td>38.9</td>
    <td>1.02</td>
    <td>0.18</td>
  </tr>
  <tr>
    <td rowspan="4">ZU3EG</td>
    <td rowspan="4">214</td>
    <td rowspan="4">55.71</td>
    <td rowspan="4">264</td>
    <td rowspan="4">194</td>
    <td>VGG-16</td>
    <td>74.22</td>
    <td>417.6</td>
    <td>7.93</td>
    <td>1.58</td>
  </tr>
  <tr>
    <td>ResNet-18</td>
    <td>7.72</td>
    <td>471.7</td>
    <td>8.96</td>
    <td>1.79</td>
  </tr>
  <tr>
    <td>ResNet-50</td>
    <td>29.06</td>
    <td>283.6</td>
    <td>5.39</td>
    <td>1.07</td>
  </tr>
  <tr>
    <td>MobileNet-V2</td>
    <td>7.41</td>
    <td>86.1</td>
    <td>1.64</td>
    <td>0.33</td>
  </tr>
  <tr>
    <td rowspan="4">ZU9EG</td>
    <td rowspan="4">214</td>
    <td rowspan="4">151.69</td>
    <td rowspan="4">2312</td>
    <td rowspan="4">771</td>
    <td>VGG-16</td>
    <td>52.70</td>
    <td>588.2</td>
    <td>3.88</td>
    <td>0.25</td>
  </tr>
  <tr>
    <td>ResNet-18</td>
    <td>5.69</td>
    <td>639.8</td>
    <td>4.22</td>
    <td>0.28</td>
  </tr>
  <tr>
    <td>ResNet-50</td>
    <td>15.94</td>
    <td>516.9</td>
    <td>3.41</td>
    <td>0.22</td>
  </tr>
  <tr>
    <td>ViT-base</td>
    <td>22.30</td>
    <td>1481.44</td>
    <td>9.77</td>
    <td>0.64</td>
  </tr>
</tbody>
</table>
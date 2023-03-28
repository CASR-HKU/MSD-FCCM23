# MSD Software
MSD software part is responsible for quantization-aware training (QAT) and the scheduler for MSD hardware. The QAT is based on a heuristic algorithm for accuracy-speedup trade-off, as the **Algorithm 1** in the paper presents. The scheduler is implemented based on the widely used 6-dimension for-loop topology as the DNN model abstraction. Based on the for-loop model, we tile the output channel ($K$), output feature map height ($H$), width ($W$), and input channel ($C$), dimensions while keeping the tile size in the kernel height ($I$) \& width ($J$) same with the DNN model. The output of the scheduler will be used in the hardware evaluation in the `../hardware`.

## Structure
* `./msd_quant`: QAT and the accuracy-speedup trade-off of MSD framework, including the quantization functions and Pytorch training framework.
* `./msd_scheduler`: The scheduler that receives DNN models and hardware constraints as inputs, and generates the optimal schedule & dataflow including the workload partitioning between LUTs and DSPs.

## Environment

- **If you want to run the retraining**

    ```
    # PyTorch 1.12
    conda create -n msd_env python=3.8 
    conda activate msd_env
    conda install  pytorch=1.12.0 torchvision torchaudio cudatoolkit=11.3 -c pytorch
    # Quantization CUDA kernel
    pip install ./quant

    #ImageNet
    pip install --extra-index-url https://developer.download.nvidia.com/compute/redist nvidia-dali-cuda110
    ```

- **If not, no need for pytorch**

    ```
    conda create -n msd_env
    conda activate msd_env
    ```

    Any version of **Python3** should be fine.

## Software Evaluation Steps
- *Quantization Accuracy* based on quantization-aware training (QAT), with all the EB = 2. (The results in Table IV in the paper)

    To run the QAT, follow the steps in command line:
    ```
    ./scripts/msd_quant_standard_eb.sh    #Each line stands for one experiment 
    
    i.e. ResNet18 with EB2 quantization:
    
    CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./checkpoint_log/ResNet18_EB2_MSD.log 2>&1

    ```

- *Accuracy-speedup trade-off* based on quantization-aware training (QAT), with mixed EBs. (The results in Fig. 10 in the paper). This part includes 2 steps. Firstly, scheduler will search the differnet latency results based on various EBs for each layer (results will be in `./msd_scheduler/aux` and `./msd_analysis/adaptive_search_xxx` are be copied to `./msd_quant_latency_search`). Secondly, QAT framework will be run based on the searched EBs.

    To run the mixed-EB search and corresponding QAT based on searched results, follow the steps in command line:
    ```
    Step 1: Mixed-EB search methodology
    ../msd_analysis/adaptive_search_(resnet18/resnet50/vgg16).py  # A set of mixed-EB strategies that meet the speedup ratio will be searched out. 
    
    Step 2: QAT under the different latency constrained
    ../scripts/msd_quant_latency_search.sh  # The required information will be manually imported from step 1 into it for QAT.

    ```

- *Direct check*. **ONLY for the artifact evaluation of the paper.** If you want to evaluate the results for the accuracy only and do not want to retrain the models, we provide all the training logs in `./msd_quant/msd_quantization/checkpoints`. 

    Also, if you want to check the training process by yourself and load our QAT process, you can directly run the following command to load the checkpoints and start training:
    ```

    ```

- *Scheduler for hardware evaluation*, with various DNN models and hardware platforms. The scheduled results are not final ones in Table IV, but for the hardware evaluation in `../hardware`.

    To run the scheduler, follow the steps in command line:
    ```

    ```

    After running, the results will be saved in `./msd_scheduler/results`. The latency results searched by the scheduler are in the format of `format.txt`, which contains the optimal schedule and dataflow for the model. Also, the layer-wise optimal schedule and dataflow with csv files will be copied to `../hardware/host/` for the hardware evaluation.

    **NOTE: the results generated in this step are based on cycle-accurate simulator in our scheduler, not the real hardware. The hardware evaluation will generate the final results in Table IV.**

## Expected Results
- The expected accuracy results based on EB=2 mode are listed here (corresponding to Table IV in the paper):

    | Models | VGG-16 | ResNet-18 | ResNet-50 | MobileNet-V2 | Vision Transformer |
    |:---:|:---:|:---:|:---:|:---:|:---:|
    | Top-1 Accuracy | **73.37%** | **69.72%** | **76.05%** |  **71.16%** |  |
    | Epochs | **3** | **5** | **5** | **5** | **5** |

- Accuracy-speedup trade-off results (corresponding to Fig. 10 in the paper):

    <table>
    <thead>
    <tr>
        <th>Models</th>
        <th>w</th>
        <th>Layer-wise EB<br>Combination</th>
        <th>Top-1 Accuracy</th>
        <th>Epochs</th>
        <th>Final Speedup<br>(Simulator)</th>
    </tr>
    </thead>
    <tbody>
    <tr>
        <td rowspan="6">VGG-16</td>
        <td>1.7</td>
        <td>[2,3,2,2,2,3,2,2,3,2,3,2,2,2,2,2]</td>
        <td>73.358%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>1.75</td>
        <td>[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]</td>
        <td>73.334%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2</td>
        <td>[2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2]</td>
        <td>73.35%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.1</td>
        <td>[1,1,2,1,1,2,1,2,2,2,2,1,2,1,2,1]</td>
        <td>72.59%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.2</td>
        <td>[1,1,2,1,1,1,1,2,2,1,2,1,2,1,2,1]</td>
        <td>72.462%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.5</td>
        <td>[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]</td>
        <td>72.186%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td rowspan="6">ResNet-50</td>
        <td>2.35</td>
        <td></td>
        <td>76.114%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.5</td>
        <td></td>
        <td>76.088%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.6</td>
        <td></td>
        <td>76.074%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>2.75</td>
        <td></td>
        <td>76.026%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>3.1</td>
        <td></td>
        <td>74.346%</td>
        <td>3</td>
        <td></td>
    </tr>
    <tr>
        <td>3.5</td>
        <td></td>
        <td>73.568%</td>
        <td>3</td>
        <td></td>
    </tr>
    </tbody>

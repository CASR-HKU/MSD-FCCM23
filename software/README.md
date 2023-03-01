# MSD Software
MSD software part is responsible for quantization-aware training (QAT) and the scheduler for MSD hardware. The QAT is based on a heuristic algorithm for accuracy-speedup trade-off, as the **Algorithm 1** in the paper presents. The scheduler is implemented based on the widely used 6-dimension for-loop topology as the DNN model abstraction. Based on the for-loop model, we tile the output channel ($K$), output feature map height ($H$), width ($W$), and input channel ($C$), dimensions while keeping the tile size in the kernel height ($I$) \& width ($J$) same with the DNN model. The output of the scheduler will be used in the hardware evaluation in the `../hardware`.

## Structure
* `./msd_quant`: QAT and the accuracy-speedup trade-off of MSD framework, including the quantization functions and Pytorch training framework.
* `./msd_scheduler`: The scheduler that receives DNN models and hardware constraints as inputs, and generates the optimal schedule & dataflow including the workload partitioning between LUTs and DSPs.

## Software Evaluation Steps
To be updated.

## Expected Results
To be updated.